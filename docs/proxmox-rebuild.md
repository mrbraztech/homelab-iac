# Proxmox VE — Instalação do zero

Guia para instalar e configurar o Proxmox VE do zero em hardware novo.

## 1. Instalar Proxmox VE

1. Download ISO em <https://proxmox.com/downloads>
2. Gravar em USB (Rufus, `dd`, Ventoy)
3. Bootar e seguir o instalador:
   - **Filesystem**: ext4 com `max_zone` ou ZFS (se houver ECC)
   - **Hostname**: `pve.omni.corp`
   - **IP**: `192.168.10.10/24`
   - **Gateway**: `192.168.10.1`
   - **DNS**: `192.168.10.2` (Pi-hole)
   - **Root password**: guardado em Ansible Vault (`inventories/lab/host_vars/nas/vault.yml`)

## 2. Pós-instalação

```bash
# Desativar subscription nag
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-sub.list
apt update && apt full-upgrade -y

# Remover nag popup
sed -i "s/if (data.status !== 'Active')/if (false)/" /usr/share/pve-manager/js/pvemanagerlib.js

# Hosts file
echo "192.168.10.10 pve.omni.corp pve" >> /etc/hosts
echo "192.168.10.12 nas.omni.corp nas" >> /etc/hosts
```

## 3. Rede

```bash
# /etc/network/interfaces — bridge vmbr0 configurada no instalador
# Verificar:
cat /etc/network/interfaces
# Deve ter vmbr0 com IP 192.168.10.10/24, gateway 192.168.10.1
```

## 4. Storage NFS (NAS)

```bash
# Montagens NFS (o Terraform gerencia, mas precisa do path existir)
mkdir -p /mnt/pve/nas-backup
mkdir -p /mnt/pve/nas-nextcloud
mkdir -p /mnt/pve/nas-media
mkdir -p /mnt/pve/nas-catholic-library
```

O Terraform aplica os storages NFS via `storage.tf`.

## 5. Provisionar infraestrutura

```bash
# Na máquina controller
source scripts/export-tf-vars.sh
cd terraform
tofu init
tofu apply
```

Isso cria todos os 12 CTs (VMIDs 100-111), 4 NFS storages e 1 backup job.

## 6. Configurar CTs com Ansible

```bash
ansible-playbook playbooks/proxmox.yml --limit proxmox
ansible-playbook playbooks/dns.yml --limit dns
ansible-playbook playbooks/proxy.yml --limit proxy
ansible-playbook playbooks/tools.yml --limit tools
ansible-playbook playbooks/omada.yml --limit omada
ansible-playbook playbooks/site.yml --limit site
ansible-playbook playbooks/vpn.yml --limit vpn
ansible-playbook playbooks/cloud.yml --limit cloud
ansible-playbook playbooks/docserver.yml --limit docserver
ansible-playbook playbooks/media.yml --limit media
ansible-playbook playbooks/gateway.yml --limit gateway
ansible-playbook playbooks/9router.yml --limit 9router
```

## 7. Restaurar dados

Ver `docs/disaster-recovery.md`.
