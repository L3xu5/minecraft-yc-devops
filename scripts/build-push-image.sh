#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"

if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi

REGISTRY_ID="$(${TF} -chdir="${TF_DIR}" output -raw container_registry_id)"
IMAGE="cr.yandex/${REGISTRY_ID}/minecraft-server:latest"

echo "==> Building ${IMAGE}..."
docker build -t "${IMAGE}" "${ROOT}/docker"

echo "==> Authenticating to Yandex Container Registry..."
yc container registry configure-docker

echo "==> Pushing..."
docker push "${IMAGE}"

echo ""
echo "Update deployment image to: ${IMAGE}"
