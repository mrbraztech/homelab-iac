---
name: proxmox
description: Design, provision, review, and troubleshoot Proxmox VE virtual machines, LXC containers, storage, networking, backups, templates, cloud-init, permissions, and Terraform/OpenTofu integration. Use for pct, qm, pvesm, bridges, VLANs, mounts, snapshots, and cluster-safe operations.
license: MIT
compatibility: OpenCode; Proxmox VE environment. Execution may require SSH and Proxmox API access. Optional: OpenTofu/Terraform, Ansible, jq.
metadata:
  category: infrastructure
  language: repository-english-conversation-pt-br
  version: "1.0.0"
---

# Proxmox VE Infrastructure

Use this skill for Proxmox VE planning, configuration, IaC, and troubleshooting.


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


## Environment discovery

Before proposing changes, identify:

- Proxmox VE version and node/cluster topology
- standalone versus clustered deployment
- storage definitions and content types
- VM and CT identifiers
- bridge, bond, VLAN, and firewall configuration
- backup targets and retention
- high availability expectations
- privileged versus unprivileged LXC requirements
- API token permissions
- provider and IaC conventions

Prefer read-only commands first:

```bash
pveversion -v
pvesh get /nodes
pvesm status
qm list
pct list
ip -br link
ip -br addr
```

Do not run cluster or storage mutation commands merely for discovery.

## VM workflow

For a VM, define:

- VMID and naming convention
- machine type, BIOS/UEFI, and guest agent
- CPU type and topology
- RAM and ballooning
- disk bus, cache, discard, and storage
- network bridge, VLAN, and firewall
- cloud-init or installation media
- startup order and protection
- backup policy

Prefer VirtIO devices where guest support exists. Do not enable host CPU passthrough without documenting migration implications.

## LXC workflow

For a container, define:

- privileged or unprivileged mode
- nesting/keyctl/fuse requirements
- UID/GID mapping implications
- root filesystem and mount points
- bridge, VLAN, IP, DNS, and firewall
- features required by Docker or system workloads
- backup behavior of bind mounts
- device passthrough requirements

Never recommend privileged mode as a generic fix. Explain the security tradeoff and use it only where the workload requires it.

### Mount points

Distinguish clearly:

- Proxmox-managed storage-backed mount points
- bind mounts from the host
- NFS/SMB mounts inside the guest
- device passthrough

Before changing a mount:

- verify source existence and permissions
- verify CT privilege mapping
- confirm backup inclusion/exclusion
- stop the guest when required
- document rollback

## Networking

Inspect:

```bash
cat /etc/network/interfaces
ip route
bridge link
bridge vlan show
```

Check for:

- VLAN-aware bridges
- duplicate addressing
- MTU mismatches
- firewall policy
- bridge physical interface
- DHCP/static route assumptions
- asymmetric routing

Do not overwrite `/etc/network/interfaces` wholesale. Preserve comments and cluster-specific configuration.

## Storage

Before creating or modifying storage, verify:

- backend type
- shared versus local
- supported content
- free capacity and thin provisioning
- discard/TRIM behavior
- snapshot support
- backup compatibility
- failure domain

Never remove a storage definition until all referenced volumes and backups have been identified.

## Backup and recovery

For critical guests:

- verify scheduled backups
- identify mode: snapshot, suspend, or stop
- confirm retention
- validate backup storage capacity
- test restore to an isolated VMID/CTID
- include external bind mounts separately

A successful backup job is not proof of a successful restore.

## IaC integration

When using Terraform/OpenTofu:

- use scoped API tokens
- avoid root credentials
- pin provider versions
- import existing resources before managing them
- reconcile provider defaults
- protect resources from accidental replacement
- keep guest configuration in Ansible/cloud-init where appropriate

Use Proxmox for lifecycle and hardware definition; use configuration management for OS and application state.

## Validation and safe commands

Read-only validation should precede mutation:

```bash
qm config <vmid>
pct config <ctid>
pvesm status
pvesh get /cluster/resources
```

For any command that stops, migrates, destroys, restores, resizes, snapshots, or changes cluster membership, present the exact command and request explicit approval.

## Expected output

For substantial changes, include target state, impact, commands or IaC files, rollback, and validation. Use [the output template](assets/output-template.md) and [the checklist](references/checklist.md).
