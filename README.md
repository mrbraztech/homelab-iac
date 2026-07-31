# Homelab Infrastructure as Code

IaC repository for managing a Debian homelab on Proxmox VE using **OpenTofu** (infrastructure provisioning) and **Ansible** (configuration management).

---

## Prerequisites

### Controller machine

```bash
sudo apt install -y git openssh-client python3 python3-pip python3-venv

pipx ensurepath
pipx install ansible
pipx install ansible-lint
pipx install yamllint
pipx install opentofu
```

### Ansible collections

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

Required: `community.general`, `community.docker`, `community.postgresql`, `ansible.posix`.

### Vault password

Create `~/.vault_pass` with your Ansible Vault password:

```bash
echo "your-vault-password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

---

## Quick Start

### 1. Export Terraform variables

```bash
source scripts/export-tf-vars.sh
```

This reads secrets from `inventories/lab/host_vars/nas/vault.yml` (Ansible Vault encrypted) and exports:

- `TF_VAR_proxmox_*` — Proxmox API credentials
- `TF_VAR_minio_*` — MinIO/S3 backend credentials
- `TF_VAR_ssh_public_key` — SSH public key for CT initialization
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — S3 backend auth

### 2. Provision infrastructure (OpenTofu)

```bash
cd terraform

# Initialize (first time only)
tofu init

# Preview changes
tofu plan

# Apply changes
tofu apply

# Import existing resources
tofu import proxmox_virtual_environment_container.<name> pve/<vmid>
```

### 3. Configure hosts (Ansible)

```bash
# Dry run
ansible-playbook playbooks/<playbook>.yml --limit <host> --check --diff

# Apply
ansible-playbook playbooks/<playbook>.yml --limit <host>

# Full syntax check
ansible-playbook playbooks/<playbook>.yml --syntax-check
```

### 4. Validate

```bash
yamllint .
ansible-lint .
```

---

## Project Structure

```text
homelab-iac/
├── ansible.cfg                  # Ansible defaults
├── collections/
│   └── requirements.yml         # Ansible Galaxy collections
├── inventories/
│   └── lab/
│       ├── hosts.yml            # Host definitions
│       ├── group_vars/
│       │   └── all.yml          # Group variables
│       └── host_vars/
│           ├── dns/vault.yml
│           ├── tools/vault.yml
│           ├── nas/vault.yml
│           ├── vpn/vault.yml
│           ├── cloud/vault.yml
│           └── media/vault.yml
├── playbooks/
│   ├── nas.yml                  # NAS: bootstrap, docker, postgres, redis, omv
│   ├── tools.yml                # Tools: bootstrap, docker, cyberchef, pgadmin
│   ├── 9router.yml              # 9Router: bootstrap, docker, ninerouter
│   ├── proxy.yml                # Proxy: bootstrap, docker, nginx_proxy_manager
│   ├── dns.yml                  # DNS: bootstrap, docker, pihole
│   ├── omada.yml                # Omada: bootstrap, docker, omada
│   ├── site.yml                 # Site: bootstrap, docker, frigate
│   ├── vpn.yml                  # VPN: bootstrap, tailscale
│   ├── cloud.yml                # Cloud: bootstrap, docker, nextcloud, onlyoffice
│   ├── docserver.yml            # DocServer: bootstrap, docker, onlyoffice
│   ├── media.yml                # Media: bootstrap, docker, immich
│   ├── gateway.yml              # Gateway: bootstrap, wireguard exit-node
│   └── check.yml                # Diagnostics (all hosts)
├── roles/
│   ├── bootstrap/               # User, packages, locale, timezone, SSH
│   ├── docker/                  # Docker CE, daemon config, docker group
│   ├── postgres/                # PostgreSQL + pgvector
│   ├── redis/                   # Redis 7 Alpine
│   ├── omv/                     # OpenMediaVault + NFS/SMB
│   ├── cyberchef/               # CyberChef (Apache)
│   ├── pgadmin/                 # pgAdmin4
│   ├── ninerouter/              # 9Router + Headroom
│   ├── nginx_proxy_manager/     # Nginx Proxy Manager
│   ├── pihole/                  # Pi-hole DNS
│   ├── omada/                   # TP-Link Omada Controller
│   ├── frigate/                 # Frigate NVR
│   ├── tailscale/               # Tailscale (native)
│   ├── nextcloud/               # Nextcloud
│   ├── onlyoffice/              # OnlyOffice Document Server
│   ├── immich/                  # Immich photo/video
│   ├── gateway/                 # WireGuard Proton exit-node (NAT)
│   └── minio/                   # MinIO AIStor
├── terraform/
│   ├── backend.tf               # S3 backend (MinIO)
│   ├── providers.tf             # bpg/proxmox ~> 0.111
│   ├── variables.tf             # Proxmox + MinIO vars
│   ├── main.tf                  # Provider config
│   ├── storage.tf               # NFS storages
│   ├── backup.tf                # Monthly backup job
│   ├── containers_dns.tf        # CT dns (100)
│   ├── containers_proxy.tf      # CT proxy (101)
│   ├── containers_tools.tf      # CT tools (102)
│   ├── containers_omada.tf      # CT omada (103)
│   ├── containers_site.tf       # CT site (104)
│   ├── containers_vpn.tf        # CT vpn (105)
│   ├── containers_cloud.tf      # CT cloud (106)
│   ├── containers_docserver.tf  # CT docserver (107)
│   ├── containers_media.tf      # CT media (108)
│   ├── containers_gateway.tf    # CT gateway (109)
│   ├── containers_ai_rag.tf     # CT ai-rag (110)
│   ├── containers_ninerouter.tf # CT ninerouter (111)
│   └── outputs.tf               # All resource outputs
├── scripts/
│   └── export-tf-vars.sh        # Export TF + AWS env vars
└── docs/
    ├── access.md
    ├── credentials.md
    └── ...
