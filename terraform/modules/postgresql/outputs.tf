output "cluster_id" {
  value = yandex_mdb_postgresql_cluster.main.id
}

output "host_fqdn" {
  value = yandex_mdb_postgresql_cluster.main.host[0].fqdn
}

output "database_name" {
  value = yandex_mdb_postgresql_database.minecraft.name
}

output "database_user" {
  value = yandex_mdb_postgresql_user.minecraft.name
}
