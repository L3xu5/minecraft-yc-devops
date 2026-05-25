output "minecraft_fqdn" {
  value = yandex_dns_recordset.minecraft.name
}

output "zone_id" {
  value = yandex_dns_zone.main.id
}