```

---

## Infrastructure (OpenTofu)

### Backend

State stored in MinIO S3-compatible storage:

- **Endpoint**: `http://192.168.10.12:9000`
- **Bucket**: `proxmox-ct-state`
- **Key**: `homelab/terraform.tfstate`

### Managed resources

| Resource | VMID | IP | File |
|---|---|---|---|
| CT dns | 100 | 192.168.10.2 | `containers_dns.tf` |
| CT proxy | 101 | 192.168.10.3 | `containers_proxy.tf` |
| CT tools | 102 | 192.168.10.14 | `containers_tools.tf` |
| CT omada | 103 | 192.168.10.11 | `containers_omada.tf` |
| CT site | 104 | 192.168.10.13 | `containers_site.tf` |
| CT vpn | 105 | 192.168.10.4 | `containers_vpn.tf` |
| CT cloud | 106 | 192.168.10.15 | `containers_cloud.tf` |
| CT docserver | 107 | 192.168.10.16 | `containers_docserver.tf` |
| CT media | 108 | 192.168.10.17 | `containers_media.tf` |
| CT gateway | 109 | 192.168.10.5 | `containers_gateway.tf` |
| CT ai-rag | 110 | 192.168.10.18 | `containers_ai_rag.tf` |
| CT ninerouter | 111 | 192.168.10.19 | `containers_ninerouter.tf` |
| Storage nas-backup | — | — | `storage.tf` |
| Storage nas-nextcloud | — | — | `storage.tf` |
| Storage nas-media | — | — | `storage.tf` |
| Storage nas-catholic-library | — | — | `storage.tf` |
| Backup job monthly | — | — | `backup.tf` |

### SSH user

All CTs include a `user_account` block that injects the SSH public key from `var.ssh_public_key` during initialization. The `ansible` user is then created by the `bootstrap` role on first Ansible run.

### Common commands

```bash
source scripts/export-tf-vars.sh
cd terraform

# First time
tofu init

# Preview
tofu plan

# Apply
tofu apply

# Import existing resource
tofu import proxmox_virtual_environment_container.<name> pve/<vmid>

# Validate config
tofu validate

# Check current state
tofu state list
tofu state show proxmox_virtual_environment_container.<name>
```

---

## Configuration Management (Ansible)

### Inventory

All hosts in `inventories/lab/hosts.yml` under the `lab` group:

| Host | IP | Playbook | Services |
|---|---|---|---|
| nas | 192.168.10.12 | `nas.yml` | PostgreSQL, Redis, OMV, MinIO |
| tools | 192.168.10.14 | `tools.yml` | CyberChef, pgAdmin |
| 9router | 192.168.10.19 | `9router.yml` | 9Router + Headroom |
| proxy | 192.168.10.3 | `proxy.yml` | Nginx Proxy Manager |
| dns | 192.168.10.2 | `dns.yml` | Pi-hole |
| omada | 192.168.10.11 | `omada.yml` | Omada Controller |
| site | 192.168.10.13 | `site.yml` | Frigate NVR |
| vpn | 192.168.10.4 | `vpn.yml` | Tailscale |
| cloud | 192.168.10.15 | `cloud.yml` | Nextcloud + OnlyOffice |
| docserver | 192.168.10.16 | `docserver.yml` | OnlyOffice |
| media | 192.168.10.17 | `media.yml` | Immich |
| gateway | 192.168.10.5 | `gateway.yml` | WireGuard exit-node |
| ai-rag | 192.168.10.18 | — | (managed via Terraform only) |

