output "tools_id" {
  description = "VMID do container tools"
  value       = proxmox_virtual_environment_container.tools.vm_id
}

output "tools_ipv4" {
  description = "Endereço IPv4 do container tools"
  value       = proxmox_virtual_environment_container.tools.ipv4
}
