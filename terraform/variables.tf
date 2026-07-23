variable "proxmox_endpoint" {
  description = "URL da API Proxmox"
  type        = string
  default     = "https://192.168.10.10:8006"
}

variable "proxmox_user" {
  description = "Usuário da API Proxmox"
  type        = string
}

variable "proxmox_password" {
  description = "Senha do usuário Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nome do node Proxmox"
  type        = string
  default     = "pve"
}

variable "minio_access_key" {
  description = "Chave de acesso MinIO"
  type        = string
}

variable "minio_secret_key" {
  description = "Secret key MinIO"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Chave pública SSH"
  type        = string
}
