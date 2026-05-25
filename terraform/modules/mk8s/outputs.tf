output "cluster_id" {
  value = yandex_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = yandex_kubernetes_cluster.main.name
}

output "service_account_id" {
  value = yandex_iam_service_account.k8s.id
}
