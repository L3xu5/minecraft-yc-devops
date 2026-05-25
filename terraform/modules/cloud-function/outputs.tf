output "function_id" {
  value = yandex_function.status.id
}

output "function_url" {
  value = "https://functions.yandexcloud.net/${yandex_function.status.id}"
}

output "service_account_id" {
  value = yandex_iam_service_account.function.id
}
