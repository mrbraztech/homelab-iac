resource "proxmox_virtual_environment_container" "proxy" {
  node_name    = var.proxmox_node
  vm_id        = 101
  unprivileged = true
  description  = "Nginx Proxy Manager"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = true
  }

  initialization {
    hostname = "proxy"

    ip_config {
      ipv4 {
        address = "192.168.10.3/24"
        gateway = "192.168.10.1"
      }
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 256
    swap      = 256
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
