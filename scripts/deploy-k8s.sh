#!/usr/bin/env bash
set -euo pipefail

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
GCP_ZONE="${GCP_ZONE:-us-central1-a}"
IMAGE_REPOSITORY="${GITOPS_IMAGE_REPOSITORY:-ghcr.io/nikhilsrh07/portfolio-website}"
IMAGE_TAG="${GITOPS_IMAGE_TAG:?Set GITOPS_IMAGE_TAG to an immutable image tag}"
INSTANCE_NAME="${GITOPS_INSTANCE_NAME:-portfolio-dev-portfolio}"
IMAGE_URI="${IMAGE_REPOSITORY}:${IMAGE_TAG}"

[[ "$GCP_PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]] || {
  echo "GCP_PROJECT_ID has an invalid format." >&2
  exit 1
}
[[ "$GCP_ZONE" =~ ^[a-z0-9-]+$ ]] || {
  echo "GCP_ZONE has an invalid format." >&2
  exit 1
}
[[ "$INSTANCE_NAME" =~ ^[a-z][a-z0-9-]{0,62}$ ]] || {
  echo "GITOPS_INSTANCE_NAME has an invalid format." >&2
  exit 1
}
[[ "$IMAGE_REPOSITORY" =~ ^[a-z0-9./:_-]+$ ]] || {
  echo "GITOPS_IMAGE_REPOSITORY has an invalid format." >&2
  exit 1
}
[[ "$IMAGE_TAG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] || {
  echo "GITOPS_IMAGE_TAG has an invalid format." >&2
  exit 1
}
command -v gcloud >/dev/null 2>&1 || {
  echo "gcloud is required to deploy the Kubernetes workload." >&2
  exit 1
}

gcloud compute ssh "$INSTANCE_NAME" \
  --project="$GCP_PROJECT_ID" \
  --zone="$GCP_ZONE" \
  --quiet \
  --command="sudo kubectl -n default set image deployment/portfolio portfolio=${IMAGE_URI} && sudo kubectl -n default rollout status deployment/portfolio --timeout=240s"