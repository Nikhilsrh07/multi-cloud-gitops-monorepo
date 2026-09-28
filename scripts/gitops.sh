#!/usr/bin/env bash
set -euo pipefail

ACTION="${GITOPS_ACTION:-help}"
CLOUD="${GITOPS_CLOUD:-gcp}"
ENVIRONMENT="${GITOPS_ENVIRONMENT:-}"
USE_TERRAGRUNT=false
[[ "${GITOPS_USE_TERRAGRUNT:-false}" == "true" ]] && USE_TERRAGRUNT=true
VAR_FILE="${GITOPS_VAR_FILE:-}"
RELEASE_NAME="${GITOPS_RELEASE_NAME:-portfolio}"
NAMESPACE="${GITOPS_NAMESPACE:-production}"
INGRESS_HOST="${GITOPS_INGRESS_HOST:-www.nikhilsrh07.com}"
IMAGE_REPOSITORY="${GITOPS_IMAGE_REPOSITORY:-ghcr.io/nikhilsrh07/portfolio-website}"
IMAGE_TAG="${GITOPS_IMAGE_TAG:-latest}"
AUTO_APPROVE=false
[[ "${GITOPS_AUTO_APPROVE:-false}" == "true" ]] && AUTO_APPROVE=true

usage() {
  cat <<'EOF'
Usage: ./scripts/gitops.sh --action <up|validate|plan|apply|destroy> --cloud <aws|gcp|azure>

Provisions the $0 free-tier VM, installs k3s, deploys the portfolio, and
points Cloudflare DNS at it — all from Terraform's dynamic outputs.
A new --image-tag recreates the VM with the fresh image baked in.

Options:
  --environment <dev|staging|prod>  Defaults to dev when omitted (or GITOPS_ENVIRONMENT).
  --cloud <aws|gcp|azure>           Defaults to gcp (or GITOPS_CLOUD).
  --use-terragrunt                 Use the shared Terragrunt remote state.
  --var-file <path>                Optional Terraform variable file.
  --image-repository <repo>        Container image repository (or GITOPS_IMAGE_REPOSITORY).
  --image-tag <tag>                Container image tag (or GITOPS_IMAGE_TAG).
  --ingress-host <host>            Kept for compatibility (DNS is via Cloudflare module).
  --namespace <ns>                 Kept for compatibility.
  --release-name <name>            Kept for compatibility.
  --auto-approve                   Skip confirmations (required for non-interactive use).
  --help                           Show this help.

Environment variables (all optional, CLI flags win):
  GITOPS_ACTION, GITOPS_CLOUD, GITOPS_ENVIRONMENT, GITOPS_USE_TERRAGRUNT,
  GITOPS_VAR_FILE, GITOPS_RELEASE_NAME, GITOPS_NAMESPACE, GITOPS_INGRESS_HOST,
  GITOPS_IMAGE_REPOSITORY, GITOPS_IMAGE_TAG, GITOPS_AUTO_APPROVE

Examples:
  ./scripts/gitops.sh --action up --cloud aws --environment dev --auto-approve
  ./scripts/gitops.sh --action plan --cloud gcp
  GITOPS_CLOUD=azure ./scripts/gitops.sh --action apply --auto-approve
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action) ACTION="${2:?Missing value for --action}"; shift 2 ;;
    --cloud) CLOUD="${2:?Missing value for --cloud}"; shift 2 ;;
    --environment) ENVIRONMENT="${2:?Missing value for --environment}"; shift 2 ;;
    --use-terragrunt) USE_TERRAGRUNT=true; shift ;;
    --var-file) VAR_FILE="${2:?Missing value for --var-file}"; shift 2 ;;
    --image-repository) IMAGE_REPOSITORY="${2:?Missing value for --image-repository}"; shift 2 ;;
    --image-tag) IMAGE_TAG="${2:?Missing value for --image-tag}"; shift 2 ;;
    --ingress-host) INGRESS_HOST="${2:?Missing value for --ingress-host}"; shift 2 ;;
    --namespace) NAMESPACE="${2:?Missing value for --namespace}"; shift 2 ;;
    --release-name) RELEASE_NAME="${2:?Missing value for --release-name}"; shift 2 ;;
    --auto-approve) AUTO_APPROVE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$ACTION" == "help" ]]; then
  usage
  exit 0
fi

case "$CLOUD" in
  aws|gcp|azure) ;;
  *) echo "Cloud must be aws, gcp, or azure." >&2; exit 1 ;;
esac

if [[ -z "$ENVIRONMENT" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "Environment [dev]: " ENVIRONMENT
    ENVIRONMENT="${ENVIRONMENT:-dev}"
  else
    ENVIRONMENT="dev"
    echo "Non-interactive shell detected; defaulting environment to 'dev'."
  fi
fi

case "$ENVIRONMENT" in
  dev|staging|prod) ;;
  *) echo "Environment must be dev, staging, or prod." >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# =====================================================================
# 📝 GLOBAL LOGGING REDIRECTION ENGINE
# =====================================================================
# Creates a local logs folder and streams everything to terminal AND logfile
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/gitops_${CLOUD}_${ENVIRONMENT}_${ACTION}_${TIMESTAMP}.log"

# Duplicate standard output and error output to your log file automatically
exec > >(tee -ia "$LOG_FILE") 2>&1
echo "====================================================================="
echo "📝 Writing automated log details to: $LOG_FILE"
echo "====================================================================="

