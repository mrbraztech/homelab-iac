---
name: linux
description: Administer, automate, harden, and troubleshoot Linux systems, especially Ubuntu and Debian. Use for systemd, packages, networking, DNS, SSH, users, permissions, filesystems, mounts, logs, firewalls, kernel settings, services, performance, and boot issues.
license: MIT
compatibility: OpenCode; intended for systemd-based Ubuntu/Debian systems. Commands may require sudo. Optional: shellcheck, nftables, smartmontools, sysstat.
metadata:
  category: infrastructure
  language: repository-english-conversation-pt-br
  version: "1.0.0"
---

# Linux Administration

Use this skill for Linux system administration, automation, security, and troubleshooting.


## Communication and artifact language

- Communicate with the user in Brazilian Portuguese.
- Write every repository artifact in English.
- Keep code, comments, documentation, configuration, logs, errors, identifiers, test names, commit messages, and pull request text in English.
- Do not translate existing identifiers or external API fields unless the task explicitly requires it.

## Operating principles

1. Inspect the repository and current configuration before proposing changes.
2. Reuse existing conventions instead of introducing parallel patterns.
3. Prefer declarative, idempotent, reviewable, and reversible changes.
4. Separate facts observed in the repository from assumptions.
5. Do not expose secrets in output, logs, examples, commits, or generated files.
6. Run the narrowest useful validation before broad or destructive actions.
7. Never claim success without checking the relevant command output or resulting state.
8. Explain performed work and remaining risks in Brazilian Portuguese.

## Safety boundaries

- Do not apply destructive changes without explicit user approval.
- Do not delete infrastructure, state, data, backups, volumes, networks, users, or access rules merely to make validation pass.
- Do not rotate credentials, modify production access, run database restores, or change firewall policy without explicit approval.
- When a task can affect production, first produce a plan, expected impact, rollback procedure, and validation steps.


## Troubleshooting method

Use an evidence-driven sequence:

1. Define the expected and observed behavior.
2. Identify when the issue started and what changed.
3. Inspect status and logs.
4. Reproduce with the narrowest safe test.
5. Verify dependencies, permissions, networking, storage, and resource pressure.
6. Apply one controlled change at a time.
7. Validate the fix and persistence across restart where relevant.
8. Document rollback.

Do not start by reinstalling or deleting configuration.

## System discovery

Prefer read-only commands:

```bash
cat /etc/os-release
uname -a
hostnamectl
systemctl --failed
df -hT
lsblk -f
free -h
ip -br addr
ip route
```

Do not paste secret environment variables or private keys.

## systemd

Inspect:

```bash
systemctl status service --no-pager
journalctl -u service --since "1 hour ago" --no-pager
systemctl cat service
systemctl show service
```

For overrides:

```bash
sudo systemctl edit service
sudo systemctl daemon-reload
sudo systemctl restart service
```

Prefer drop-ins over editing packaged unit files. Validate service user, paths, environment, dependencies, restart behavior, and resource limits.

## Packages

- Use repository-supported package management.
- Run `apt update` before relying on package metadata.
- Avoid mixing distribution releases or untrusted repositories.
- Inspect pinning and source files before diagnosing dependency conflicts.
- Do not run broad removal or autoremove without reviewing the transaction.
- For manually installed binaries, prefer `/usr/local/bin` or user-local paths.

## Users, permissions, and SSH

- Apply least privilege.
- Prefer groups and ACLs over world-writable permissions.
- Do not use `chmod 777` as a fix.
- Validate SSH access in a second session before closing the current one.
- Back up SSH and sudoers files.
- Use `visudo` validation.
- Preserve an emergency access path during authentication changes.
- Never print private keys.

## Networking and DNS

Inspect layers separately:

```bash
ip link
ip addr
ip route
resolvectl status
ss -lntup
ping -c 3 <gateway>
curl -v <url>
```

Distinguish link, addressing, routing, DNS, firewall, proxy, and application failures.

For NetworkManager:

```bash
nmcli device status
nmcli connection show
```

For Netplan, inspect generated backend behavior before applying changes. Use `netplan try` where available for remote systems.

## Firewall

Determine whether the system uses nftables, iptables compatibility, UFW, firewalld, Docker-managed chains, or Proxmox firewall.

Do not flush firewall rules remotely. Add narrow rules and preserve established SSH access.

## Filesystems and mounts

Before modifying `/etc/fstab`:

- identify UUID and filesystem
- verify mount point
- test options manually
- create a backup
- use `mount -a` and inspect errors
- consider boot behavior with `nofail` and timeouts
- understand ownership and permission semantics

Never format a device based only on `/dev/sdX` naming. Confirm using UUID, model, size, and existing signatures.

## Storage health

Use appropriate tools:

```bash
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINTS,MODEL
df -hT
du -xhd1 /
smartctl -a /dev/device
```

Do not run filesystem repair on a mounted writable filesystem unless the tool explicitly supports it.

## Performance

Separate CPU, memory, I/O, network, and GPU bottlenecks:

```bash
uptime
top
vmstat 1
iostat -xz 1
pidstat 1
ss -s
```

Avoid tuning kernel parameters before measuring.

## Shell scripts

Generated scripts must:

- use `#!/usr/bin/env bash` when Bash features are required
- use `set -euo pipefail` when appropriate
- validate arguments
- quote variables
- handle temporary files with cleanup traps
- provide meaningful errors
- avoid destructive defaults
- pass ShellCheck where available

## Validation

After changes, verify:

- command exit status
- service status
- relevant logs
- network reachability
- persistence after reload/restart where required
- rollback readiness

## Expected output

For substantial changes, include observed evidence, diagnosis, exact changes, validation, and rollback. Use [the output template](assets/output-template.md) and [the checklist](references/checklist.md).
