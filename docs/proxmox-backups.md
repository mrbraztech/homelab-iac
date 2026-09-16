# Proxmox CT Backups

## Scheduled backups

A monthly backup job runs on Proxmox (snapshot mode, zstd compression, keep-last=5). Backups are stored on the NFS export `nas-backup` (from NAS, mounted at `/mnt/pve/nas-backup`).

## On-demand backups

Before applying service version updates, always create an on-demand backup of the target CT:

```bash
ansible proxmox -m command -a "vzdump <vmid> --storage nas-backup --compress zstd --mode snapshot"
```

| CT | VMID |
|---|---|
| dns | 100 |
| proxy | 101 |
| tools | 102 |
| network | 103 |
| site | 104 |
| vpn | 105 |
| cloud | 106 |
| docserver | 107 |
| media | 108 |
| mail | 109 |
| ai-gateway | 110 |
| agent | 111 |
| vault | 112 |
| relay | 113 |

List existing backups:

```bash
ansible proxmox -m command -a "ls -lt /mnt/pve/nas-backup/dump/vzdump-lxc-<vmid>-*"
```

## Restore

Restore from Proxmox CLI (the CT must be stopped):

```bash
pct restore <vmid> <backup-file> --storage local-lvm
```

Or from the Proxmox UI: Datacenter → Backup → select backup → Restore.
