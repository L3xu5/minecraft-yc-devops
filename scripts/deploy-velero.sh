#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"

if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi
command -v helm >/dev/null || { echo "Install helm"; exit 1; }
command -v kubectl >/dev/null || { echo "Install kubectl"; exit 1; }

ACCESS_KEY="$(${TF} -chdir="${TF_DIR}" output -raw velero_access_key 2>/dev/null || true)"
SECRET_KEY="$(${TF} -chdir="${TF_DIR}" output -raw velero_secret_key 2>/dev/null || true)"

if [[ -z "${ACCESS_KEY}" || -z "${SECRET_KEY}" ]]; then
  echo "Run tofu apply with enable_velero = true first"
  exit 1
fi

kubectl create namespace velero --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic velero-credentials \
  -n velero \
  --from-literal=cloud="[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts 2>/dev/null || true
helm repo update vmware-tanzu
helm upgrade --install velero vmware-tanzu/velero \
  -n velero \
  -f "${ROOT}/helm/platform/velero-values.yaml" \
  --wait --timeout 10m

echo "==> Velero ready. Test: velero backup create test-backup --include-namespaces minecraft"
