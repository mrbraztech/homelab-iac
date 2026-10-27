# Proxmox Storage Maintenance

This document describes the automated local-lvm maintenance and monitoring
managed by the `proxmox_storage` Ansible role on the Proxmox host.

## Current platform

- Proxmox VE 9.2.2, single node `pve`.
- `local-lvm` is an LVM-thin pool (`pve/data`) used by the LXC rootfs volumes.
- Netdata runs as the Proxmox parent and already collects the LVM thin-pool
  utilization charts.
- The existing monthly Proxmox backup job runs on the first day of each month
  at `00:00`, uses `nas-backup`, and keeps the last five backups.
- The host has a weekly host-level `fstrim.timer`, but it does not trim LXC
  rootfs filesystems.

## Automated LXC TRIM

The role installs:

```text
/usr/local/sbin/proxmox-lxc-fstrim
/etc/systemd/system/proxmox-lxc-fstrim.service
/etc/systemd/system/proxmox-lxc-fstrim.timer
```

The timer runs weekly:

```text
OnCalendar=Sun *-*-* 05:00:00
RandomizedDelaySec=5m
Persistent=false
```

The timer is not persistent: a missed weekly window is skipped instead of
running outside the maintenance window. The script:

- skips stopped containers;
- considers only running containers whose rootfs is on `local-lvm`;
- uses `pct fstrim <vmid> --ignore-mountpoints`, so NFS and bind mounts are
  never trimmed;
- runs containers sequentially, never concurrently;
- takes the `/run/lock/proxmox-lxc-fstrim.lock` lock to prevent overlapping
  executions;
- takes a non-blocking flock on `/run/vzdump.lock`; if a backup is running,
  the TRIM run is skipped. Proxmox `PVE::VZDump::getlock` holds the exclusive
  lock on `/var/run/vzdump.lock` for the entire backup task;
- logs the per-container result, the reclaimed thin-pool delta, the overall
  summary, and the final Data/Meta utilization to the systemd journal;
- continues with the remaining containers if one container fails, then exits
  non-zero to mark the run as failed;
- does not write to guest application data.

Logs:

```bash
journalctl -u proxmox-lxc-fstrim.service --since "30 days ago"
```

Manual run, only during the Sunday maintenance window if needed:

```bash
systemctl start proxmox-lxc-fstrim.service
```

## Thin-pool monitoring

Netdata's LVM collector provides these charts:

```text
lvm.lv_data_space_utilization
lvm.lv_metadata_space_utilization
```

The role deploys a Netdata health file at:

```text
/etc/netdata/health.d/pve-local-lvm.conf
```

It overrides the stock LVM utilization templates with these thresholds:

| Metric | Warning | Critical |
|---|---:|---:|
| Thin pool data | 80% | 90% |
| Thin pool metadata | 80% | 90% |

Additional full-pool alarms fire at 99.5% for data and metadata. The alarm
state engine provides transition-based delivery and the `delay` setting
reduces flapping.

The read-only thin-pool state is not exposed by Netdata's LVM collector, so a
small read-only check runs every five minutes:

```text
/usr/local/libexec/proxmox-storage/check-readonly
/etc/systemd/system/proxmox-storage-readonly.service
/etc/systemd/system/proxmox-storage-readonly.timer
```

It reads `lvs -o lv_attr` for `pve/data`, tracks the previous state in
`/var/lib/proxmox-storage/readonly.state`, and sends an alert only on a
transition to read-only and a recovery alert when it becomes writable again.

## Notification path

Storage alarms use the existing Netdata notification engine and the existing
mail relay CT at `192.168.10.5:25`. The role deploys a custom Netdata sender
that enriches every alert with:

- the local-lvm total/used/available capacity from `pvesm status`;
- the thin-pool data and metadata percentages from `lvs`.

The recipient is read from Proxmox `root@pam` unless
`proxmox_storage_alert_email` is set explicitly. The mail CT rewrites the
sender to the verified SMTP2GO sender.

Netdata alarm configuration:

```text
/etc/netdata/health.d/pve-local-lvm.conf
/etc/netdata/health_alarm_notify.conf
```

The second file is a managed user-level override; the stock Netdata
configuration is still loaded first.

