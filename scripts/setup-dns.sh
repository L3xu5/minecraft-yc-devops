#!/usr/bin/env bash
set -euo pipefail

# Cloud DNS: создаёт зону и A-запись mc.<domain> → IP Minecraft LoadBalancer
#
# Usage:
#   ./scripts/setup-dns.sh example.com.
#   ./scripts/setup-dns.sh example.com. 158.160.33.131

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT}/terraform/envs/dev"

if command -v tofu >/dev/null; then TF=tofu; else TF=terraform; fi

DOMAIN="${1:-}"
IP="${2:-$(kubectl get svc minecraft -n minecraft -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)}"

if [[ -z "${DOMAIN}" ]]; then
  echo "Usage: $0 <dns-zone> [minecraft-external-ip]"
  echo "Example: $0 mydomain.ru. 158.160.33.131"
  exit 1
fi

[[ "${DOMAIN}" == *"." ]] || DOMAIN="${DOMAIN}."

if [[ -z "${IP}" ]]; then
  echo "Could not detect LoadBalancer IP. Pass it as second argument."
  exit 1
fi

echo "==> DNS: mc.${DOMAIN} → ${IP}"

export YC_TOKEN="$(yc iam create-token)"

# Patch tfvars
TFVARS="${TF_DIR}/terraform.tfvars"
if grep -q '^enable_dns' "${TFVARS}"; then
  sed -i '' "s/^enable_dns.*$/enable_dns = true/" "${TFVARS}"
else
  echo "enable_dns = true" >> "${TFVARS}"
fi

grep -q '^dns_zone' "${TFVARS}" && sed -i '' "s|^dns_zone.*$|dns_zone = \"${DOMAIN}\"|" "${TFVARS}" \
  || echo "dns_zone = \"${DOMAIN}\"" >> "${TFVARS}"

grep -q '^minecraft_external_ip' "${TFVARS}" && sed -i '' "s|^minecraft_external_ip.*$|minecraft_external_ip = \"${IP}\"|" "${TFVARS}" \
  || echo "minecraft_external_ip = \"${IP}\"" >> "${TFVARS}"

${TF} -chdir="${TF_DIR}" apply -auto-approve

echo ""
echo "==> NS-серверы (пропиши у регистратора домена):"
yc dns zone list --format json | python3 -c "
import sys, json
domain = '${DOMAIN}'.rstrip('.')
for z in json.load(sys.stdin):
    if z.get('zone', '').rstrip('.') == domain:
        for ns in z.get('name_servers', []):
            print('  ', ns)
"

echo ""
echo "После делегирования DNS подключайся: mc.${DOMAIN}:25565"
