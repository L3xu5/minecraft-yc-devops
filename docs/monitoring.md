# Cloud Monitoring — Minecraft K8s

## Встроенный мониторинг MK8s

Консоль → **Managed Kubernetes** → `minecraft-k8s` → вкладка **Мониторинг**.

Метрики: CPU/RAM нод, сеть, состояние pod'ов.

## Watchdog CronJob (в кластере)

Каждые 15 минут проверяет:
- pod Minecraft в состоянии Ready
- нет failed backup jobs

Логи с `ALERT:` попадают в **Cloud Logging**:
```bash
kubectl logs -l job-name -n minecraft --tail=20
# или CronJob:
kubectl logs -l app.kubernetes.io/name=minecraft-watchdog -n minecraft
```

## Алерты в Cloud Monitoring (рекомендуется настроить вручную)

1. [Консоль Monitoring](https://console.cloud.yandex.ru/monitoring) → **Алерты** → **Создать**
2. Создай **канал уведомлений** (email / Telegram bot)

Примеры алертов:

| Алерт | Метрика / условие |
|-------|-------------------|
| Нода перегружена | CPU > 90% на node group 5 мин |
| Мало памяти | RAM > 90% на node 5 мин |
| Pod не Running | `kube_pod_status_ready` для minecraft (если установлен kube-state-metrics) |

Для MK8s базовые метрики нод доступны без дополнительной установки.

## Cloud Logging

Консоль → **Logging** → фильтр по кластеру `minecraft-k8s`, namespace `minecraft`.

Полезные запросы:
```
jsonPayload.message:"ALERT"
resource_type=k8s_container AND resource.labels.namespace_name="minecraft"
```

## Billing alert

Консоль → **Биллинг** → **Бюджеты** → лимит 5000–8000 ₽, уведомление на 80%.