## Backup coordination

The monthly backup schedule is unchanged:

```text
*-*-01 00:00
```

The weekly TRIM runs on Sunday at 05:00 with a five-minute randomized delay.
In addition to the time separation, the TRIM script takes a non-blocking lock
on `/run/vzdump.lock`, so it cannot run concurrently with a `vzdump` job.

The read-only check is read-only and may run during a backup.

## Deployment

The role is included in `playbooks/proxmox.yml` after the Netdata parent role.

Recommended procedure for future changes:

```bash
ansible-playbook playbooks/proxmox.yml --limit proxmox --check --diff
ansible-playbook playbooks/proxmox.yml --limit proxmox
systemctl list-timers proxmox-lxc-fstrim.timer proxmox-storage-readonly.timer
systemctl status proxmox-lxc-fstrim.timer proxmox-storage-readonly.timer --no-pager
journalctl -u proxmox-lxc-fstrim.service -u proxmox-storage-readonly.service --since "10 minutes ago"
```

Do not start `proxmox-lxc-fstrim.service` manually outside the Sunday
maintenance window. The read-only check is safe to run manually, but the timer
already runs it every five minutes.

Validate Netdata alarms:

```bash
curl -s "http://127.0.0.1:19999/api/v1/alarms?all" | grep -i lvm
```

The role is validated and deployed in production. Use `--check --diff` before
future changes; do not redeploy during the monthly backup window.

## Safe testing

The scripts support command overrides for testing:

- `PCT_BIN`, `LVS_BIN`, `DMSETUP_BIN`, `TIMEOUT_BIN`, `LOGGER_BIN`;
- `TRIM_LOCK_FILE`, `BACKUP_LOCK_FILE`, `STATE_FILE`, `LOCK_FILE`;
- `LOCAL_STORAGE`, `THIN_POOL`, `THIN_POOL_DM`;
- `PROXMOX_STORAGE_NOTIFY_CONFIG`, `NOTIFY_BIN`, `DRY_RUN=1`.

`DRY_RUN=1` makes the notification helper print the message instead of sending
it. This is used to test monitoring and TRIM orchestration without generating
real alerts.

A dry-run of the TRIM script can be performed by pointing `PCT_BIN` at a mock
that implements `list`, `config`, and `fstrim`, and pointing the lock files at
temporary paths.

## Declarative enable/disable

Set these variables to disable the corresponding feature without removing
unrelated configuration:

```yaml
proxmox_storage_trim_enabled: false
proxmox_storage_monitoring_enabled: false
```

With `proxmox_storage_trim_enabled: false`, the role stops and disables
`proxmox-lxc-fstrim.timer`.

With `proxmox_storage_monitoring_enabled: false`, the role:

- stops and disables `proxmox-storage-readonly.timer`;
- removes the managed Netdata thin-pool alarm file;
- removes the managed Netdata custom notification override;
- restarts Netdata so the stock alarm definitions are restored.

The scripts and unit files are left in place but have no active timer. Setting
the variables back to `true` deploys and re-enables the features again.

## Rollback

To stop and disable the automation manually:

```bash
systemctl disable --now proxmox-lxc-fstrim.timer proxmox-storage-readonly.timer
```

Then remove the role-owned files if desired:

```text
/usr/local/sbin/proxmox-lxc-fstrim
/usr/local/libexec/proxmox-storage/
/etc/proxmox-storage/
/var/lib/proxmox-storage/
/etc/systemd/system/proxmox-lxc-fstrim.*
/etc/systemd/system/proxmox-storage-readonly.*
/etc/netdata/health.d/pve-local-lvm.conf
/etc/netdata/health_alarm_notify.conf
```

Run `systemctl daemon-reload` and restart Netdata after removing the Netdata
files. Removing the user-level Netdata notification override restores the
stock notification behavior.

## Limitations

- The Netdata LVM collector exposes utilization but not the LVM read-only
  attribute or available bytes; those are handled by the small read-only check
  and the custom notification enrichment.
- Notification delivery depends on the mail CT at `192.168.10.5`.
- The custom Netdata notification file is managed by Ansible and should not be
  edited manually.
- The role does not resize the thin pool, delete volumes, or change backup
  retention.
