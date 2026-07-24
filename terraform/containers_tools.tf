resource "proxmox_virtual_environment_container" "tools" {
  node_name    = var.proxmox_node
  vm_id        = 102
  unprivileged = true
  description  = "CyberChef + pgAdmin"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = true
  }

  initialization {
    hostname = "tools"

    ip_config {
      ipv4 {
        address = "192.168.10.14/24"
        gateway = "192.168.10.1"
      }
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 512
    swap      = 256
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
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