### Run a playbook

```bash
# Dry run (check mode)
ansible-playbook playbooks/proxy.yml --limit proxy --check --diff

# Apply to specific host
ansible-playbook playbooks/proxy.yml --limit proxy

# Apply to all hosts in a playbook
ansible-playbook playbooks/nas.yml

# Syntax check only
ansible-playbook playbooks/proxy.yml --syntax-check

# Check connectivity to all hosts
ansible lab -m ping

# List inventory
ansible-inventory --graph
```

### Playbook flow

Each playbook follows: `bootstrap` → `docker` → `<service roles>`

```
bootstrap: user, packages, locale, timezone, SSH hardening, sudo
docker:    Docker CE from official repo, daemon config, docker group
```

### Vault secrets

Sensitive values stored in `inventories/lab/host_vars/<host>/vault.yml` (Ansible Vault encrypted).

| Host | Variables |
|---|---|
| nas | `vault_proxmox_user`, `vault_proxmox_password`, `vault_minio_access_key`, `vault_minio_secret_key`, `vault_postgres_password`, `vault_immich_password`, `vault_nextcloud_password` |
| tools | `vault_pgadmin_password` |
| dns | `vault_pihole_password` |
| vpn | `vault_tailscale_auth_key` |
| cloud | `vault_nextcloud_db_password`, `vault_nextcloud_admin_password` |
| docserver | `vault_onlyoffice_jwt_secret` |
| media | `vault_immich_db_password`, `vault_immich_jwt_secret` |

Encrypt a new vault file:

```bash
ansible-vault encrypt inventories/lab/host_vars/<host>/vault.yml
```

Edit an encrypted vault file:

```bash
ansible-vault edit inventories/lab/host_vars/<host>/vault.yml
```

View an encrypted vault file:

```bash
ansible-vault view inventories/lab/host_vars/<host>/vault.yml
```

---

## Validation

Always run before committing:

```bash
yamllint .
ansible-lint .
```

Both must pass. Pre-commit hooks run these automatically.

---

## Network Topology

```text
192.168.10.0/24
├── .1   — Gateway
├── .2   — DNS (Pi-hole)
├── .3   — Proxy (NPM)
├── .4   — VPN (Tailscale)
├── .5   — Gateway CT
├── .10  — Proxmox host
├── .11  — Omada Controller
├── .12  — NAS (PostgreSQL, Redis, OMV, MinIO)
├── .13  — Site (Frigate NVR)
├── .14  — Tools (CyberChef, pgAdmin)
├── .15  — Cloud (Nextcloud + OnlyOffice)
├── .16  — DocServer (OnlyOffice)
├── .17  — Media (Immich)
├── .18  — AI-RAG
└── .19  — 9Router
```

---

## Disaster Recovery

> **Documentos detalhados:**
> - [`docs/proxmox-rebuild.md`](docs/proxmox-rebuild.md) — Instalação do Proxmox VE do zero (hardware novo)
> - [`docs/disaster-recovery.md`](docs/disaster-recovery.md) — Procedimento completo de recuperação

1. **Provision infrastructure**: `source scripts/export-tf-vars.sh && cd terraform && tofu init && tofu apply`
2. **Configure hosts**: `ansible-playbook playbooks/proxmox.yml && ansible-playbook playbooks/<playbook>.yml --limit <host>` for each host
4. **Restore data**: from MinIO backups on `nas-backup` storage

---

## Conventions

- **Modules**: always FQCN (`ansible.builtin.copy`, not `copy`)
- **Variables**: prefix with role name (e.g. `docker_users`, `pihole_password`)
- **Roles**: one role per service, no generic directories
- **Role names**: `^[a-z][a-z0-9_]*$` — digit-prefixed services use aliases (e.g. `ninerouter` for `9router`)
- **YAML**: 2-space indent, LF endings, truthy `"true"` / `"false"`
- **Max line length**: 120 characters
- **Terraform files**: one CT per file (`containers_<name>.tf`)

---

## License

Personal use and learning purposes.
