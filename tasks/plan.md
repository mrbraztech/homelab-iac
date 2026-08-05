# Implementation Plan: Remover CT gateway → Postfix (SMTP2GO) + Vaultwarden

## Overview

1. **Remover o CT `gateway`** (VMID 109, 192.168.10.5, WireGuard Proton exit-node + microsocks SOCKS5) — nenhum outro recurso do repo depende dos serviços dele (confirmado por busca de `1080`/`microsocks`/`wireguard`).
2. **Reaproveitar o slot do gateway** para um CT `mail` (mesmo VMID **109**, mesmo IP **192.168.10.5**) rodando **Postfix como smarthost SMTP2GO** para o lab inteiro (bare-metal, como `vpn.yml`/`gateway.yml` — exceção documentada, MTA de sistema não roda em container).
3. **Adicionar Vaultwarden** (alternativa leve ao servidor Bitwarden oficial) em um **novo CT `vault`** (VMID **112**, IP **192.168.10.20**), Docker, banco no PostgreSQL central do `nas`, web em `https://vault.omni.corp` via NPM.

## Decisões do usuário

- Hostname do CT reaproveitado: **`mail`** (funcionalidade, não a ferramenta).
- Postfix = **smarthost do lab inteiro** (mynetworks = loopback + LAN).
- Bitwarden: **Vaultwarden** (Rust, 1 container) em vez do servidor oficial (.NET + MSSQL).
- Vaultwarden em **novo CT** (VMID 112, IP .20).
- Domínio web: **`vault.omni.corp`** (cert wildcard `*.omni.corp` já cobre).

## Tabela alvo

| VMID | Hostname | IP | Recurso tf | Playbook | Role |
|---|---|---|---|---|---|
| 100 | dns | .2 | dns | dns.yml | pihole |
| 101 | proxy | .3 | proxy | proxy.yml | nginx_proxy_manager |
| 102 | tools | .14 | tools | tools.yml | cyberchef+pgadmin |
| 103 | network | .11 | network | network.yml | network |
| 104 | site | .13 | site | site.yml | frigate |
| 105 | vpn | .4 | vpn | vpn.yml | tailscale |
| 106 | cloud | .15 | cloud | cloud.yml | nextcloud |
| 107 | docserver | .16 | docserver | docserver.yml | onlyoffice |
| 108 | media | .17 | media | media.yml | immich |
| 109 | **mail** | **.5** | **mail** | **mail.yml** | **postfix** |
| 110 | ai-gateway | .18 | ai_gateway | ai-gateway.yml | ai_gateway |
| 111 | agent | .19 | agent | agent.yml | agent |
| 112 | **vault** | **.20** | **vaultwarden** | **vault.yml** | **vaultwarden** |

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Terraform vai **destruir e recriar** o CT 109 (mudança de `hostname` + nome do resource) | Médio | Gateway não guarda dados (só wg+microsocks). Garantir destroy-before-create no apply (recriar com mesmo VMID/IP) |
| SMTP2GO rejeita remetente não verificado (535/550) | Médio | Alias/`smtp_generic_maps` forçam um *verified sender*; conferir "Verified Senders" na conta SMTP2GO |
| Vaultwarden precisa de `ADMIN_TOKEN` e DB no `nas` | Médio | Credenciais pedidas ao usuário e salvas no vault; role `nas.yml` cria user/db `vaultwarden` |
| NPM proxy host é gerenciado via UI (config via API está `false`) | Médio | Passo manual documentado + atualizar `docs/npm-proxy-hosts.md` |
| Ponto único de e-mail: se `mail` cair, lab inteiro perde e-mail | Baixo | Sem dependência atual; monitorar serviço no `check.yml` |

## Fases

### Fase 0 — Entradas do usuário (pré-requisito)
- [ ] Credenciais SMTP2GO: **SMTP user** (username + password, painel "Sending > SMTP Users") + **verified sender** (ex.: `alerts@omni.corp`).
- [ ] Credenciais Vaultwarden: `ADMIN_TOKEN` (senha do painel admin), e-mail/senha da conta inicial, senha do banco `vaultwarden` no Postgres.
- [ ] Confirmar que o SOCKS5 do gateway (192.168.10.5:1080) não é mais usado por ninguém.

