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

output "network_id" {
  description = "VMID do container network"
  value       = proxmox_virtual_environment_container.network.vm_id
}

output "network_ipv4" {
  description = "Endereço IPv4 do container network"
  value       = proxmox_virtual_environment_container.network.ipv4
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

output "mail_id" {
  description = "VMID do container mail"
  value       = proxmox_virtual_environment_container.mail.vm_id
}

output "mail_ipv4" {
  description = "Endereço IPv4 do container mail"
  value       = proxmox_virtual_environment_container.mail.ipv4
}

output "ai_gateway_id" {
  description = "VMID do container ai-gateway"
  value       = proxmox_virtual_environment_container.ai_gateway.vm_id
}

output "ai_gateway_ipv4" {
  description = "Endereço IPv4 do container ai-gateway"
  value       = proxmox_virtual_environment_container.ai_gateway.ipv4
}

output "agent_id" {
  description = "VMID do container agent"
  value       = proxmox_virtual_environment_container.agent.vm_id
}

output "agent_ipv4" {
  description = "Endereço IPv4 do container agent"
  value       = proxmox_virtual_environment_container.agent.ipv4
}

output "vault_id" {
  description = "VMID do container vault"
  value       = proxmox_virtual_environment_container.vault.vm_id
}

output "vault_ipv4" {
  description = "Endereço IPv4 do container vault"
  value       = proxmox_virtual_environment_container.vault.ipv4
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

output "nas_surveillance_id" {
  description = "ID do storage NFS nas-surveillance"
  value       = proxmox_storage_nfs.nas_surveillance.id
}

output "backup_job_id" {
  description = "ID do backup job mensal"
  value       = proxmox_backup_job.monthly.id
}
