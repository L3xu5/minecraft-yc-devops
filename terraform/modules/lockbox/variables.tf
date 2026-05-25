variable "folder_id" {
  type = string
}

variable "secret_name" {
  type    = string
  default = "minecraft-secrets"
}

variable "rcon_password" {
  type      = string
  sensitive = true
}

variable "s3_access_key" {
  type      = string
  sensitive = true
}

variable "s3_secret_key" {
  type      = string
  sensitive = true
}

variable "eso_sa_name" {
  type    = string
  default = "minecraft-eso-sa"
}
