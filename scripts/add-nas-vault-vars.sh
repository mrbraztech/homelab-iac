#!/usr/bin/env bash
# Script para adicionar variáveis ao vault do NAS
# Uso: bash scripts/add-nas-vault-vars.sh
set -euo pipefail

VAULT_FILE="inventories/lab/host_vars/nas/vault.yml"

echo "Adicionando variáveis ao vault do NAS..."
echo ""
echo "Variáveis a serem adicionadas:"
echo "  - vault_minio_access_key"
echo "  - vault_minio_secret_key"
echo "  - vault_minio_license_key"
echo "  - vault_proxmox_user"
echo "  - vault_proxmox_password"
echo ""
echo "Execute o seguinte comando e adicione as variáveis:"
echo ""
echo "  ansible-vault edit $VAULT_FILE"
echo ""
echo "Exemplo de formato a adicionar ao final do arquivo:"
echo ""
cat <<'EOF'
vault_minio_access_key: SUA_CHAVE_AQUI
vault_minio_secret_key: SUA_SENHA_AQUI
vault_minio_license_key: |
  CONTEUDO_DO_ARQUIVO_DE_LICENCA_AQUI
vault_proxmox_user: root@pam
vault_proxmox_password: SUA_SENHA_PROXMOX_AQUI
EOF
echo ""
echo "Após adicionar, salve e saia do editor."
echo "O arquivo será re-criptografado automaticamente."
