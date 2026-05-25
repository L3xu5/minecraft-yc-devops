output "registry_id" {
  value = yandex_container_registry.main.id
}

output "registry_name" {
  value = yandex_container_registry.main.name
}

output "minecraft_image" {
  value = "cr.yandex/${yandex_container_registry.main.id}/minecraft-server"
}
