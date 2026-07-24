# AGENTS.md

Ansible IaC repo managing Debian homelab servers. Single inventory (`lab`), base roles (`bootstrap`, `docker`), service roles (`postgres`, `redis`, `omv`, `cyberchef`, `pgadmin`, `ninerouter`), playbooks orchestrate roles only.

---

## Validate before committing

```bash
yamllint .
ansible-lint
```

Both must pass. Pre-commit hooks run these automatically.

---

## Run playbooks

```bash
# NAS (bootstrap + docker + postgres + redis + omv + DB setup)
ansible-playbook playbooks/nas.yml --limit <host>
ansible-playbook playbooks/nas.yml --limit <host> --check --diff

# Tools (bootstrap + docker + cyberchef + pgadmin)
ansible-playbook playbooks/tools.yml --limit <host>

# 9Router (bootstrap + docker + 9router + headroom)
ansible-playbook playbooks/9router.yml --limit <host>

# Proxy (bootstrap + docker + nginx-proxy-manager)
ansible-playbook playbooks/proxy.yml --limit <host>

# Check all hosts
ansible-playbook playbooks/check.yml
```

---

## Install collections

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

Required collections: `community.general`, `community.docker`, `community.postgresql`, `ansible.posix`.

---

## Structure

- `inventories/lab/hosts.yml` — hosts and connection settings
- `inventories/lab/group_vars/all.yml` — group/host variable overrides
- `roles/bootstrap/` — user, packages, locale, timezone, SSH hardening, sudo, AllowGroups
- `roles/docker/` — Docker CE from official repo, daemon config, docker group
- `roles/postgres/` — PostgreSQL with pgvector, container lifecycle
- `roles/redis/` — Redis 7 Alpine, container lifecycle
- `roles/omv/` — OpenMediaVault install, NFS/SMB share management
- `roles/cyberchef/` — CyberChef container
- `roles/pgadmin/` — pgAdmin container
- `roles/ninerouter/` — 9Router AI proxy + Headroom sidecar
- `roles/nginx_proxy_manager/` — Nginx Proxy Manager reverse proxy
- `playbooks/nas.yml` — NAS host setup + PostgreSQL DBs/extensions
- `playbooks/tools.yml` — Tools host setup
- `playbooks/9router.yml` — 9Router host setup
- `playbooks/proxy.yml` — Proxy host setup
- `playbooks/check.yml` — Host diagnostics
- `ansible.cfg` — defaults to `inventories/lab/hosts.yml`, enables `become=True` and SSH pipelining

Role dependency chain: `bootstrap` -> `docker`.

---

## Conventions

- **Modules**: always FQCN (`ansible.builtin.copy`, not `copy`)
- **Variables**: prefix with role name, e.g. `bootstrap_timezone`, `bootstrap_admin_user`, `docker_users`
- **Variable defaults**: use `defaults/main.yml` for overridable values; `vars/` only for fixed values
- **Roles**: one role per service, never generic directories grouping multiple services (e.g. `roles/services/` is forbidden; use `roles/postgres/`, `roles/redis/`, etc.)
- **Role names**: must match `^[a-z][a-z0-9_]*$` (ansible-lint rule). If a service name starts with a digit (e.g. `9router`), use a descriptive alias without the digit (e.g. `ninerouter`). The role directory, variable prefixes, and task/handler names must all use this alias consistently. Display names in templates and descriptions can use the original service name.
- **YAML**: 2-space indent, LF endings, truthy values are `"true"` / `"false"` (not `yes`/`no`)
- **Max line length**: 120 characters
- **Task names**: descriptive, single responsibility
- **Shell commands**: only when no Ansible module exists; document why and ensure idempotency

---

## Secrets

Never commit credentials, SSH keys, vault passwords, or `.env` files. The `.gitignore` blocks common secret patterns. Prefer Ansible Vault or environment variables for secrets.

---

## Gotchas

- `collections/ansible_collections/` is vendored locally — excluded from both linters. Never edit files there.
- `host_key_checking = True` in ansible.cfg — new hosts need SSH known_hosts first.
- SSH connection uses `~/.ssh/homelab_ed25519` with user `ansible` (defined in inventory).
- On first provision, `bootstrap_ssh_password_authentication: true` is set in group_vars to allow initial access. Default in role is `false`.
- The `check.yml` playbook targets `all` hosts (not just `lab`) for host info gathering.
- When you need to search docs, use Context7 mcp.

---

## Homelab context

### Hardware

| Server | OS | Role |
|---|---|---|
| Proxmox | Proxmox VE | VM/CT host |
| NAS | Debian + OpenMediaVault | Storage |

### Current services (Proxmox CTs)

| Service | Description |
|---|---|
| Pi-hole | DNS server |
| Nginx Proxy Manager | Reverse proxy |
| Tailscale | VPN mesh network |
| Omada Controller | TP-Link network management |
| Frigate | NVR / AI object detection |
| Nextcloud + OnlyOffice | File sync + collaborative editing |
| Immich | Photo/video backup and management |
| 9Router | AI proxy + token saver (Claude/GPT/Gemini) |

### Migration strategy

The goal is to migrate all services from manual Proxmox CT management into Terraform-managed infrastructure, enabling full disaster recovery via code. Migration will be incremental — one service at a time — while keeping the existing homelab operational.


## Docker role

The `docker` role installs Docker CE from the official repo, deploys `daemon.json` (via `docker_daemon_json` variable), and manages the docker group. It depends on `bootstrap` via `meta/main.yml`.

To customize daemon config, override `docker_daemon_json` in `group_vars` or `host_vars`. The template uses `to_nice_json` — keys are sorted alphabetically on the host.

```bash
# Validate
yamllint .
ansible-lint .
ansible-playbook playbooks/nas.yml --syntax-check

# Dry run
ansible-playbook playbooks/nas.yml --check --diff

# Apply
ansible-playbook playbooks/nas.yml
```

See `docs/` for architecture decisions, storage planning (overlay2/zfs), and migration notes.

## Definition of Done

A task is not complete until all applicable steps have been performed:

1. Review the existing implementation before editing.
2. Create a concise implementation plan.
3. Make the smallest necessary changes.
4. Run `yamllint .`.
5. Run `ansible-lint .`.
6. Run the relevant playbook with `--syntax-check`.
7. Review `git diff`.
8. Fix all errors caused by the changes.
9. Report:
   - changed files;
   - commands executed;
   - test results;
   - known limitations.

Never claim completion when tests were not executed.

If a test cannot be executed, explicitly state:
- which test was skipped;
- why it was skipped;
- the exact command the developer must run.
