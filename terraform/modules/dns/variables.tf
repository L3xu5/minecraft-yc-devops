variable "zone_name" {
  type        = string
  description = "DNS zone name, e.g. example.com."
}

variable "record_name" {
  type        = string
  default     = "mc"
  description = "Subdomain for Minecraft server"
}

variable "minecraft_ip" {
  type        = string
  description = "External IP of Minecraft LoadBalancer service"
}
