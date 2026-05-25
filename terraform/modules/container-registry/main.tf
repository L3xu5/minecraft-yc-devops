terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_container_registry" "main" {
  name = var.registry_name
}

resource "yandex_container_repository" "minecraft" {
  name = "${yandex_container_registry.main.id}/minecraft-server"
}
