terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_iam_service_account" "backup" {
  name        = var.sa_name
  description = "Upload Minecraft world backups to Object Storage"
}

resource "yandex_resourcemanager_folder_iam_member" "backup_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.backup.id}"
}

resource "yandex_iam_service_account_static_access_key" "backup" {
  service_account_id = yandex_iam_service_account.backup.id
  description        = "S3 access key for Minecraft backup CronJob"
}

# Bucket создаётся через yc CLI (scripts/deploy-platform.sh) — провайдер Terraform
# требует отдельные storage credentials для управления Object Storage.
