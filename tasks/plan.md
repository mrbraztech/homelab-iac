# Implementation Plan: Rename CTs (nomenclatura por funcionalidade) + remover ai-rag

## Overview

Refatorar a nomenclatura da infraestrutura para descrever **funcionalidade**, nunca a solução/ferramenta. Renomear 3 CTs (hostname real no Proxmox + todo o repo), remover o CT `ai-rag` por completo, e reutilizar os slots de VMID/IP liberados. Dados preservados via backup/restore Proxmox.

## Decisões do usuário

- Nomes novos: `9router` → **ai-gateway**, `hermes` → **agent**, `omada` → **network**.
- Remover `ai-rag` completamente (CT + arquivos do projeto).
- IPs: manter todos os atuais; só mover `9router` .19 → .18 (slot do ai-rag) e `hermes` .20 → .19 (slot do 9router).
- VMIDs: reutilizar slots liberados → ai-gateway 110 (ex-111), agent 111 (ex-112); network mantém 103.
- Dados: backup/restore via Proxmox (vzdump → nas-backup → pct restore).
- Storage NFS `nas-catholic-library`: **manter** (mesmo sem consumidor).
- Container names do Docker internos (`9router`, `hermes`, `omada`) e paths on-disk (`/opt/9router`, `/opt/omada`, `/opt/hermes`): **manter**.
- Proxy hosts antigos do NPM (`router.omni.corp`, `hermes.omni.corp`, `omada.omni.corp`): deixar para limpeza manual.

## Tabela alvo

| VMID | Hostname | IP | Recurso tf | Playbook | Role |
|---|---|---|---|---|---|
| 100 | dns | .2 | dns | dns.yml | pihole |
| 101 | proxy | .3 | proxy | proxy.yml | nginx_proxy_manager |
| 102 | tools | .14 | tools | tools.yml | cyberchef+pgadmin |
| 103 | **network** | .11 | network | network.yml | network |
| 104 | site | .13 | site | site.yml | frigate |
| 105 | vpn | .4 | vpn | vpn.yml | tailscale |
| 106 | cloud | .15 | cloud | cloud.yml | nextcloud |
| 107 | docserver | .16 | docserver | docserver.yml | onlyoffice |
| 108 | media | .17 | media | media.yml | immich |
| 109 | gateway | .5 | gateway | gateway.yml | gateway |
| 110 | **ai-gateway** | .18 | ai_gateway | ai-gateway.yml | ai_gateway |
| 111 | **agent** | .19 | agent | agent.yml | agent |
| — | ~~ai-rag~~ | ~~.18~~ | ~~ai_rag~~ | — | — |

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `initialization.hostname` e `vm_id` são ForceNew → recria os CTs | Alto (dados) | `vzdump` de 103/111/112 em `nas-backup` ANTES de aplicar; `pct restore` após recriar |
| Colisão de VMID durante o apply (110 usado pelo ai-rag; 111 usado pelo 9router) | Alto | Aplicar em fases sequenciais: remover ai-rag → renomear 9router → renomear hermes |
| Backup restaura hostname/IP antigos dentro do rootfs | Médio | `pct set <vmid> --hostname/--net0` para alinhar com o state do tofu após restore |
| `pct restore` sobrescreve atributos (cpu/memória) do CT recém-criado | Médio | Rodar `tofu apply` após restores para reconciliar a config |
| FQDN/proxy hosts novos dependem do wildcard `*.omni.corp` | Baixo | Cert wildcard já cobre; deploy_to_npm cria hosts ausentes automaticamente |
| GPU passthrough do site referencia VMID 104 | Baixo | Site permanece 104 — nenhuma alteração em `playbooks/proxmox.yml` |

## Fases

### Fase 1 — Backup (em Proxmox, via API/CLI)
- [ ] `vzdump` de CTs 103 (omada), 111 (9router), 112 (hermes) → storage `nas-backup`, modo snapshot, zstd.
- [ ] Confirmar que os 3 arquivos `.tar.zst` existem no storage.

### Fase 2 — Renome no repositório (sem apply)
- [ ] Terraform: renomear resources, hostnames, IPs, VMIDs; deletar ai-rag; atualizar outputs.
- [ ] Inventory: remover ai-rag; renomear hosts 9router/hermes/omada; atualizar IPs.
- [ ] Roles: renomear dirs + prefixes (`ninerouter_`→`ai_gateway_`, `hermes_`→`agent_`, `omada_`→`network_`); manter paths/container names on-disk.
- [ ] Playbooks: renomear arquivos e `hosts:`/roles.
- [ ] host_vars: `hermes/` → `agent/`; renomear vars de vault (`vault_hermes_*` → `vault_agent_*`).
- [ ] DNS (`custom_dns.yml`): remover ai-rag; renomear short-names + FQDNs.
- [ ] NPM (`nginx_proxy_manager/defaults/main.yml`): renomear domain_names + forward_host.
- [ ] Docs (README, AGENTS.md, npm-proxy-hosts, proxmox-rebuild, disaster-recovery, credentials, backlog).
- [ ] `yamllint .`, `ansible-lint .`, syntax-check de todos os playbooks alterados.

### Fase 3 — Apply em fases (OpenTofu)
- [ ] `tofu state mv` (quando aplicável) + `tofu apply` #1: remover ai-rag → destroi 110.
- [ ] `tofu apply` #2: renomear 9router→ai-gateway (vm_id 111→110, ip .19→.18) → destroi 111, cria 110.
- [ ] `tofu apply` #3: renomear hermes→agent (vm_id 112→111, ip .20→.19) → destroi 112, cria 111.
- [ ] `tofu apply` #4: renomear omada→network (hostname; vm_id/IP inalterados) → substitui 103.
- [ ] `tofu plan` → 0 changes esperado.

### Fase 4 — Restore de dados
- [ ] `pct restore 110 <backup-9router>` ; `pct restore 111 <backup-hermes>` ; `pct restore 103 <backup-omada>`.
- [ ] `pct set` hostname/ip em cada um para bater com o state (`ai-gateway`/.18, `agent`/.19, `network`/.11).
- [ ] `tofu apply` para reconciliar config; `tofu plan` 0 changes.

### Fase 5 — Configuração (Ansible)
- [ ] `dns.yml --limit dns` (aplica short-names + FQDNs novos via API Pi-hole).
- [ ] `proxy.yml --limit proxy` (internal_ca cria os proxy hosts novos; associa wildcard).
- [ ] Playbooks dos CTs renomeados (`ai-gateway.yml`, `agent.yml`, `network.yml`).
- [ ] `check.yml` para validar todos os hosts.

### Fase 6 — Verificação e commit
- [ ] `ansible lab -m ping`, `tofu plan` 0 changes.
- [ ] Testar endpoints: `https://ai-gateway.omni.corp`, `https://agent.omni.corp` (com auth), `https://network.omni.corp`.
- [ ] Revisar `git diff`, commit + push.
- [ ] Limpeza manual (fora do repo): remover proxy hosts antigos do NPM.

## Observação de dados preservados

- `9router`: dados em `/opt/9router/data` (bind mount do compose).
- `hermes`: dados em `/opt/hermes/data` (bind mount `./data` → `/opt/data`).
- `omada`: dados em `/opt/omada/data` e `/opt/omada/log`.

Como paths e container names são mantidos, após `pct restore` as roles reutilizam os dados existentes sem recriar do zero.
