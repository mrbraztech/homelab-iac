# AGENTS.md

Ansible + OpenTofu repo managing Debian homelab CTs on Proxmox.

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
| `proxy.yml` | proxy | Nginx Proxy Manager |
| `dns.yml` | dns | Pi-hole |
| `omada.yml` | omada | Omada Controller |
| `site.yml` | site | Frigate NVR |
| `vpn.yml` | vpn | Tailscale |
| `cloud.yml` | cloud | Nextcloud + OnlyOffice |
| `docserver.yml` | docserver | OnlyOffice |
| `media.yml` | media | Immich |
| `gateway.yml` | gateway | (placeholder) |
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

State stored in MinIO S3 (`http://192.168.10.12:9000`, bucket `proxmox-ct-state`). One CT per file (`containers_<name>.tf`).

## Inventory

Two groups in `inventories/lab/hosts.yml`:

- **`lab`** — Debian CTs, user `ansible`, key `~/.ssh/homelab_ed25519`
- **`infra`** — `nas` (ansible), `proxmox` (root)

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
- `host_key_checking = True` — new hosts need SSH known_hosts first.
- SSH uses `~/.ssh/homelab_ed25519`, user `ansible` (except proxmox=root).
- First provision: `bootstrap_ssh_password_authentication: true` in group_vars. Default is `false`.
- `check.yml` targets `all` (not just `lab`).
- On first run after `tofu apply`, the CT exists but Ansible has not run `bootstrap` yet — the `ansible` user may not exist. If `tofu apply` created the CT with `user_account` (SSH key injection), the SSH key from `var.ssh_public_key` is used; the Ansible `ansible` user is created during the first `bootstrap` run.
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
