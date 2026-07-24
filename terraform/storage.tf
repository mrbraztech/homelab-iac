resource "proxmox_storage_nfs" "nas_backup" {
  id     = "nas-backup"
  nodes  = [var.proxmox_node]
  server = "192.168.10.12"
  export = "/export/backup"

  content = ["backup"]

  backups {
    keep_last = 5
  }
}

resource "proxmox_storage_nfs" "nas_nextcloud" {
  id     = "nas-nextcloud"
  nodes  = [var.proxmox_node]
  server = "192.168.10.12"
  export = "/export/nextcloud"

  content = ["images"]
}

resource "proxmox_storage_nfs" "nas_media" {
  id     = "nas-media"
  nodes  = [var.proxmox_node]
  server = "192.168.10.12"
  export = "/export/media"

  content = ["rootdir"]
}

resource "proxmox_storage_nfs" "nas_catholic_library" {
  id     = "nas-catholic-library"
  nodes  = [var.proxmox_node]
  server = "192.168.10.12"
  export = "/export/catholic-library"

  content = ["rootdir"]
}
