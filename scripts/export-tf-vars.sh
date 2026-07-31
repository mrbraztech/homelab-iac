#!/usr/bin/env bash
set -euo pipefail

VAULT_FILE="inventories/lab/host_vars/nas/vault.yml"

export TF_VAR_proxmox_endpoint="https://192.168.10.10:8006"
export TF_VAR_proxmox_user="$(ansible-vault view "$VAULT_FILE" | grep 'vault_proxmox_user:' | awk '{print $2}' | tr -d '"')"
export TF_VAR_proxmox_password="$(ansible-vault view "$VAULT_FILE" | grep 'vault_proxmox_password:' | awk '{print $2}' | tr -d '"')"
export TF_VAR_minio_access_key="$(ansible-vault view "$VAULT_FILE" | grep 'vault_minio_access_key:' | awk '{print $2}' | tr -d '"')"
export TF_VAR_minio_secret_key="$(ansible-vault view "$VAULT_FILE" | grep 'vault_minio_secret_key:' | awk '{print $2}' | tr -d '"')"
export TF_VAR_ssh_public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0LYBC7E//h9w1bhm6zSyJKkbfsor/frcQO8yHlHMcp opencode@homelab"

# S3 backend (MinIO) credentials
export AWS_ACCESS_KEY_ID="${TF_VAR_minio_access_key}"
export AWS_SECRET_ACCESS_KEY="${TF_VAR_minio_secret_key}"

echo "Variáveis TF exportadas com sucesso."
echo ""
echo "Container AIStor: aistor-server"
echo "Console: http://192.168.10.12:9001"
echo "API: http://192.168.10.12:9000"