ENVIRONMENT_ROOT="$REPO_ROOT/terraform/environments/$ENVIRONMENT"
CLOUD_TERRAFORM_DIR="$ENVIRONMENT_ROOT/$CLOUD"
TERRAFORM_DIR="$CLOUD_TERRAFORM_DIR"
if [[ ! -d "$TERRAFORM_DIR" ]]; then
  TERRAFORM_DIR="$ENVIRONMENT_ROOT"
fi

[[ -d "$TERRAFORM_DIR" ]] || { echo "Terraform environment not found: $TERRAFORM_DIR" >&2; exit 1; }

find_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi

  local windows_user="${USERNAME:-$(id -un)}"
  if [[ "$name" == "terraform" ]]; then
    for candidate in \
      "/c/Users/$windows_user/bin/terraform.exe" \
      "/mnt/c/Users/$windows_user/bin/terraform.exe"; do
      if [[ -f "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  fi

  return 1
}

TERRAFORM_BIN="$(find_command terraform || true)"
if [[ -z "$TERRAFORM_BIN" ]]; then
  echo "Terraform was not found. Install it or add it to PATH before running this script." >&2
  exit 1
fi

terraform_args=()
if [[ "$TERRAFORM_DIR" == "$ENVIRONMENT_ROOT" ]]; then
  terraform_args+=("-var" "cloud=$CLOUD")
fi
if [[ "$CLOUD" == "gcp" && -z "$VAR_FILE" ]] && command -v gcloud >/dev/null 2>&1; then
  gcp_project="$(gcloud config get-value project 2>/dev/null || true)"
  if [[ -n "$gcp_project" && "$gcp_project" != "(unset)" ]]; then
    terraform_args+=("-var" "gcp_project_id=$gcp_project")
  fi
fi
if [[ "$CLOUD" == "gcp" && "${terraform_args[*]}" != *"gcp_project_id="* ]]; then
  gcp_project="${GOOGLE_CLOUD_PROJECT:-}"
  if [[ -n "$gcp_project" ]]; then
    terraform_args+=("-var" "gcp_project_id=$gcp_project")
  else
    echo "GCP project is not configured. Run: gcloud config set project <project-id>" >&2
    exit 1
  fi
fi
if [[ -n "$VAR_FILE" ]]; then
  [[ -f "$VAR_FILE" ]] || { echo "Variable file not found: $VAR_FILE" >&2; exit 1; }
  terraform_args+=("-var-file" "$VAR_FILE")
fi

run_terraform() {
  if [[ "$TERRAFORM_BIN" == *.exe ]]; then
    local windows_dir
    if command -v wslpath >/dev/null 2>&1; then
      windows_dir="$(wslpath -w "$TERRAFORM_DIR")"
    elif command -v cygpath >/dev/null 2>&1; then
      windows_dir="$(cygpath -w "$TERRAFORM_DIR")"
    else
      echo "Cannot convert Terraform path for the Windows executable." >&2
      exit 1
    fi
    "$TERRAFORM_BIN" "-chdir=$windows_dir" "$@"
  else
    "$TERRAFORM_BIN" "-chdir=$TERRAFORM_DIR" "$@"
  fi
}

run_terragrunt() {
  command -v terragrunt >/dev/null 2>&1 || { echo "terragrunt is required with --use-terragrunt." >&2; exit 1; }
  TG_CLOUD="$CLOUD" terragrunt --working-dir "$TERRAFORM_DIR" "$@"
}

# Image coordinates flow into Terraform as variables so the k3s manifest
# rendered on the $0 VM always uses the freshly built image (dynamic data).
export TF_VAR_image_repository="$IMAGE_REPOSITORY"
export TF_VAR_image_tag="$IMAGE_TAG"

apply_infrastructure() {
  local args=(apply "${terraform_args[@]}")
  $AUTO_APPROVE && args+=(--auto-approve)
  if $USE_TERRAGRUNT; then
    run_terragrunt "${args[@]}"
  else
    run_terraform init -backend=false
    run_terraform "${args[@]}"
  fi
}

case "$ACTION" in
  validate)
    run_terraform init -backend=false
    run_terraform validate
    ;;
  plan)
    if $USE_TERRAGRUNT; then
      run_terragrunt plan "${terraform_args[@]}"
    else
      run_terraform init -backend=false
      run_terraform plan "${terraform_args[@]}"
    fi
    ;;
  apply) apply_infrastructure ;;
  destroy)
    $AUTO_APPROVE || { echo "Destroy requires --auto-approve." >&2; exit 1; }
    destroy_args=(destroy "${terraform_args[@]}" --auto-approve)
    if $USE_TERRAGRUNT; then
      run_terragrunt "${destroy_args[@]}"
    else
      run_terraform init -backend=false
      run_terraform "${destroy_args[@]}"
    fi
    ;;
  up)
    if ! $AUTO_APPROVE; then
      if [[ -t 0 ]]; then
        read -r -p "Provision $0 $CLOUD/$ENVIRONMENT VM, deploy portfolio, update DNS? [y/N] " confirmation
        [[ "$confirmation" =~ ^([yY][eE][sS]|[yY])$ ]] || { echo "Operation cancelled."; exit 1; }
      else
        echo "Refusing to run 'up' without --auto-approve in non-interactive mode." >&2
        exit 1
      fi
    fi
    apply_infrastructure
    echo "Site: https://www.${INGRESS_HOST#www.}"
    ;;
  *) echo "Unknown action: $ACTION" >&2; usage; exit 1 ;;
esac

echo "Completed action: $ACTION"