### Fase 1 — Remover gateway / criar CT mail (Terraform + repo)
- [ ] Terraform: deletar `containers_gateway.tf`; criar `containers_mail.tf` (vm_id 109, hostname `mail`, ip .5, specs iguais).
- [ ] `outputs.tf`: `gateway_id`/`gateway_ipv4` → `mail_id`/`mail_ipv4`.
- [ ] Inventory: `gateway` → `mail` (hosts.yml).
- [ ] Remover role `gateway/`, playbook `gateway.yml`, `host_vars/gateway/`.
- [ ] `tofu plan` → confirmar destroy do 109 + create do 109 (mesmo VMID/IP).

### Fase 2 — Role `postfix` (CT mail)
- [ ] Role `postfix`: `defaults/main.yml` (relayhost `[mail.smtp2go.com]:587`, mynetworks loopback+192.168.10.0/24, STARTTLS `encrypt`, creds via vault).
- [ ] Tasks: apt install `postfix` + `libsasl2-modules`; `sasl_passwd` (0600) + `postmap`; `smtp_generic_maps` (root→verified sender); aliases root→destino; service started/enabled.
- [ ] `playbooks/mail.yml` (bootstrap + postfix — sem role docker).
- [ ] `host_vars/mail/vault.yml`: `vault_postfix_smtp_username`, `vault_postfix_smtp_password`, `vault_postfix_sender`, `vault_postfix_admin_email`.
- [ ] DNS: short-name `gateway` → `mail` em 192.168.10.5.
- [ ] Verificação: `postconf`, `sendmail` teste, `mailq` vazio, entrega visível nos logs SMTP2GO.

### Fase 3 — Role `vaultwarden` (CT vault)
- [ ] Terraform: `containers_vaultwarden.tf` (vm_id 112, hostname `vault`, ip .20, 2 cores / 2 GB / 20 GB) + outputs `vault_id`/`vault_ipv4`.
- [ ] Inventory: host `vault` (192.168.10.20).
- [ ] Role `vaultwarden`: docker-compose com imagem `vaultwarden/server` (porta 80), env `DATABASE_URL=postgresql://vaultwarden:…@192.168.10.12:5432/vaultwarden`, `DOMAIN=https://vault.omni.corp`, `ADMIN_TOKEN`, `SIGNUPS_ALLOWED=false` após setup; volume `/data` (attachments/config/keys).
- [ ] `playbooks/vault.yml` (bootstrap + docker + vaultwarden).
- [ ] `nas.yml` (2º play): user + db `vaultwarden` em `postgres_setup_users`/`postgres_setup_databases`.
- [ ] `host_vars/vault/vault.yml`: `vault_vaultwarden_admin_token`, `vault_vaultwarden_db_password` etc.
- [ ] DNS: `vault.omni.corp` → proxy (.3); short-name `vault` → .20.
- [ ] NPM (manual via UI): proxy host `vault.omni.corp` → 192.168.10.20:80, SSL com cert wildcard; atualizar `docs/npm-proxy-hosts.md`.

### Fase 4 — Consumidores do smarthost (opcional)
- [ ] Ajustar apps que enviam e-mail (netdata, frigate, immich…) para `192.168.10.5:25` sem auth (mynetworks LAN) ou com credenciais se preferir auth.

### Fase 5 — Documentação e validação
- [ ] README (tabelas de CTs/playbooks/roles), AGENTS.md (tabela de playbooks + exceção `mail.yml`), `docs/npm-proxy-hosts.md`, `docs/access.md`/`credentials.md` (novos serviços).
- [ ] `yamllint .`, `ansible-lint .`, `--syntax-check` dos playbooks alterados, `tofu validate` + `tofu plan`.
- [ ] Apply em sequência: tofu → dns.yml → mail.yml → nas.yml → vault.yml → proxy manual.
- [ ] Testes: `ssh root@mail`, `echo teste | sendmail -f <sender> <dest>`; `https://vault.omni.corp` acessível e cria cofre; `tofu plan` 0 changes.
- [ ] Revisar `git diff`, commit + push.

## Pendências / Open questions

- Fornecer SMTP2GO SMTP user + verified sender (usuário).
- Definir remetente padrão (`alerts@omni.corp`?) e destino dos e-mails de sistema (root alias).
- Gerar `ADMIN_TOKEN` do Vaultwarden e senha do DB (usuário decide; convenção exige perguntar).
- Confirmar apps que passarão a usar o smarthost (Fase 4).
