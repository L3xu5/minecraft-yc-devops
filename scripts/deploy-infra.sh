#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"

echo "==> Checking prerequisites..."
command -v yc >/dev/null || { echo "Install yc CLI: https://yandex.cloud/ru/docs/cli/quickstart"; exit 1; }
if command -v tofu >/dev/null; then
  TF=tofu
elif command -v terraform >/dev/null; then
  TF=terraform
else
  echo "Install OpenTofu or Terraform: brew install opentofu"
  exit 1
fi

if [[ ! -f "${TF_DIR}/terraform.tfvars" ]]; then
  echo "Create ${TF_DIR}/terraform.tfvars from terraform.tfvars.example"
  exit 1
fi

CLUSTER_NAME="$(grep cluster_name "${TF_DIR}/terraform.tfvars" | cut -d'"' -f2 || echo minecraft-k8s)"

echo "==> Terraform init & apply..."
export YC_TOKEN="$(yc iam create-token)"
cd "${TF_DIR}"
${TF} init
${TF} apply -auto-approve

echo "==> Configuring kubectl..."
yc managed-kubernetes cluster get-credentials \
  --name "${CLUSTER_NAME}" \
  --external \
  --force

echo "==> Cluster nodes:"
kubectl get nodes

echo ""
echo "Next: create secret and deploy Minecraft:"
echo "  kubectl create secret generic minecraft-secrets --from-literal=rcon-password='CHANGE_ME' -n minecraft"
echo "  kubectl apply -k ${ROOT}/k8s/apps/minecraft/"
echo "  kubectl get svc -n minecraft -w"
