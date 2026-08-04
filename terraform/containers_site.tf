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
    mount   = ["nfs"]
  }

  initialization {
    hostname = "site"

    ip_config {
      ipv4 {
        address = "192.168.10.13/24"
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
    dedicated = 8000
    swap      = 8000
  }

  disk {
    datastore_id = "local-lvm"
    size         = 32
  }

  mount_point {
    volume = "/mnt/pve/nas-surveillance"
    path   = "/mnt/surveillance"
  }

  # GPU passthrough for Frigate (/dev/dri) requires manual LXC config:
  #   lxc.cgroup2.devices.allow: c 226:* rwm
  #   lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
  # Applied directly on Proxmox host until BPG provider supports raw LXC entries.

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
    ignore_changes = [initialization[0].user_account]
  }
}
