#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"
PLATFORM_DIR="${ROOT}/k8s/platform"

if command -v tofu >/dev/null; then TF=tofu; elif command -v terraform >/dev/null; then TF=terraform; else echo "Install tofu/terraform"; exit 1; fi
command -v helm >/dev/null || { echo "Install helm: brew install helm"; exit 1; }
command -v kubectl >/dev/null || { echo "Install kubectl"; exit 1; }
command -v yc >/dev/null || { echo "Install yc CLI"; exit 1; }

export YC_TOKEN="$(yc iam create-token)"
FOLDER_ID="$(yc config get folder-id)"

echo "==> Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update external-secrets
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n platform --create-namespace \
  --set installCRDs=true \
  --set webhook.failurePolicy=Ignore \
  --wait --timeout 5m

echo "==> Creating ESO auth secret (JSON authorized key)..."
ESO_SA_ID="$(${TF} -chdir="${TF_DIR}" output -raw eso_service_account_id 2>/dev/null || true)"
if [[ -z "${ESO_SA_ID}" ]]; then
  echo "Run tofu apply in terraform/envs/dev first (enable_lockbox = true)"
  exit 1
fi

KEY_FILE="$(mktemp)"
yc iam key create --service-account-id "${ESO_SA_ID}" --output "${KEY_FILE}" >/dev/null

kubectl create namespace minecraft --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic yc-auth \
  --from-file=authorized-key="${KEY_FILE}" \
  -n minecraft \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f "${KEY_FILE}"

echo "==> Applying SecretStore..."
kubectl apply -f "${PLATFORM_DIR}/secret-store.yaml"

LOCKBOX_ID="$(${TF} -chdir="${TF_DIR}" output -raw lockbox_secret_name 2>/dev/null || true)"
# Resolve secret ID by name
LOCKBOX_SECRET_ID="$(yc lockbox secret get "${LOCKBOX_ID}" --format json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"

echo "==> Applying ExternalSecret for minecraft namespace..."
kubectl create namespace minecraft --dry-run=client -o yaml | kubectl apply -f -
sed "s/\${LOCKBOX_SECRET_ID}/${LOCKBOX_SECRET_ID}/g" \
  "${PLATFORM_DIR}/external-secret-minecraft.yaml" | kubectl apply -f -

echo "==> Ensuring Object Storage bucket exists..."
BUCKET="$(${TF} -chdir="${TF_DIR}" output -raw backup_bucket_name 2>/dev/null || true)"
if [[ -n "${BUCKET}" ]]; then
  yc storage bucket create --name "${BUCKET}" 2>/dev/null || echo "Bucket ${BUCKET} already exists"
  kubectl create configmap minecraft-backup-config \
    --from-literal=bucket-name="${BUCKET}" \
    -n minecraft \
    --dry-run=client -o yaml | kubectl apply -f -
fi

echo "==> Waiting for ExternalSecret sync..."
for _ in $(seq 1 30); do
  if kubectl get secret minecraft-secrets -n minecraft >/dev/null 2>&1; then
    echo "Secret minecraft-secrets synced from Lockbox."
    break
  fi
  sleep 5
done

kubectl get externalsecret -n minecraft
kubectl get secret minecraft-secrets -n minecraft 2>/dev/null || echo "ExternalSecret still syncing — check: kubectl describe externalsecret minecraft-secrets -n minecraft"

echo ""
echo "==> Next: ./scripts/deploy-minecraft.sh or Argo CD sync"
echo "==> Storage lifecycle..."
"${ROOT}/scripts/setup-lifecycle.sh" "${BUCKET:-}"
