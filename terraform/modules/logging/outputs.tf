output "log_group_id" {
  value = yandex_logging_group.main.id
}

output "logging_sa_id" {
  value = yandex_iam_service_account.logging.id
}
