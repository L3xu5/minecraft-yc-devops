#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUCKET="${1:-}"

if [[ -z "${BUCKET}" ]]; then
  if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi
  BUCKET="$(${TF} -chdir="${ROOT}/terraform/envs/dev" output -raw backup_bucket_name 2>/dev/null || true)"
fi

if [[ -z "${BUCKET}" ]]; then
  echo "Usage: $0 [bucket-name]"
  exit 1
fi

echo "==> Applying lifecycle to bucket ${BUCKET}..."
echo "    0-7 days:  STANDARD"
echo "    7-30 days: COLD"
echo "    30+ days:  DELETE"

yc storage bucket update \
  --name "${BUCKET}" \
  --lifecycle-rules-from-file "${ROOT}/config/storage-lifecycle.json"

echo "==> Done. Rules apply daily at 00:00 UTC."
