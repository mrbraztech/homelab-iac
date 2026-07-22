# NAS Services (PostgreSQL + Redis)

## Overview

The `services` role manages PostgreSQL (with pgvector) and Redis on the NAS host via Docker Compose.

- **PostgreSQL**: `pgvector/pgvector:pg17` — databases `immich` and `nextcloud`
- **Redis**: `redis:7-alpine` — cache layer
- **Network**: Docker default bridge
- **Volume**: `/opt/data/postgres` → container `/var/lib/postgresql/data`

## Host

| Key | Value |
|---|---|
| Hostname | nas |
| IP | 192.168.10.12 |
| OS | Debian 13 + OpenMediaVault |
| SSH user | ansible (after bootstrap) |
| Docker | Pre-installed |

## Variables

Override in `host_vars/nas/` or `group_vars/`:

| Variable | Default | Description |
|---|---|---|
| `services_postgres_image` | `pgvector/pgvector:pg17` | PostgreSQL image |
| `services_postgres_container_name` | `postgres` | Container name |
| `services_postgres_port` | `5432` | Host port |
| `services_postgres_volume_path` | `/opt/data/postgres` | Data volume path |
| `services_postgres_password` | vault | Via `vault_postgres_password` |
| `services_postgres_databases` | `[immich, nextcloud]` | Databases to ensure |
| `services_redis_image` | `redis:7-alpine` | Redis image |
| `services_redis_container_name` | `redis` | Container name |
| `services_redis_port` | `6379` | Host port |
| `services_install_dir` | `/opt/services` | Compose file location |

## Secrets

`vault_postgres_password` is stored encrypted in `host_vars/nas/vault.yml`.

```bash
# Create/edit vault
ansible-vault edit inventories/lab/host_vars/nas/vault.yml

# Content
vault_postgres_password: "your-secure-password"
```

## Deployment

**For any new host**, run the bootstrap chain first to create the `ansible` user:

```bash
# 1. Bootstrap as root (creates ansible user, SSH key, sudo)
ansible-playbook playbooks/bootstrap.yml --limit <host>

# 2. Update inventory: change ansible_user from root to ansible
#    Edit inventories/lab/hosts.yml

# 3. Run base roles as ansible user
ansible-playbook playbooks/common.yml --limit <host>
ansible-playbook playbooks/security.yml --limit <host>
ansible-playbook playbooks/docker.yml --limit <host>
```

**Why bootstrap as root?** The `ansible` user doesn't exist yet. Bootstrap creates it with SSH key, sudo, and docker group. After that, all playbooks run as `ansible` (never root again).

**For NAS specifically**, after the base chain:

```bash
# If migrating from existing containers: run migration script FIRST
./scripts/migrate-postgres.sh

# If fresh install (no existing containers): run playbook directly
ansible-playbook playbooks/nas.yml
```

**Subsequent updates** (after bootstrap):

```bash
ansible-playbook playbooks/nas.yml --check --diff
ansible-playbook playbooks/nas.yml
```

**Important**: If containers `postgres` or `redis` already exist on the NAS, you MUST run the migration script first. Running `playbooks/nas.yml` directly will fail with a container name conflict.

## Migration

### Prerequisites

- SSH key `~/.ssh/homelab_ed25519` authorized for `root` on NAS
- Ansible and Docker installed on workstation
- Vault password available (`~/.vault_pass`)

### Procedure

1. **Backup existing data** (safety net):
   ```bash
   ssh root@192.168.10.12
   /opt/scripts/backup.sh  # or whatever the script is called
   ```

2. **Run migration script**:
   ```bash
   ./scripts/migrate-postgres.sh
   ```

   The script will:
   - Dump all databases from the old container (`pg_dumpall`)
   - Stop old containers
   - Provision new containers via Ansible
   - Restore dump to new container
   - Validate tables and extensions

3. **Verify**:
   ```bash
   docker exec postgres psql -U postgres -c "\l"
   docker exec postgres psql -U postgres -d immich -c "\dt"
   docker exec postgres psql -U postgres -d nextcloud -c "\dt"
   ```

### Dry Run

```bash
./scripts/migrate-postgres.sh --dry-run
```

### Rollback

If migration fails:

1. Stop new containers:
   ```bash
   docker stop postgres redis && docker rm postgres redis
   ```

2. Restore from backup in `/opt/scripts`:
   ```bash
   ssh root@192.168.10.12
   /opt/scripts/restore.sh  # or restore from latest backup
   ```

3. Re-provision old containers (if docker-compose.yml was backed up):
   ```bash
   cd /path/to/old/compose
   docker compose up -d
   ```

## Validation

```bash
# Syntax check
ansible-playbook playbooks/nas.yml --syntax-check

# Dry run
ansible-playbook playbooks/nas.yml --check --diff

# Linters
yamllint .
ansible-lint .
```

## Troubleshooting

### PostgreSQL won't start

```bash
journalctl -xeu docker.service --no-pager -n 20
docker logs postgres
```

Common causes:
- Volume permissions (data dir owned by UID 999)
- Port conflict (another process on 5432)
- Invalid environment variables

### Database connection refused

```bash
# Check container is running
docker ps | grep postgres

# Check port is listening
ss -tlnp | grep 5432

# Test connection
docker exec postgres psql -U postgres -c "SELECT 1;"
```

### pgvector extension missing

```bash
docker exec postgres psql -U postgres -d immich -c "CREATE EXTENSION IF NOT EXISTS vector;"
```
