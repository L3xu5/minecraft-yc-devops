output "service_account_id" {
  value = yandex_iam_service_account.velero.id
}

output "access_key" {
  value     = yandex_iam_service_account_static_access_key.velero.access_key
  sensitive = true
}

output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.velero.secret_key
  sensitive = true
}
