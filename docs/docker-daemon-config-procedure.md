# Docker Daemon Configuration

## How it works

The `docker` role deploys `/etc/docker/daemon.json` via the `docker_daemon_json` variable. The template (`roles/docker/templates/daemon.json.j2`) renders the variable as sorted JSON. Docker restarts only when the file changes.

Default config:

```json
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": { "max-size": "10m", "max-file": "3" },
    "live-restore": true,
    "iptables": false,
    "ipv6": false,
    "log-level": "warn"
}
```

To customize, override `docker_daemon_json` in `group_vars/all.yml` or `host_vars/<host>.yml`.

## Storage driver

**overlay2** is the default and works well on Debian with ext4/xfs.

Use **ZFS** only when the Proxmox storage backend is already ZFS and you have a dedicated zvol for Docker:

```json
{ "storage-driver": "zfs" }
```

Do not mix overlay2 on ZFS backing without understanding the performance implications.

## Recovery

If Docker fails to start after a `daemon.json` change:

```bash
# Check the error
journalctl -xeu docker.service --no-pager -n 20

# Remove the broken config
sudo rm /etc/docker/daemon.json
sudo systemctl start docker

# Restore from a known-good config, then re-apply the playbook
```

Common causes:
- Invalid JSON syntax
- Unknown directives (e.g. `oom-score-adjust` is not valid in daemon.json)
- Wrong log level (`warn` not `warning`)

## Storage considerations

For large media workloads (Frigate, Immich), the default `/var/lib/docker/` on the root partition may run out of space or hit I/O limits. Plan ahead:

- Move Docker data to a separate disk or partition via LVM or bind mount before deploying containers.
- Monitor disk usage with `docker system df`.
