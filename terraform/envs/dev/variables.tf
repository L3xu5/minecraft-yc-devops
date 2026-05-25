variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder ID (yc config get folder-id)"
}

variable "zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Availability zone for subnet and nodes"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version. Run: yc managed-kubernetes list-versions"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_memory_gb" {
  type    = number
  default = 8
}

variable "cluster_name" {
  type    = string
  default = "minecraft-k8s"
}

# --- Фазы 5–7 ---

variable "enable_backups" {
  type    = bool
  default = true
}

variable "enable_lockbox" {
  type    = bool
  default = true
}

variable "enable_container_registry" {
  type    = bool
  default = true
}

variable "enable_logging" {
  type    = bool
  default = true
}

variable "enable_dns" {
  type    = bool
  default = false
}

variable "backup_bucket_name" {
  type        = string
  description = "Globally unique Object Storage bucket name"
}

variable "rcon_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "RCON password; generated randomly if null"
}

variable "dns_zone" {
  type        = string
  default     = ""
  description = "Public DNS zone, e.g. example.com."
}

variable "dns_record_name" {
  type    = string
  default = "mc"
}

variable "minecraft_external_ip" {
  type        = string
  default     = ""
  description = "LoadBalancer IP for DNS A-record (kubectl get svc -n minecraft)"
}
