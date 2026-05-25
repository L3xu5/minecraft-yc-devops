variable "folder_id" {
  type = string
}

variable "sa_name" {
  type    = string
  default = "minecraft-logging-sa"
}

variable "log_group_name" {
  type    = string
  default = "minecraft-k8s-logs"
}
