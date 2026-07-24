# Backlog: Import completo do Proxmox para Terraform

## Objetivo
Gerenciar toda a infraestrutura do Proxmox via Terraform/OpenTofu, permitindo reconstrução total a partir do código.

## Estado atual
- **Terraform gerencia:** 3 CTs (tools 102, ninerouter 111, proxy 101)
- **Proxmox possui:** 12 CTs, 6 storages, 1 backup job

## Trabalho por tipo

### 1. Storages NFS (4 recursos)

| Storage | Server | Export | Conteúdo |
|---------|--------|--------|----------|
| nas-backup | 192.168.10.12 | /export/backup | backup |
| nas-nextcloud | 192.168.10.12 | /export/nextcloud | images |
| nas-media | 192.168.10.12 | /export/media | rootdir |
| nas-catholic-library | 192.168.10.12 | /export/catholic-library | rootdir |

**Arquivo:** `terraform/storage.tf`

### 2. Containers (9 recursos)

| CT | VMID | CPU | RAM | Disco | IP | Requisitos especiais |
|----|------|-----|-----|-------|-----|----------------------|
| dns | 100 | 1 | 128MB | 8GB | 192.168.10.2 | - |
| omada | 103 | 1 | 2500MB | 8GB | 192.168.10.11 | - |
| site | 104 | 4 | 8000MB | 32GB | 192.168.10.13 | GPU passthrough /dev/dri |
| vpn | 105 | 1 | 512MB | 4GB | 192.168.10.4 | TUN device /dev/net/tun |
| cloud | 106 | 2 | 4000MB | 32GB | 192.168.10.15 | NFS mount: nas-nextcloud |
| docserver | 107 | 2 | 4000MB | 24GB | 192.168.10.16 | - |
| media | 108 | 2 | 4000MB | 20GB | 192.168.10.17 | NFS mount: nas-media |
| gateway | 109 | 2 | 1024MB | 8GB | 192.168.10.5 | - |
| ai-rag | 110 | 4 | 8192MB | 40GB | 192.168.10.18 | NFS mount: nas-catholic-library |

**Arquivos:** Um por CT (`containers_dns.tf`, `containers_omada.tf`, etc.)

### 3. Backup Job (1 recurso)

| Propriedade | Valor |
|-------------|-------|
| Schedule | Monthly |
| Scope | All CTs |
| Compress | zstd |
| Mode | snapshot |
| Storage | nas-backup |
| Prune | keep-last=5 |

**Arquivo:** `terraform/backup.tf`

### 4. Outputs (atualização)

Adicionar outputs para todos os CTs e storages importados.

**Arquivo:** `terraform/outputs.tf`

---

## Sequência de commits

| # | Hash | Mensagem | Arquivo(s) |
|---|------|----------|------------|
| 1 | - | `backlog: add Proxmox import backlog` | `backlog.md` |
| 2 | - | `chore: remove roadmap from AGENTS.md` | `AGENTS.md` |
| 3 | - | `feat(terraform): add NFS storage backends` | `storage.tf` |
| 4 | - | `feat(terraform): add CT dns (100)` | `containers_dns.tf` |
| 5 | - | `feat(terraform): add CT omada (103)` | `containers_omada.tf` |
| 6 | - | `feat(terraform): add CT site (104)` | `containers_site.tf` |
| 7 | - | `feat(terraform): add CT vpn (105)` | `containers_vpn.tf` |
| 8 | - | `feat(terraform): add CT cloud (106)` | `containers_cloud.tf` |
| 9 | - | `feat(terraform): add CT docserver (107)` | `containers_docserver.tf` |
| 10 | - | `feat(terraform): add CT media (108)` | `containers_media.tf` |
| 11 | - | `feat(terraform): add CT gateway (109)` | `containers_gateway.tf` |
| 12 | - | `feat(terraform): add CT ai-rag (110)` | `containers_ai_rag.tf` |
| 13 | - | `feat(terraform): add monthly backup job` | `backup.tf` |
| 14 | - | `feat(terraform): add outputs for all resources` | `outputs.tf` |
| 15 | - | `push` | - |

## Validações

Após cada commit:
- `source scripts/export-tf-vars.sh && cd terraform && tofu plan` — 0 changes após imports
- `yamllint .` — deve passar
- `ansible-lint .` — deve passar

## Riscos conhecidos

1. **Device passthrough** (/dev/dri, /dev/net/tun) pode precisar de config manual
2. **Backup job** pode não ser suportado pelo provider BPG
3. **NFS mounts** requerem feature `mount=nfs` habilitada no CT
4. **CTs importados** não devem ter `user_account` (força replacement)
