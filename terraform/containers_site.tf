resource "proxmox_virtual_environment_container" "site" {
  node_name    = var.proxmox_node
  vm_id        = 104
  unprivileged = false
  description  = "Frigate NVR + AI object detection"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = false
  }

  initialization {
    hostname = "site"

    ip_config {
      ipv4 {
        address = "192.168.10.13/24"
        gateway = "192.168.10.1"
      }
    }

  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8000
    swap      = 8000
  }

  disk {
    datastore_id = "local-lvm"
    size         = 32
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
