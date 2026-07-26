resource "proxmox_virtual_environment_container" "gateway" {
  node_name    = var.proxmox_node
  vm_id        = 109
  unprivileged = true
  description  = "Gateway / reverse proxy"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = false
  }

  initialization {
    hostname = "gateway"

    ip_config {
      ipv4 {
        address = "192.168.10.5/24"
        gateway = "192.168.10.1"
      }
    }

  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  network_interface {
    name     = "eth0"
    firewall = true
  }

  operating_system {
    template_file_id = ""
    type             = "debian"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  started       = true
  start_on_boot = true
}
