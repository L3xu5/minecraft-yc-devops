terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_iam_service_account" "logging" {
  name        = var.sa_name
  description = "Fluent Bit → Yandex Cloud Logging"
}

resource "yandex_resourcemanager_folder_iam_member" "logging_writer" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.logging.id}"
}

resource "yandex_logging_group" "main" {
  name        = var.log_group_name
  folder_id   = var.folder_id
  retention_period = "168h"
}

resource "yandex_iam_service_account_key" "logging" {
  service_account_id = yandex_iam_service_account.logging.id
  description        = "Authorized key for Fluent Bit"
}
