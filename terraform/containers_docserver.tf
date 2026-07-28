resource "proxmox_virtual_environment_container" "docserver" {
  node_name    = var.proxmox_node
  vm_id        = 107
  unprivileged = false
  description  = "Document server"

  timeout_create = 1800
  timeout_delete = 60

  features {
    mount   = ["nfs"]
    nesting = true
  }

  initialization {
    hostname = "docserver"

    ip_config {
      ipv4 {
        address = "192.168.10.16/24"
        gateway = "192.168.10.1"
      }
    }

  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4000
    swap      = 2000
  }

  disk {
    datastore_id = "local-lvm"
    size         = 24
  }

  network_interface {
    name     = "eth0"
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
