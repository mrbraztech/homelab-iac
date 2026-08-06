# AGENTS.md

Ansible + OpenTofu repo managing Debian homelab CTs on Proxmox.

Operational procedures live in `docs/` (`access.md`, `credentials.md`, `proxmox-rebuild.md`, `disaster-recovery.md`, `npm-proxy-hosts.md`, `nas-services.md`, `docker-daemon-config-procedure.md`).

## Validate before committing

```bash
yamllint .
ansible-lint .
```

Both must pass. `ansible-lint` runs at `profile: production` (stricter than default — see `.ansible-lint`). Pre-commit hooks (`trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `ansible-lint`, `yamllint`) run these automatically.

## Playbooks

All in `playbooks/`. Standard flow: `bootstrap` → `docker` → service roles. Exceptions (no `docker` role): `vpn.yml` (native Tailscale), `mail.yml` (bare-metal Postfix smarthost), `proxmox.yml` (netdata parent, no bootstrap).

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
| `nas.yml` | nas | PostgreSQL, Redis, OMV, MinIO, Netdata child |
| `tools.yml` | tools | CyberChef, pgAdmin |
| `ai-gateway.yml` | ai-gateway | AI gateway (9Router + Headroom) |
| `proxy.yml` | proxy | Nginx Proxy Manager, internal CA |
| `dns.yml` | dns | Pi-hole + Unbound |
| `network.yml` | network | Network controller (Omada) |
| `site.yml` | site | Frigate NVR |
| `vpn.yml` | vpn | Tailscale |
| `cloud.yml` | cloud | Nextcloud |
| `docserver.yml` | docserver | OnlyOffice |
| `media.yml` | media | Immich |
| `mail.yml` | mail | Postfix smarthost via SMTP2GO |
| `vault.yml` | vault | Vaultwarden (Bitwarden-compatible) |
| `agent.yml` | agent | Agent (Hermes AI agent, Docker container, AI agent with learning loop) |
| `proxmox.yml` | proxmox | Netdata parent, GPU passthrough for CT 104 (site/Frigate) |

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

State stored in MinIO S3 (`http://192.168.10.12:9000`, bucket `proxmox-ct-state`, key `homelab/terraform.tfstate`). One CT per file (`containers_<name>.tf`). `var.ssh_public_key` is hardcoded in `scripts/export-tf-vars.sh` — if your SSH key changes, update it there.

## Inventory

Groups in `inventories/lab/hosts.yml`. **All hosts connect as `root`**.

- **`lab`** — Debian CTs (`agent`, `ai-gateway`, `cloud`, `dns`, `docserver`, `mail`, `media`, `network`, `proxy`, `site`, `tools`, `vault`, `vpn`). Key `~/.ssh/id_ed25519_opencode`, always via `ProxyJump=containers` (`StrictHostKeyChecking=no` set in inventory — no known_hosts needed).
- **`infra`** — `nas` (key `~/.ssh/id_ed25519_opencode`), `proxmox` (key `~/.ssh/id_ed25519_proxmox_opencode`). Direct, no jump.

`proxmox.yml` targets the `proxmox` host in `infra` group, not `lab` — configure Netdata parent + GPU passthrough for Frigate.

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
- **Database**: never SQLite/file-based stores — all apps that need a database must use the central PostgreSQL on `nas` (`nas.yml`, second play creates users/databases)
- **Deployment**: new provisionings must prefer Docker containers over bare-metal installs by default — switch to bare-metal only when there is a clear, objective reason (e.g. no official image, host-level requirements). Always confirm exceptions with the user before implementing them.
- **New CTs**: every new CT requires two DNS records in `inventories/lab/host_vars/dns/custom_dns.yml` (under `pihole_custom_dns`):
  - a **short-name** record (e.g. `dns` → `192.168.10.2`) so `ssh root@dns` resolves directly to the CT, and
  - when the CT exports a web service, a `*.omni.corp` FQDN (e.g. `dns.omni.corp`) — but web FQDNs resolve to the NPM proxy (`192.168.10.3`), not the CT, and need a matching NPM reverse proxy host (see `docs/npm-proxy-hosts.md`); the `*.omni.corp` wildcard from the internal CA already covers the certificate.
  Note: `pihole_custom_dns` is applied by the `dns.yml` playbook via the Pi-hole v6 API.
- **Naming**: CT hostnames, inventory entries, DNS records and role names describe the **functionality**, never the tool/solution name (e.g. the Pi-hole CT is named `dns`, not `pihole`). When the functionality name is unclear, ask the user which name to use before provisioning.
- **Credentials**: whenever a new CT or service needs a user/password, **always ask the user which credentials to use before creating them** — never auto-generate or pick defaults without asking. Store them in `inventories/lab/host_vars/<host>/vault.yml` with a `vault_` prefix.
- **Roles**: one per service directory — no generic groupings like `roles/services/`
- **Role names**: `^[a-z][a-z0-9_]*$` — role dir, var prefixes, tasks/handlers must use the same alias.
- **YAML**: 2-space indent, LF, truthy `"true"`/`"false"`, max 120 chars
- **Task names**: descriptive, single responsibility
- **Shell**: only when no Ansible module exists; document why and ensure idempotency

## Infrastructure notes

- Proxmox backup job runs monthly (snapshot, zstd, keep-last=5) — stored on NAS via NFS export `nas-backup` mounted on Proxmox host.

## Gotchas

- `collections/ansible_collections/` is vendored locally — excluded from linters. Never edit.
- `lab` hosts are only reachable via `ProxyJump=containers` — connection fails if proxmox is down or unreachable.
- First provision: `bootstrap_ssh_password_authentication: true` in `inventories/lab/group_vars/all.yml` (password needed for first SSH key push). Role default is `false`.
- `check.yml` targets `all` (includes both `lab` and `infra` groups).
- `nas.yml` has a second play for PostgreSQL database setup (users, databases, extensions) — runs `community.postgresql.*` modules after roles complete.
- OpenTofu provider: `bpg/proxmox` version `~> 0.111` (check `terraform/providers.tf` before upgrading).

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
