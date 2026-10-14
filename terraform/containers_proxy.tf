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

    user_account {
      keys = [var.ssh_public_key]
    }

  }

  cpu {
    cores = 1
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
    name = "eth0"
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

  lifecycle {
    ignore_changes = [
      initialization[0].user_account,
      operating_system[0].template_file_id,
    ]
  }
}
