resource "proxmox_virtual_environment_container" "vpn" {
  node_name    = var.proxmox_node
  vm_id        = 105
  unprivileged = true
  description  = "Tailscale VPN mesh"

  timeout_create = 1800
  timeout_delete = 60

  features {
    nesting = true
    keyctl  = true
  }

  initialization {
    hostname = "vpn"

    ip_config {
      ipv4 {
        address = "192.168.10.4/24"
        gateway = "192.168.10.1"
      }
    }

  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
  }

  device_passthrough {
    path = "/dev/net/tun"
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

  startup {
    order = 1
  }
}
