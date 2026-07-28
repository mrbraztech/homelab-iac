resource "proxmox_virtual_environment_container" "dns" {
  node_name    = var.proxmox_node
  vm_id        = 100
  unprivileged = true
  description  = "Pi-hole DNS server"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = true
  }

  initialization {
    hostname = "dns"

    ip_config {
      ipv4 {
        address = "192.168.10.2/24"
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

  startup {
    order = 1
  }
}
