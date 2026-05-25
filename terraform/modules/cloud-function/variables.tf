variable "folder_id" {
  type = string
}

variable "sa_name" {
  type    = string
  default = "minecraft-function-sa"
}

variable "function_name" {
  type    = string
  default = "minecraft-status"
}

variable "minecraft_host" {
  type        = string
  description = "Minecraft NLB IP or hostname"
}

variable "minecraft_port" {
  type    = string
  default = "25565"
}
