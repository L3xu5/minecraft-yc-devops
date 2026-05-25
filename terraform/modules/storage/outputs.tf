output "bucket_name" {
  value = var.bucket_name
}

output "access_key" {
  value     = yandex_iam_service_account_static_access_key.backup.access_key
  sensitive = true
}

output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.backup.secret_key
  sensitive = true
}

output "service_account_id" {
  value = yandex_iam_service_account.backup.id
}
