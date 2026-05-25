output "cluster_id" {
  value       = module.mk8s.cluster_id
  description = "Kubernetes cluster ID"
}

output "cluster_name" {
  value = module.mk8s.cluster_name
}

output "network_id" {
  value = module.vpc.network_id
}

output "backup_bucket_name" {
  value = var.enable_backups ? module.storage[0].bucket_name : null
}

output "lockbox_secret_name" {
  value = var.enable_lockbox ? module.lockbox[0].lockbox_secret_name : null
}

output "container_registry_id" {
  value = var.enable_container_registry ? module.container_registry[0].registry_id : null
}

output "minecraft_image" {
  value = var.enable_container_registry ? "cr.yandex/${module.container_registry[0].registry_id}/minecraft-server:latest" : null
}

output "log_group_id" {
  value = var.enable_logging ? module.logging[0].log_group_id : null
}

output "logging_sa_id" {
  value = var.enable_logging ? module.logging[0].logging_sa_id : null
}

output "minecraft_fqdn" {
  value = var.enable_dns && var.dns_zone != "" && var.minecraft_external_ip != "" ? module.dns[0].minecraft_fqdn : null
}

output "rcon_password" {
  value     = local.rcon_password
  sensitive = true
}

output "eso_service_account_id" {
  value = var.enable_lockbox ? module.lockbox[0].eso_service_account_id : null
}

output "next_steps" {
  value = <<-EOT
    Platform:
      ./scripts/deploy-platform.sh

    Minecraft (if not deployed):
      ./scripts/deploy-minecraft.sh

    Manual backup test:
      kubectl create job --from=cronjob/minecraft-world-backup minecraft-backup-manual -n minecraft
  EOT
}
