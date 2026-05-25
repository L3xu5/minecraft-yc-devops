resource "yandex_mdb_postgresql_cluster" "main" {
  name        = var.cluster_name
  environment = "PRODUCTION"
  network_id  = var.network_id

  config {
    version = var.postgresql_version
    resources {
      resource_preset_id = var.resource_preset_id
      disk_type_id       = "network-ssd"
      disk_size          = var.disk_size_gb
    }

    postgresql_config = {
      max_connections = 100
    }
  }

  host {
    zone      = var.zone
    subnet_id = var.subnet_id
  }

  security_group_ids = var.security_group_ids
}

resource "yandex_mdb_postgresql_user" "minecraft" {
  cluster_id  = yandex_mdb_postgresql_cluster.main.id
  name        = var.database_user
  password    = var.database_password
  conn_limit  = 20
}

resource "yandex_mdb_postgresql_database" "minecraft" {
  cluster_id = yandex_mdb_postgresql_cluster.main.id
  name       = var.database_name
  owner      = yandex_mdb_postgresql_user.minecraft.name

  depends_on = [yandex_mdb_postgresql_user.minecraft]
}
