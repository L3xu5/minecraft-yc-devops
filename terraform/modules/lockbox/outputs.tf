output "lockbox_secret_id" {
  value = yandex_lockbox_secret.minecraft.id
}

output "lockbox_secret_name" {
  value = yandex_lockbox_secret.minecraft.name
}

output "eso_service_account_id" {
  value = yandex_iam_service_account.eso.id
}

output "eso_authorized_key" {
  value     = yandex_iam_service_account_key.eso.private_key
  sensitive = true
}
