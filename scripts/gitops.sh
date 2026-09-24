#!/usr/bin/env bash
set -euo pipefail

ACTION="help"
CLOUD="gcp"
ENVIRONMENT=""
USE_TERRAGRUNT=false
VAR_FILE=""
RELEASE_NAME="portfolio"
NAMESPACE="production"
INGRESS_HOST="www.nikhil-srh07.com"
IMAGE_REPOSITORY="nodejs-multi-cloud-app"
IMAGE_TAG="latest"
AUTO_APPROVE=false

usage() {
  cat <<'EOF'
Usage: ./scripts/gitops.sh --action <up|validate|plan|apply|destroy|deploy|undeploy> --cloud <aws|gcp|azure>

Options:
  --environment <dev|staging|prod>  Defaults to dev when omitted.
  --use-terragrunt                 Use the shared Terragrunt remote state.
  --var-file <path>                Optional Terraform variable file.
  --auto-approve                   Skip the up confirmation; required for destroy.
  --help                           Show this help.

Examples:
  ./scripts/gitops.sh --action up --cloud gcp
  ./scripts/gitops.sh --action plan --cloud aws --environment dev
  ./scripts/gitops.sh --action apply --cloud azure --use-terragrunt
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action) ACTION="${2:?Missing value for --action}"; shift 2 ;;
    --cloud) CLOUD="${2:?Missing value for --cloud}"; shift 2 ;;
    --environment) ENVIRONMENT="${2:?Missing value for --environment}"; shift 2 ;;
    --use-terragrunt) USE_TERRAGRUNT=true; shift ;;
    --var-file) VAR_FILE="${2:?Missing value for --var-file}"; shift 2 ;;
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
  read -r -p "Environment [dev]: " ENVIRONMENT
  ENVIRONMENT="${ENVIRONMENT:-dev}"
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
CHART_DIR="$REPO_ROOT/helm/my-app"

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
    terraform_args=("-var" "project_id=$gcp_project")
  fi
fi
if [[ "$CLOUD" == "gcp" && "${terraform_args[*]}" != *"project_id="* ]]; then
  gcp_project="${GOOGLE_CLOUD_PROJECT:-}"
  if [[ -n "$gcp_project" ]]; then
    terraform_args=("-var" "project_id=$gcp_project")
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

deploy_helm() {
  local helm_bin
  helm_bin="$(find_command helm || true)"
  [[ -n "$helm_bin" ]] || { echo "Helm is required for deploy." >&2; exit 1; }
  "$helm_bin" upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set "image.repository=$IMAGE_REPOSITORY" \
    --set "image.tag=$IMAGE_TAG" \
    --set "ingress.host=$INGRESS_HOST"
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
  deploy) deploy_helm ;;
  undeploy)
    helm_bin="$(find_command helm || true)"
    [[ -n "$helm_bin" ]] || { echo "Helm is required for undeploy." >&2; exit 1; }
    "$helm_bin" uninstall "$RELEASE_NAME" --namespace "$NAMESPACE"
    ;;
  up)
    if ! $AUTO_APPROVE; then
      read -r -p "Provision $CLOUD/$ENVIRONMENT and deploy Helm to Kubernetes? [y/N] " confirmation
      [[ "$confirmation" =~ ^([yY][eE][sS]|[yY])$ ]] || { echo "Operation cancelled."; exit 1; }
    fi
    apply_infrastructure
    deploy_helm
    ;;
  *) echo "Unknown action: $ACTION" >&2; usage; exit 1 ;;
esac

echo "Completed action: $ACTION"
