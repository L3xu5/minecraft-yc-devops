#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"
PLATFORM="${ROOT}/helm/platform"

if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi
command -v helm >/dev/null || { echo "Install helm"; exit 1; }
command -v kubectl >/dev/null || { echo "Install kubectl"; exit 1; }
command -v yc >/dev/null || { echo "Install yc"; exit 1; }

export YC_TOKEN="$(yc iam create-token)"

echo "==> [1/6] Terraform apply..."
${TF} -chdir="${TF_DIR}" init -upgrade >/dev/null
${TF} -chdir="${TF_DIR}" apply -auto-approve

LOG_GROUP_ID="$(${TF} -chdir="${TF_DIR}" output -raw log_group_id)"
LOGGING_SA_ID="$(${TF} -chdir="${TF_DIR}" output -raw logging_sa_id)"
REGISTRY_ID="$(${TF} -chdir="${TF_DIR}" output -raw container_registry_id)"
BUCKET="$(${TF} -chdir="${TF_DIR}" output -raw backup_bucket_name)"
IMAGE="cr.yandex/${REGISTRY_ID}/minecraft-server:latest"

echo "==> [2/6] Docker image → YCR..."
USE_REPO="itzg/minecraft-server"
USE_TAG="latest"
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  if docker build -t "${IMAGE}" "${ROOT}/docker" && yc container registry configure-docker && docker push "${IMAGE}"; then
    USE_REPO="cr.yandex/${REGISTRY_ID}/minecraft-server"
    USE_TAG="latest"
  fi
else
  echo "WARN: Docker unavailable — using itzg/minecraft-server"
fi

echo "==> [3/6] Lockbox / ESO..."
[[ -x "${ROOT}/scripts/deploy-platform.sh" ]] && "${ROOT}/scripts/deploy-platform.sh" || true

echo "==> [4/6] Fluent Bit → Cloud Logging..."
KEY_FILE="$(mktemp)"
yc iam key create --service-account-id "${LOGGING_SA_ID}" --output "${KEY_FILE}" >/dev/null

kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic secret-key-json \
  --from-file=key.json="${KEY_FILE}" \
  -n logging --dry-run=client -o yaml | kubectl apply -f -
rm -f "${KEY_FILE}"

sed "s/__LOG_GROUP_ID__/${LOG_GROUP_ID}/g" \
  "${ROOT}/k8s/platform/fluent-bit.yaml" | kubectl apply -f -

echo "==> [5/6] Prometheus + Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update prometheus-community
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f "${PLATFORM}/prometheus-values.yaml" \
  --wait --timeout 10m

echo "==> [6/6] Helm: Minecraft..."
helm upgrade --install minecraft "${ROOT}/helm/minecraft" \
  -n minecraft --create-namespace \
  -f "${ROOT}/helm/minecraft/values-prod.yaml" \
  --set "image.repository=${USE_REPO}" \
  --set "image.tag=${USE_TAG}" \
  --set "backup.bucketName=${BUCKET}" \
  --wait --timeout 10m

echo "==> Argo CD (GitOps)..."
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update argo
helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --set server.service.type=LoadBalancer \
  --wait --timeout 10m || echo "WARN: Argo CD optional"

MC_IP="$(kubectl get svc minecraft -n minecraft -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo pending)"
GRAF_IP="$(kubectl get svc -n monitoring kube-prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo pending)"

echo ""
echo "============================================"
echo "Production v2 deployed"
echo "Minecraft:  ${MC_IP}:25565"
echo "Grafana:    http://${GRAF_IP}  (admin / changeme-grafana)"
echo "Logs:       Console → Logging → ${LOG_GROUP_ID}"
echo "Image:      ${USE_REPO}:${USE_TAG}"
echo "============================================"
