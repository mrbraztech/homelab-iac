resource "proxmox_virtual_environment_container" "agent" {
  node_name    = var.proxmox_node
  vm_id        = 111
  unprivileged = false
  description  = "Agent (Hermes AI agent)"

  timeout_create = 1800
  timeout_delete = 60

  features {
    mount   = ["nfs"]
    nesting = true
  }

  initialization {
    hostname = "agent"

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
    cores = 4
  }

  memory {
    dedicated = 8192
    swap      = 2048
  }

  disk {
    datastore_id = "local-lvm"
    size         = 60
  }

  mount_point {
    volume = "/mnt/pve/nas-backup"
    path   = "/mnt/backup"
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
}
