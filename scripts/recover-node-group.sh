#!/usr/bin/env bash
# Восстановление node group после vpc.externalAddressesCreation.rate exceeded.
# Не запускай tofu apply в цикле — каждая попытка создаёт VM и тратит квоту на внешние IP.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"

if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi
command -v yc >/dev/null || { echo "Install yc CLI"; exit 1; }

export YC_TOKEN="$(yc iam create-token)"

echo "==> Текущие node groups:"
yc managed-kubernetes node-group list || true

STUCK="$(yc managed-kubernetes node-group list --format json 2>/dev/null \
  | python3 -c "
import json, sys
for ng in json.load(sys.stdin):
    if ng.get('status') in ('PROVISIONING', 'RECONCILING', 'DEGRADED'):
        print(ng['id'])
" 2>/dev/null || true)"

if [[ -n "${STUCK}" ]]; then
  echo ""
  echo "WARN: Найдены зависшие node groups — удаляем, чтобы остановить retry создания VM:"
  while read -r id; do
    [[ -z "${id}" ]] && continue
    echo "    yc managed-kubernetes node-group delete ${id} --async"
    yc managed-kubernetes node-group delete "${id}" --async
  done <<< "${STUCK}"
  echo ""
  echo "Подожди 2–3 мин, пока удаление завершится, затем снова запусти этот скрипт."
  exit 0
fi

echo ""
echo "==> Ожидание: rate-limit YC на внешние IP сбрасывается ~60 мин после последней ошибки."
echo "    Не запускай apply чаще одного раза в час."
if [[ "${RECOVER_FORCE:-}" != "1" ]]; then
  read -r -p "Прошло >= 60 мин с последней ошибки? [y/N] " ans
  [[ "${ans,,}" == "y" ]] || { echo "Отмена. Подожди и повтори."; exit 0; }
fi

echo ""
echo "==> Terraform: NAT gateway + node group (без public IP на worker)..."
${TF} -chdir="${TF_DIR}" init -upgrade >/dev/null
${TF} -chdir="${TF_DIR}" state rm module.mk8s.yandex_kubernetes_node_group.main 2>/dev/null || true
${TF} -chdir="${TF_DIR}" apply -auto-approve \
  -target=module.vpc \
  -target=module.mk8s.yandex_kubernetes_node_group.main

echo ""
echo "==> Проверка:"
yc managed-kubernetes node-group list
echo ""
echo "Когда STATUS=RUNNING:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
