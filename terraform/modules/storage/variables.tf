variable "folder_id" {
  type = string
}

variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name for world backups"
}

variable "sa_name" {
  type    = string
  default = "minecraft-backup-sa"
}
