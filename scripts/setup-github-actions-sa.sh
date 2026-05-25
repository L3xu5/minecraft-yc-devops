#!/usr/bin/env bash
# Создаёт service account для GitHub Actions и печатает команду для секрета.
set -euo pipefail

SA_NAME="${SA_NAME:-github-actions}"
FOLDER_ID="${FOLDER_ID:-$(yc config get folder-id)}"
CLUSTER_NAME="${CLUSTER_NAME:-minecraft-k8s}"
REPO="${GITHUB_REPO:-L3xu5/minecraft-yc-devops}"

echo "==> Folder: ${FOLDER_ID}"

SA_ID="$(yc iam service-account list --folder-id "${FOLDER_ID}" --format json \
  | python3 -c "import sys,json; print(next((x['id'] for x in json.load(sys.stdin) if x['name']=='${SA_NAME}'), ''))")"

if [[ -z "${SA_ID}" ]]; then
  SA_ID="$(yc iam service-account create --name "${SA_NAME}" --folder-id "${FOLDER_ID}" --format json \
    | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"
  echo "Created service account ${SA_NAME}: ${SA_ID}"
else
  echo "Using existing service account ${SA_NAME}: ${SA_ID}"
fi

for ROLE in k8s.admin container-registry.images.puller; do
  yc resource-manager folder add-access-binding "${FOLDER_ID}" \
    --role "${ROLE}" --subject "serviceAccount:${SA_ID}" >/dev/null 2>&1 || true
done

for ROLE in k8s.cluster-api.cluster-admin k8s.clusters.agent; do
  yc managed-kubernetes cluster add-access-binding "${CLUSTER_NAME}" \
    --role "${ROLE}" --subject "serviceAccount:${SA_ID}" >/dev/null 2>&1 || true
done

KEY_FILE="$(mktemp)"
yc iam key create --service-account-id "${SA_ID}" --output "${KEY_FILE}" >/dev/null

echo ""
echo "==> GitHub secret (один раз):"
echo "gh secret set YC_SA_JSON_CREDENTIALS < \"${KEY_FILE}\" -R ${REPO}"
echo ""
echo "==> Также нужен секрет YC_FOLDER_ID=${FOLDER_ID}"
echo ""
echo "==> RBAC в кластере (если ещё не применён):"
echo "kubectl apply -f k8s/platform/github-actions-rbac.yaml"
echo ""
echo "JSON-ключ сохранён во временный файл: ${KEY_FILE}"
echo "Удали его после добавления секрета: rm -f \"${KEY_FILE}\""
