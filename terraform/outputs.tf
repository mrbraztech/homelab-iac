output "dns_id" {
  description = "VMID do container dns"
  value       = proxmox_virtual_environment_container.dns.vm_id
}

output "dns_ipv4" {
  description = "Endereço IPv4 do container dns"
  value       = proxmox_virtual_environment_container.dns.ipv4
}

output "proxy_id" {
  description = "VMID do container proxy"
  value       = proxmox_virtual_environment_container.proxy.vm_id
}

output "proxy_ipv4" {
  description = "Endereço IPv4 do container proxy"
  value       = proxmox_virtual_environment_container.proxy.ipv4
}

output "tools_id" {
  description = "VMID do container tools"
  value       = proxmox_virtual_environment_container.tools.vm_id
}

output "tools_ipv4" {
  description = "Endereço IPv4 do container tools"
  value       = proxmox_virtual_environment_container.tools.ipv4
}

output "omada_id" {
  description = "VMID do container omada"
  value       = proxmox_virtual_environment_container.omada.vm_id
}

output "omada_ipv4" {
  description = "Endereço IPv4 do container omada"
  value       = proxmox_virtual_environment_container.omada.ipv4
}

output "site_id" {
  description = "VMID do container site"
  value       = proxmox_virtual_environment_container.site.vm_id
}

output "site_ipv4" {
  description = "Endereço IPv4 do container site"
  value       = proxmox_virtual_environment_container.site.ipv4
}

output "vpn_id" {
  description = "VMID do container vpn"
  value       = proxmox_virtual_environment_container.vpn.vm_id
}

output "vpn_ipv4" {
  description = "Endereço IPv4 do container vpn"
  value       = proxmox_virtual_environment_container.vpn.ipv4
}

output "cloud_id" {
  description = "VMID do container cloud"
  value       = proxmox_virtual_environment_container.cloud.vm_id
}

output "cloud_ipv4" {
  description = "Endereço IPv4 do container cloud"
  value       = proxmox_virtual_environment_container.cloud.ipv4
}

output "docserver_id" {
  description = "VMID do container docserver"
  value       = proxmox_virtual_environment_container.docserver.vm_id
}

output "docserver_ipv4" {
  description = "Endereço IPv4 do container docserver"
  value       = proxmox_virtual_environment_container.docserver.ipv4
}

output "media_id" {
  description = "VMID do container media"
  value       = proxmox_virtual_environment_container.media.vm_id
}

output "media_ipv4" {
  description = "Endereço IPv4 do container media"
  value       = proxmox_virtual_environment_container.media.ipv4
}

output "gateway_id" {
  description = "VMID do container gateway"
  value       = proxmox_virtual_environment_container.gateway.vm_id
}

output "gateway_ipv4" {
  description = "Endereço IPv4 do container gateway"
  value       = proxmox_virtual_environment_container.gateway.ipv4
}

output "ai_rag_id" {
  description = "VMID do container ai-rag"
  value       = proxmox_virtual_environment_container.ai_rag.vm_id
}

output "ai_rag_ipv4" {
  description = "Endereço IPv4 do container ai-rag"
  value       = proxmox_virtual_environment_container.ai_rag.ipv4
}

output "ninerouter_id" {
  description = "VMID do container 9router"
  value       = proxmox_virtual_environment_container.ninerouter.vm_id
}

output "ninerouter_ipv4" {
  description = "Endereço IPv4 do container 9router"
  value       = proxmox_virtual_environment_container.ninerouter.ipv4
}

output "hermes_id" {
  description = "VMID do container hermes"
  value       = proxmox_virtual_environment_container.hermes.vm_id
}

output "hermes_ipv4" {
  description = "Endereço IPv4 do container hermes"
  value       = proxmox_virtual_environment_container.hermes.ipv4
}

output "nas_backup_id" {
  description = "ID do storage NFS nas-backup"
  value       = proxmox_storage_nfs.nas_backup.id
}

output "nas_nextcloud_id" {
  description = "ID do storage NFS nas-nextcloud"
  value       = proxmox_storage_nfs.nas_nextcloud.id
}

output "nas_media_id" {
  description = "ID do storage NFS nas-media"
  value       = proxmox_storage_nfs.nas_media.id
}

output "nas_catholic_library_id" {
  description = "ID do storage NFS nas-catholic-library"
  value       = proxmox_storage_nfs.nas_catholic_library.id
}

output "backup_job_id" {
  description = "ID do backup job mensal"
  value       = proxmox_backup_job.monthly.id
}
