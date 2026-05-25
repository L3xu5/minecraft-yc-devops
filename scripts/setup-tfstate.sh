#!/usr/bin/env bash
set -euo pipefail

BUCKET="${1:-minecraft-tfstate-b1gqbqg5}"

echo "==> Creating Terraform state bucket: ${BUCKET}"
yc storage bucket create --name "${BUCKET}" 2>/dev/null || echo "Bucket exists"

echo ""
echo "==> Enable remote state:"
echo "  cp terraform/envs/dev/backend.tf.example terraform/envs/dev/backend.tf"
echo "  cd terraform/envs/dev && tofu init -migrate-state"
