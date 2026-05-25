variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "zone" {
  type = string
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "cluster_name" {
  type    = string
  default = "minecraft-postgres"
}

variable "postgresql_version" {
  type    = string
  default = "16"
}

variable "resource_preset_id" {
  type    = string
  default = "s2.micro"
}

variable "disk_size_gb" {
  type    = number
  default = 10
}

variable "database_name" {
  type    = string
  default = "minecraft"
}

variable "database_user" {
  type    = string
  default = "minecraft"
}

variable "database_password" {
  type      = string
  sensitive = true
}
