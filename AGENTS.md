# AGENTS.md

Ansible IaC repo managing Debian homelab servers. Single inventory (`lab`), four roles (`bootstrap`, `common`, `security`, `docker`), playbooks orchestrate roles only.

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
# Syntax check
ansible-playbook playbooks/bootstrap.yml --syntax-check

# Dry run
ansible-playbook playbooks/bootstrap.yml --check --diff

# Apply (order: bootstrap -> common -> security -> docker)
ansible-playbook playbooks/bootstrap.yml
ansible-playbook playbooks/common.yml
ansible-playbook playbooks/security.yml
ansible-playbook playbooks/docker.yml
```

---

## Install collections

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

Required collections: `community.general`, `ansible.posix`.

---

## Structure

- `inventories/lab/hosts.yml` — hosts and connection settings
- `inventories/lab/group_vars/all.yml` — group/host variable overrides
- `roles/bootstrap/` — admin user, SSH keys, sudo, minimum bootstrap packages
- `roles/common/` — full packages, locale, timezone
- `roles/security/` — SSH hardening, auth policies, firewall (placeholder)
- `roles/docker/` — Docker CE from official repo, daemon config, docker group
- `ansible.cfg` — defaults to `inventories/lab/hosts.yml`, enables `become=True` and SSH pipelining

Role dependency chain: `bootstrap` -> `common` -> `security` -> `docker`.

---

## Conventions

- **Modules**: always FQCN (`ansible.builtin.copy`, not `copy`)
- **Variables**: prefix with role name, e.g. `common_timezone`, `bootstrap_admin_user`, `security_ssh_port`, `docker_users`
- **Variable defaults**: use `defaults/main.yml` for overridable values; `vars/` only for fixed values
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
- On first provision, `security_ssh_password_authentication: true` is set in group_vars to allow initial access. Default in role is `false`.
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

### Migration strategy

The goal is to migrate all services from manual Proxmox CT management into Ansible-managed infrastructure, enabling full disaster recovery via playbooks. Migration will be incremental — one service at a time — while keeping the existing homelab operational.

### Roadmap

1. ✅ Base roles: `bootstrap` → `common` → `security` → `docker`
2. ⬜ Docker daemon configuration (daemon.json, storage driver, logging)
3. ⬜ Migrate Pi-hole to Ansible-managed Docker container
4. ⬜ Migrate Nginx Proxy Manager to Ansible-managed Docker container
5. ⬜ Migrate Tailscale to Ansible-managed Docker container
6. ⬜ Migrate Omada Controller to Ansible-managed Docker container
7. ⬜ Migrate Frigate to Ansible-managed Docker container
8. ⬜ Migrate Nextcloud + OnlyOffice to Ansible-managed Docker container
9. ⬜ Migrate Immich to Ansible-managed Docker container
10. ⬜ NAS role (OpenMediaVault / NFS/SMB mounts)
11. ⬜ Proxmox role (VM/CT management via API) — optional


## Docker phase 1 — daemon configuration & storage driver  
```bash
# After creating role roles/docker/, set these defaults for proper deployment:
touch roles/docker/templates/daemon.json        # config (storage, network drivers)
mkdir -p docs/docker                      # procedure to deploy containers + recovery notes

# Run docker playbook in order with bootstrap->common->security first!  
ansible-playbook playbooks/bootstrap.yml   ansible-playbook playbooks/common.yml  \
    ansible-playbook playbooks/security.yml ansible-playbook playbooks/docker.yml --check
```  

See `docs/` for architecture decisions, storage planning (overlay2/zfs), and migration strategy notes.
