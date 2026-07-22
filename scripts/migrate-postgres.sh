#!/bin/bash
set -euo pipefail

# PostgreSQL Migration Script
# Migrates data from existing Docker Compose PostgreSQL to Ansible-managed instance
#
# Usage: ./scripts/migrate-postgres.sh [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DUMP_FILE="/tmp/migration-dump-$(date +%Y%m%d-%H%M%S).sql"
OLD_CONTAINER="postgres"
NEW_CONTAINER="postgres"
REDIS_CONTAINER="redis"
PLAYBOOK="playbooks/nas.yml"
LIMIT="nas"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    warn "Dry run mode — no changes will be made"
fi

# --- Pre-flight checks ---
log "Checking prerequisites..."

if ! command -v docker &>/dev/null; then
    error "Docker not found. Install Docker first."
    exit 1
fi

if ! command -v ansible-playbook &>/dev/null; then
    error "ansible-playbook not found. Install Ansible first."
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${OLD_CONTAINER}$"; then
    error "Container '${OLD_CONTAINER}' is not running."
    exit 1
fi

log "Pre-flight checks passed."

# --- Step 1: Dump from old container ---
log "Step 1: Dumping database from '${OLD_CONTAINER}'..."
if [[ "$DRY_RUN" == false ]]; then
    docker exec "${OLD_CONTAINER}" pg_dumpall -U postgres > "${DUMP_FILE}"
    DUMP_SIZE=$(du -h "${DUMP_FILE}" | cut -f1)
    log "Dump created: ${DUMP_FILE} (${DUMP_SIZE})"
else
    log "[dry-run] Would dump to ${DUMP_FILE}"
fi

# --- Step 2: Stop old containers ---
log "Step 2: Stopping old containers..."
if [[ "$DRY_RUN" == false ]]; then
    docker stop "${OLD_CONTAINER}" "${REDIS_CONTAINER}" 2>/dev/null || true
    docker rm "${OLD_CONTAINER}" "${REDIS_CONTAINER}" 2>/dev/null || true
    log "Old containers stopped and removed."
else
    log "[dry-run] Would stop ${OLD_CONTAINER} and ${REDIS_CONTAINER}"
fi

# --- Step 3: Provision new containers via Ansible ---
log "Step 3: Provisioning new containers via Ansible..."
if [[ "$DRY_RUN" == false ]]; then
    cd "${PROJECT_DIR}"
    ansible-playbook "${PLAYBOOK}" --limit "${LIMIT}"
    log "Ansible playbook completed."
else
    log "[dry-run] Would run: ansible-playbook ${PLAYBOOK} --limit ${LIMIT}"
fi

# --- Step 4: Wait for PostgreSQL ---
log "Step 4: Waiting for PostgreSQL to be ready..."
if [[ "$DRY_RUN" == false ]]; then
    RETRIES=30
    until docker exec "${NEW_CONTAINER}" pg_isready -U postgres &>/dev/null; do
        RETRIES=$((RETRIES - 1))
        if [[ $RETRIES -le 0 ]]; then
            error "PostgreSQL did not become ready in time."
            exit 1
        fi
        sleep 2
    done
    log "PostgreSQL is ready."
else
    log "[dry-run] Would wait for PostgreSQL"
fi

# --- Step 5: Restore dump ---
log "Step 5: Restoring dump to new container..."
if [[ "$DRY_RUN" == false ]]; then
    docker exec -i "${NEW_CONTAINER}" psql -U postgres < "${DUMP_FILE}"
    log "Restore completed."
else
    log "[dry-run] Would restore ${DUMP_FILE}"
fi

# --- Step 6: Validate ---
log "Step 6: Validating migration..."
if [[ "$DRY_RUN" == false ]]; then
    echo ""
    echo "=== Databases ==="
    docker exec "${NEW_CONTAINER}" psql -U postgres -c "\l" | grep -E "immich|nextcloud"

    echo ""
    echo "=== Tables in immich ==="
    docker exec "${NEW_CONTAINER}" psql -U postgres -d immich -c "\dt" 2>/dev/null || warn "No tables in immich"

    echo ""
    echo "=== Tables in nextcloud ==="
    docker exec "${NEW_CONTAINER}" psql -U postgres -d nextcloud -c "\dt" 2>/dev/null || warn "No tables in nextcloud"

    echo ""
    echo "=== pgvector extension ==="
    docker exec "${NEW_CONTAINER}" psql -U postgres -d immich -c "SELECT * FROM pg_extension WHERE extname = 'vector';" 2>/dev/null || warn "pgvector not found in immich"
else
    log "[dry-run] Would validate migration"
fi

# --- Step 7: Cleanup ---
log "Step 7: Cleanup..."
if [[ "$DRY_RUN" == false ]]; then
    read -rp "Delete dump file ${DUMP_FILE}? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "${DUMP_FILE}"
        log "Dump file deleted."
    else
        log "Dump file kept at ${DUMP_FILE}"
    fi
else
    log "[dry-run] Would offer to delete dump"
fi

echo ""
log "Migration completed successfully!"
log "PostgreSQL: localhost:${OLD_CONTAINER} -> port 5432"
log "Redis: localhost:${REDIS_CONTAINER} -> port 6379"
