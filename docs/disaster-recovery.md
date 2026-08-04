# Disaster Recovery

Procedimento para recuperar todo o homelab a partir do código.

## Pré-requisitos

- Máquina controller com Ansible + OpenTofu instalados
- Acesso ao repositório `homelab-iac`
- Acesso ao MinIO (estado do Terraform + backups)
- Chave SSH `~/.ssh/homelab_ed25519`
- Vault password em `~/.vault_pass`

```bash
sudo apt install -y git openssh-client python3 python3-pip python3-venv

pipx ensurepath
pipx install ansible
pipx install ansible-lint
pipx install yamllint
pipx install opentofu

ansible-galaxy collection install -r collections/requirements.yml
```

## 1. Proxmox VE — Instalação do zero

Se o Proxmox VE foi perdido, siga `docs/proxmox-rebuild.md` primeiro.

Se o Proxmox VE ainda existe, vá para o passo 2.

## 2. Estado do Terraform

O estado do Terraform fica no MinIO (`http://192.168.10.12:9000`, bucket `proxmox-ct-state`).

```bash
source scripts/export-tf-vars.sh
cd terraform
tofu init
tofu plan
```

Se `tofu plan` mostrar 0 mudanças, a infraestrutura está íntegra.

Se o estado do MinIO foi perdido, reimportar tudo:

```bash
tofu import proxmox_virtual_environment_container.dns pve/100
tofu import proxmox_virtual_environment_container.proxy pve/101
tofu import proxmox_virtual_environment_container.tools pve/102
tofu import proxmox_virtual_environment_container.network pve/103
tofu import proxmox_virtual_environment_container.site pve/104
tofu import proxmox_virtual_environment_container.vpn pve/105
tofu import proxmox_virtual_environment_container.cloud pve/106
tofu import proxmox_virtual_environment_container.docserver pve/107
tofu import proxmox_virtual_environment_container.media pve/108
tofu import proxmox_virtual_environment_container.gateway pve/109
tofu import proxmox_virtual_environment_container.ai_gateway pve/110
tofu import proxmox_virtual_environment_container.agent pve/111
tofu import proxmox_storage_nfs.nas_backup nas-backup
tofu import proxmox_storage_nfs.nas_nextcloud nas-nextcloud
tofu import proxmox_storage_nfs.nas_media nas-media
tofu import proxmox_storage_nfs.nas_catholic_library nas-catholic-library
tofu import proxmox_backup_job.monthly backup-cfcbe978-42c4
```

Após importar, verificar:

```bash
tofu plan  # deve mostrar 0 changes (exceto IPs de bridge Docker)
```

## 3. Configurar CTs com Ansible

```bash
ansible-playbook playbooks/proxmox.yml --limit proxmox
ansible-playbook playbooks/dns.yml --limit dns
ansible-playbook playbooks/proxy.yml --limit proxy
ansible-playbook playbooks/tools.yml --limit tools
ansible-playbook playbooks/network.yml --limit network
ansible-playbook playbooks/site.yml --limit site
ansible-playbook playbooks/vpn.yml --limit vpn
ansible-playbook playbooks/cloud.yml --limit cloud
ansible-playbook playbooks/docserver.yml --limit docserver
ansible-playbook playbooks/media.yml --limit media
ansible-playbook playbooks/gateway.yml --limit gateway
ansible-playbook playbooks/ai-gateway.yml --limit ai-gateway
ansible-playbook playbooks/agent.yml --limit agent
```

## 4. Restaurar dados de aplicação

Os backups ficam no MinIO (`nas-backup` storage, `/export/backup`).

### Backup dos CTs (Proxmox)

Os backups mensais (snapshot, zstd) estão em `nas-backup`. Para restaurar um CT:

```bash
# Pela UI do Proxmox: Datacenter -> Backup -> escolher backup -> Restore
# Ou via CLI:
pct restore <vmid> <backup-file> --storage local-lvm
```

### Dados das aplicações

Cada serviço tem seus dados em volumes Docker ou bind mounts no CT correspondente. Os backups de dados de aplicação (banco, arquivos) são responsabilidade de cada serviço e não são cobertos por este documento.

## 5. Verificação

```bash
# Ping em todos os hosts
ansible lab -m ping

# Playbook de diagnóstico
ansible-playbook playbooks/check.yml

# Terraform - confirmar 0 mudanças
cd terraform && tofu plan
```
