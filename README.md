# Minecraft на Yandex Cloud Kubernetes

DevOps-проект: один Minecraft-сервер (Java/Paper), один общий мир, инфраструктура как код.

## Структура

```
├── terraform/
│   ├── modules/vpc/                 # VPC, Security Groups
│   ├── modules/mk8s/                # Managed Kubernetes
│   ├── modules/storage/             # SA + S3 keys для бэкапов
│   ├── modules/lockbox/             # Lockbox + ESO service account
│   ├── modules/container-registry/  # Yandex Container Registry
│   ├── modules/dns/                 # Cloud DNS (опционально)
│   └── envs/dev/
├── k8s/
│   ├── apps/minecraft/              # Сервер + backup CronJob
│   └── platform/                    # External Secrets (Lockbox)
├── docker/                          # Кастомный образ для YCR
├── scripts/
└── .github/workflows/ci.yml
```

## Быстрый старт

```bash
# Полный production v2 (Helm + Logging + Prometheus + Argo CD):
./scripts/deploy-v2.sh

# Или по шагам:
./scripts/deploy-infra.sh
./scripts/deploy-platform.sh
./scripts/deploy-minecraft.sh   # Helm chart
```

## Production v2 (новое)

| Компонент | Технология |
|-----------|------------|
| Minecraft | **Helm chart** `helm/minecraft/` |
| Образ | **Yandex Container Registry** (`./scripts/build-push-image.sh`) |
| Логи | **Fluent Bit** → **Cloud Logging** |
| Метрики | **kube-prometheus-stack** + **Grafana** (LoadBalancer) |
| GitOps | **Argo CD** + `argocd/applications/minecraft.yaml` |
| CI/CD | **GitHub Actions** deploy на main |

```bash
./scripts/deploy-v2.sh
```

Grafana: `kubectl get svc -n monitoring kube-prometheus-grafana`  
Логи: консоль YC → Logging → `minecraft-k8s-logs`

Подключение: `kubectl get svc minecraft -n minecraft` → `EXTERNAL-IP:25565`

---

## Фазы 0–4 — Базовый сервер ✅

См. разделы ниже: аккаунт YC → Terraform → Minecraft Deployment.

---

## Фаза 5 — Бэкапы (Object Storage) ✅

**Что создано:**
- Service Account `minecraft-backup-sa` с ролью `storage.editor`
- Bucket `minecraft-world-backup-b1gqbqg5` (Object Storage)
- CronJob `minecraft-world-backup` — каждые 6 часов:
  1. `save-all` через RCON
  2. `tar` папки `world/`
  3. Upload в S3 (`storage.yandexcloud.net`)

**Ручной бэкап:**
```bash
kubectl create job --from=cronjob/minecraft-world-backup backup-manual -n minecraft
kubectl logs -f job/backup-manual -n minecraft
```

**Список бэкапов:**
```bash
yc storage s3api list-objects-v2 --bucket minecraft-world-backup-b1gqbqg5
```

---

## Фаза 6 — Lockbox + External Secrets ✅

**Что создано:**
- Lockbox secret `minecraft-secrets` (RCON + S3 keys)
- External Secrets Operator в namespace `platform`
- SecretStore → синхронизация в K8s Secret `minecraft-secrets`

**Проверка:**
```bash
kubectl get externalsecret -n minecraft
kubectl get secret minecraft-secrets -n minecraft
```

RCON-пароль (из Terraform):
```bash
cd terraform/envs/dev && tofu output -raw rcon_password
```

---

## Фаза 7 — Container Registry + CI/CD

**Container Registry** создан: `minecraft-registry`

**Сборка и push образа:**
```bash
./scripts/build-push-image.sh
```

**GitHub Actions** (`.github/workflows/ci.yml`):
- `tofu validate` + `helm lint` на каждый PR
- Deploy Helm chart на push в `main`

**Секреты репозитория** (Settings → Secrets → Actions):

| Секрет | Значение |
|--------|----------|
| `YC_FOLDER_ID` | ID каталога YC, напр. `b1gqbqg5o03ev89s9m01` |
| `YC_SA_JSON_CREDENTIALS` | JSON-ключ service account (не IAM-токен, не протухает) |

Создание SA и ключа:
```bash
./scripts/setup-github-actions-sa.sh
gh secret set YC_SA_JSON_CREDENTIALS < /path/to/key.json -R L3xu5/minecraft-yc-devops
gh secret set YC_FOLDER_ID -b "b1gqbqg5o03ev89s9m01" -R L3xu5/minecraft-yc-devops
kubectl apply -f k8s/platform/github-actions-rbac.yaml
```

---

## Фаза 8 — Lifecycle + Watchdog ✅

**Object Storage lifecycle** (`config/storage-lifecycle.json`):
- 0–7 дней: STANDARD
- 7–30 дней: COLD
- 30+ дней: DELETE

```bash
./scripts/setup-lifecycle.sh
```

**Watchdog CronJob** — каждые 15 мин проверяет pod и failed backups (логи → Cloud Logging).

## Фаза 9 — Cloud DNS (когда есть домен)

```bash
./scripts/setup-dns.sh mydomain.ru.
# пропиши NS у регистратора → mc.mydomain.ru:25565
```

## Фаза 10 — Cloud Monitoring

Инструкция: [docs/monitoring.md](docs/monitoring.md)

---

## Предварительные требования

- [yc CLI](https://yandex.cloud/ru/docs/cli/quickstart)
- [OpenTofu](https://opentofu.org/) или Terraform >= 1.5
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/) (для External Secrets)

## Фаза 0 — Настройка Yandex Cloud

```bash
yc init
yc config get folder-id
yc managed-kubernetes list-versions
```

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
# заполни folder_id, k8s_version
```

## Фаза 1–2 — Инфраструктура

```bash
export YC_TOKEN=$(yc iam create-token)
cd terraform/envs/dev
tofu init && tofu apply
yc managed-kubernetes cluster get-credentials --name minecraft-k8s --external --force
```

## Фаза 3–4 — Minecraft

Секреты теперь из Lockbox (после `./scripts/deploy-platform.sh`):

```bash
kubectl apply -k k8s/apps/minecraft/
kubectl get svc -n minecraft -w
```

## Как сохраняется мир

- PVC `minecraft-data` → Yandex Disk 20 Gi SSD
- `replicas: 1` + `strategy: Recreate`
- Бэкапы в Object Storage каждые 6 часов

## Удаление

```bash
cd terraform/envs/dev && tofu destroy
yc storage bucket delete --name minecraft-world-backup-b1gqbqg5
```

## Стоимость (ориентир)

~5 000–9 000 ₽/мес (кластер + NLB + диски + Storage + Lockbox)

## Troubleshooting

| Проблема | Решение |
|----------|---------|
| ESO webhook timeout | `./scripts/deploy-platform.sh` (failurePolicy=Ignore) |
| Backup InvalidBucketName | `./scripts/deploy-platform.sh` обновит ConfigMap |
| Invalid session | `ONLINE_MODE=FALSE` уже в deployment |
| ExternalSecret не sync | `kubectl delete secret minecraft-secrets -n minecraft` — пересоздаст ESO |
