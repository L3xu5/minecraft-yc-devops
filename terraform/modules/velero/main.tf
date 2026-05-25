resource "yandex_iam_service_account" "velero" {
  name        = var.sa_name
  description = "Velero cluster backups to Object Storage"
}

resource "yandex_resourcemanager_folder_iam_member" "velero_storage" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.velero.id}"
}

resource "yandex_iam_service_account_static_access_key" "velero" {
  service_account_id = yandex_iam_service_account.velero.id
  description        = "Velero S3 credentials"
}
