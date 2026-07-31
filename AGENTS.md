# AGENTS.md

Ansible + OpenTofu repo managing Debian homelab CTs on Proxmox.

Operational procedures live in `docs/` (`access.md`, `proxmox-rebuild.md`, `disaster-recovery.md`, `npm-proxy-hosts.md`, `nas-services.md`).

## Validate before committing

```bash
yamllint .
ansible-lint .
```

Both must pass. Pre-commit hooks (`trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `ansible-lint`, `yamllint`) run these automatically.

## Playbooks

All in `playbooks/`. Flow always: `bootstrap` → `docker` → service roles.

```bash
# All playbooks — limit to specific host
ansible-playbook playbooks/<name>.yml --limit <host>
ansible-playbook playbooks/<name>.yml --limit <host> --check --diff
ansible-playbook playbooks/<name>.yml --syntax-check

# Check all hosts
ansible-playbook playbooks/check.yml

# Quick connectivity
ansible lab -m ping
ansible-inventory --graph
```

| Playbook | Host | Services |
|---|---|---|
| `nas.yml` | nas | PostgreSQL, Redis, OMV, MinIO, Netdata |
| `tools.yml` | tools | CyberChef, pgAdmin |
| `9router.yml` | 9router | 9Router + Headroom |
| `proxy.yml` | proxy | Nginx Proxy Manager, internal CA |
| `dns.yml` | dns | Pi-hole + Unbound |
| `omada.yml` | omada | Omada Controller |
| `site.yml` | site | Frigate NVR |
| `vpn.yml` | vpn | Tailscale |
| `cloud.yml` | cloud | Nextcloud + OnlyOffice |
| `docserver.yml` | docserver | OnlyOffice |
| `media.yml` | media | Immich |
| `gateway.yml` | gateway | WireGuard Proton exit-node |
| `proxmox.yml` | proxmox | Netdata, GPU passthrough |

## Provisioning (OpenTofu)

```bash
source scripts/export-tf-vars.sh    # reads vault, exports TF_VAR_* + AWS_*
cd terraform
tofu init                            # first time only
tofu plan
tofu apply
tofu validate
tofu import proxmox_virtual_environment_container.<name> pve/<vmid>
```

State stored in MinIO S3 (`http://192.168.10.12:9000`, bucket `proxmox-ct-state`). One CT per file (`containers_<name>.tf`). `var.ssh_public_key` is hardcoded in `scripts/export-tf-vars.sh` — if your SSH key changes, update it there and the inventory keys below.

## Inventory

Groups in `inventories/lab/hosts.yml`. **All hosts connect as `root`** (the old `ansible` user is gone).

- **`lab`** — Debian CTs (`ai-rag`, `cloud`, `dns`, `docserver`, `gateway`, `media`, `9router`, `omada`, `proxy`, `site`, `tools`, `vpn`). Key `~/.ssh/id_ed25519_opencode`, always via `ProxyJump=proxmox` (`StrictHostKeyChecking=no` set in inventory — no known_hosts needed).
- **`infra`** — `nas` (key `~/.ssh/id_ed25519_opencode`), `proxmox` (key `~/.ssh/id_ed25519_proxmox_opencode`). Direct, no jump.

`ai-rag` is in the inventory but has **no playbook** (Terraform-managed only).

## Vault

`vault_password_file = ~/.vault_pass` (set in `ansible.cfg`). Encrypted vars per host in `inventories/lab/host_vars/<host>/vault.yml`.

```bash
ansible-vault view inventories/lab/host_vars/<host>/vault.yml
ansible-vault edit inventories/lab/host_vars/<host>/vault.yml
ansible-vault encrypt inventories/lab/host_vars/<host>/vault.yml
```

## Conventions

- **Modules**: always FQCN (`ansible.builtin.copy`, not `copy`)
- **Variables**: prefix with role name (e.g. `bootstrap_timezone`, `docker_users`)
- **Defaults**: `defaults/main.yml` for overridable; `vars/` only for fixed values
- **Roles**: one per service directory — no generic groupings like `roles/services/`
- **Role names**: `^[a-z][a-z0-9_]*$` — digit-prefixed services use aliases (e.g. `ninerouter` for `9router`). Role dir, var prefixes, tasks/handlers must use alias consistently.
- **YAML**: 2-space indent, LF, truthy `"true"`/`"false"`, max 120 chars
- **Task names**: descriptive, single responsibility
- **Shell**: only when no Ansible module exists; document why and ensure idempotency

## Infrastructure notes

- Proxmox backup job runs monthly (snapshot, zstd, keep-last=5) — stored on NAS via NFS export `nas-backup` mounted on Proxmox host.

## Gotchas

- `collections/ansible_collections/` is vendored locally — excluded from linters. Never edit.
- `lab` hosts are only reachable via `ProxyJump=proxmox` — connection fails if proxmox is down or unreachable.
- First provision: `bootstrap_ssh_password_authentication: true` in `inventories/lab/group_vars/all.yml` (password needed for first SSH key push). Default in the role is `false`.
- `check.yml` targets `all` (not just `lab`).
- Avoid committing `opencode.json` — it's in `.gitignore` (contains API keys).

## Definition of Done

1. Review existing implementation before editing
2. Make smallest necessary changes
3. `yamllint .` — pass
4. `ansible-lint .` — pass
5. `ansible-playbook playbooks/<affected>.yml --syntax-check` — pass
6. Review `git diff`
7. Fix all errors caused by changes
8. Report: changed files, commands, test results, known limitations

If a test cannot be executed, state which, why, and the exact command the developer must run.
