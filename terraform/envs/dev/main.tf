resource "random_password" "rcon" {
  length  = 24
  special = false
}

locals {
  rcon_password = coalesce(var.rcon_password, random_password.rcon.result)
}

module "vpc" {
  source = "../../modules/vpc"

  zone = var.zone
}

module "mk8s" {
  source = "../../modules/mk8s"

  folder_id                = var.folder_id
  cluster_name             = var.cluster_name
  k8s_version              = var.k8s_version
  network_id               = module.vpc.network_id
  subnet_id                = module.vpc.subnet_id
  subnet_zone              = module.vpc.subnet_zone
  master_cidr              = "10.2.0.0/16"
  node_cidr                = "10.3.0.0/16"
  main_security_group_id   = module.vpc.main_security_group_id
  public_security_group_id = module.vpc.public_security_group_id
  node_count               = var.node_count
  node_memory_gb           = var.node_memory_gb
  enable_autoscaling       = var.enable_node_autoscaling
  node_count_min           = var.node_count_min
  node_count_max           = var.node_count_max
  node_preemptible         = var.node_preemptible
}

module "storage" {
  count  = var.enable_backups ? 1 : 0
  source = "../../modules/storage"

  folder_id   = var.folder_id
  bucket_name = var.backup_bucket_name
}

module "lockbox" {
  count  = var.enable_lockbox ? 1 : 0
  source = "../../modules/lockbox"

  folder_id     = var.folder_id
  rcon_password = local.rcon_password
  s3_access_key = var.enable_backups ? module.storage[0].access_key : "disabled"
  s3_secret_key = var.enable_backups ? module.storage[0].secret_key : "disabled"
}

module "container_registry" {
  count  = var.enable_container_registry ? 1 : 0
  source = "../../modules/container-registry"
}

module "logging" {
  count  = var.enable_logging ? 1 : 0
  source = "../../modules/logging"

  folder_id = var.folder_id
}

module "dns" {
  count  = var.enable_dns && var.dns_zone != "" && var.minecraft_external_ip != "" ? 1 : 0
  source = "../../modules/dns"

  zone_name    = var.dns_zone
  record_name  = var.dns_record_name
  minecraft_ip = var.minecraft_external_ip
}

module "velero" {
  count  = var.enable_velero ? 1 : 0
  source = "../../modules/velero"

  folder_id = var.folder_id
}
