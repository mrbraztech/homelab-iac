output "tools_id" {
  description = "VMID do container tools"
  value       = proxmox_virtual_environment_container.tools.vm_id
}

output "tools_ipv4" {
  description = "Endereço IPv4 do container tools"
  value       = proxmox_virtual_environment_container.tools.ipv4
}

output "ninerouter_id" {
  description = "VMID do container 9router"
  value       = proxmox_virtual_environment_container.ninerouter.vm_id
}

output "ninerouter_ipv4" {
  description = "Endereço IPv4 do container 9router"
  value       = proxmox_virtual_environment_container.ninerouter.ipv4
}

output "proxy_id" {
  description = "VMID do container proxy"
  value       = proxmox_virtual_environment_container.proxy.vm_id
}

output "proxy_ipv4" {
  description = "Endereço IPv4 do container proxy"
  value       = proxmox_virtual_environment_container.proxy.ipv4
}
