terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_iam_service_account" "eso" {
  name        = var.eso_sa_name
  description = "External Secrets Operator access to Lockbox"
}

resource "yandex_iam_service_account_key" "eso" {
  service_account_id = yandex_iam_service_account.eso.id
  description        = "Authorized key for ESO SecretStore"
}

resource "yandex_lockbox_secret" "minecraft" {
  name        = var.secret_name
  description = "Minecraft RCON and S3 backup credentials"
  folder_id   = var.folder_id
}

resource "yandex_lockbox_secret_version" "minecraft" {
  secret_id = yandex_lockbox_secret.minecraft.id

  entries {
    key        = "rcon-password"
    text_value = var.rcon_password
  }

  entries {
    key        = "s3-access-key"
    text_value = var.s3_access_key
  }

  entries {
    key        = "s3-secret-key"
    text_value = var.s3_secret_key
  }
}

resource "yandex_lockbox_secret_iam_binding" "eso_viewer" {
  secret_id = yandex_lockbox_secret.minecraft.id
  role      = "lockbox.payloadViewer"

  members = [
    "serviceAccount:${yandex_iam_service_account.eso.id}",
  ]
}
