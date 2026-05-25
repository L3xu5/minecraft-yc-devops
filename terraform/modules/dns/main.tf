terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_dns_zone" "main" {
  name        = replace(var.zone_name, ".", "-")
  zone        = var.zone_name
  description = "DNS zone for Minecraft server"
  public      = true
}

resource "yandex_dns_recordset" "minecraft" {
  zone_id = yandex_dns_zone.main.id
  name    = "${var.record_name}.${var.zone_name}"
  type    = "A"
  ttl     = 300
  data    = [var.minecraft_ip]
}
