# NAS Services (PostgreSQL + Redis + OMV + Print Server)

## Overview

The `nas.yml` playbook manages the NAS host:

**Play 1** — container lifecycle (roles):
- **`bootstrap`**: user, packages, locale, timezone, SSH, sudo
- **`docker`**: Docker CE
- **`postgres`**: PostgreSQL container
- **`redis`**: Redis container
- **`omv`**: OpenMediaVault shares
- **`print_server`**: CUPS + SpliX USB print server

**Play 2** — database setup (inline tasks):
- Create databases (`immich`, `nextcloud`)
- Install pgvector extension

## Host

| Key | Value |
|---|---|
| Hostname | nas |
| IP | 192.168.10.12 |
| OS | Debian 13 + OpenMediaVault |
| SSH user | ansible (after bootstrap) |
| Docker | Pre-installed |

## PostgreSQL Variables

| Variable | Default | Description |
|---|---|---|
| `postgres_image` | `pgvector/pgvector:pg17` | PostgreSQL image |
| `postgres_container_name` | `postgres` | Container name |
| `postgres_port` | `5432` | Host port |
| `postgres_volume_path` | `/opt/data/postgres` | Data volume path |
| `postgres_password` | vault | Via `vault_postgres_password` |
| `postgres_install_dir` | `/opt/postgres` | Compose file location |

## Redis Variables

| Variable | Default | Description |
|---|---|---|
| `redis_image` | `redis:7-alpine` | Redis image |
| `redis_container_name` | `redis` | Container name |
| `redis_port` | `6379` | Host port |
| `redis_install_dir` | `/opt/redis` | Compose file location |

## OMV Variables

| Variable | Default | Description |
|---|---|---|
| `omv_filesystem_uuid` | `94b09595-...` | Filesystem mount UUID |
| `omv_nfs_client` | `192.168.10.0/24` | NFS client network |
| `omv_nfs_shares` | `[]` | NFS shares to create |
| `omv_smb_shares` | `[]` | SMB shares to create |

## Print Server

The `print_server` role installs CUPS directly on the NAS and shares the Samsung
Xpress M2020W USB printer over IPP. It does not create a container and does not
modify OMV-managed configuration.

Key variables (see `roles/print_server/defaults/main.yml`):

| Variable | Default | Description |
|---|---|---|
| `print_server_printer_name` | `Samsung_M2020W` | CUPS queue name |
| `print_server_listen_address` | NAS IPv4 from Ansible facts | CUPS `Listen` address |
| `print_server_allowed_networks` | `192.168.10.0/24` | Networks allowed to print |
| `print_server_printer_uri` | empty | Optional explicit USB device URI |
| `print_server_splix_version` | `2.0.2` | Pinned SpliX release with M2020 support |

Printer URL:

```text
ipp://<nas-ip>:631/printers/<printer-name>
```

Full architecture, client setup, validation, and troubleshooting:
[`docs/print-server.md`](print-server.md).

## Secrets

Vault secrets stored in `host_vars/nas/vault.yml` (encrypted):

| Variable | Description |
|---|---|
| `vault_postgres_password` | PostgreSQL superuser password |
| `vault_immich_password` | `immich` database user password |
| `vault_nextcloud_password` | `nextcloud` database user password |

```bash
ansible-vault edit inventories/lab/host_vars/nas/vault.yml
```

## Deployment

**Setup NAS** (one command):

```bash
ansible-playbook playbooks/nas.yml
```

**Subsequent updates**:

```bash
ansible-playbook playbooks/nas.yml --check --diff
ansible-playbook playbooks/nas.yml
```

## Validation

```bash
ansible-playbook playbooks/nas.yml --syntax-check
yamllint .
ansible-lint .
```

## Troubleshooting

### PostgreSQL won't start

```bash
journalctl -xeu docker.service --no-pager -n 20
docker logs postgres
```

### Database connection refused

```bash
docker ps | grep postgres
ss -tlnp | grep 5432
docker exec postgres psql -U postgres -c "SELECT 1;"
```

### pgvector extension missing

```bash
docker exec postgres psql -U postgres -d immich -c "CREATE EXTENSION IF NOT EXISTS vector;"
```
