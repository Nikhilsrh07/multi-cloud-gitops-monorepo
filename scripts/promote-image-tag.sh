#!/usr/bin/env bash
set -euo pipefail

image_tag="${1:?Usage: promote-image-tag.sh <40-character-commit-sha>}"
values_file="helm/my-app/values.yaml"

if [[ ! "$image_tag" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Image tag must be a 40-character lowercase commit SHA." >&2
  exit 1
fi

if [[ "$(grep -c '^  tag:' "$values_file")" -ne 1 ]]; then
  echo "Expected exactly one image tag in $values_file." >&2
  exit 1
fi

sed -i -E "s/^  tag:.*/  tag: \"${image_tag}\"/" "$values_file"
