#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"

if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi

BUCKET="$(${TF} -chdir="${TF_DIR}" output -raw backup_bucket_name 2>/dev/null || echo "")"

helm upgrade --install minecraft "${ROOT}/helm/minecraft" \
  -n minecraft --create-namespace \
  -f "${ROOT}/helm/minecraft/values-prod.yaml" \
  ${BUCKET:+--set "backup.bucketName=${BUCKET}"} \
  --wait --timeout 600s

kubectl rollout status deployment/minecraft -n minecraft --timeout=600s

EXTERNAL_IP=""
for _ in $(seq 1 60); do
  EXTERNAL_IP="$(kubectl get svc minecraft -n minecraft -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  [[ -n "${EXTERNAL_IP}" ]] && break
  sleep 10
done

if [[ -n "${EXTERNAL_IP}" ]]; then
  echo "Connect: ${EXTERNAL_IP}:25565"
else
  kubectl get svc -n minecraft -w
fi
