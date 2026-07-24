resource "proxmox_backup_job" "monthly" {
  id       = "backup-cfcbe978-42c4"
  schedule = "*-*-01 00:00"
  storage  = "nas-backup"

  all             = true
  compress        = "zstd"
  enabled         = true
  mode            = "snapshot"
  node            = "pve"
  notes_template  = "{{guestname}}"

  prune_backups = {
    keep-last = "5"
  }
}
