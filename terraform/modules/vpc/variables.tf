variable "network_name" {
  type    = string
  default = "minecraft-network"
}

variable "subnet_name" {
  type    = string
  default = "minecraft-subnet-a"
}

variable "zone" {
  type = string
}

variable "subnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "master_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "node_cidr" {
  type    = string
  default = "10.3.0.0/16"
}

variable "minecraft_port" {
  type    = number
  default = 25565
}
