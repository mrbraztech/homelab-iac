resource "proxmox_virtual_environment_container" "ninerouter" {
  node_name    = var.proxmox_node
  vm_id        = 111
  unprivileged = true
  description  = "9Router AI proxy + Headroom"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = true
  }

  initialization {
    hostname = "9router"

    ip_config {
      ipv4 {
        address = "192.168.10.19/24"
        gateway = "192.168.10.1"
      }
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 1024
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10
  }

  network_interface {
    name     = "eth0"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
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
