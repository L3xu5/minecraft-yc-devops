variable "folder_id" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "minecraft-k8s"
}

variable "node_group_name" {
  type    = string
  default = "minecraft-nodes"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version, e.g. 1.29. List: yc managed-kubernetes list-versions"
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "subnet_zone" {
  type = string
}

variable "master_cidr" {
  type = string
}

variable "node_cidr" {
  type = string
}

variable "main_security_group_id" {
  type = string
}

variable "public_security_group_id" {
  type = string
}

variable "service_account_name" {
  type    = string
  default = "minecraft-k8s-sa"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "enable_autoscaling" {
  type    = bool
  default = false
}

variable "node_count_min" {
  type    = number
  default = 1
}

variable "node_count_max" {
  type    = number
  default = 2
}

variable "node_cores" {
  type    = number
  default = 4
}

variable "node_memory_gb" {
  type    = number
  default = 8
}

variable "node_disk_gb" {
  type    = number
  default = 64
}

variable "node_disk_type" {
  type    = string
  default = "network-ssd"
}
