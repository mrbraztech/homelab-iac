# Task List: Rename CTs + remover ai-rag

## Fase 1 — Backup (Proxmox)
- [x] vzdump dos CTs 103, 111, 112 para nas-backup
- [x] Confirmar backups no storage (103=omada, 111=9router, 112=hermes)

## Fase 2 — Renome no repositório
- [x] Terraform: ai_rag removido; ninerouter→ai_gateway (110/.18); hermes→agent (111/.19); omada→network (103/.11); outputs atualizados
- [x] Inventory: ai-rag removido; hosts renomeados com novos IPs
- [x] Roles: ninerouter→ai_gateway; hermes→agent; omada→network (dirs, prefixes, vars, defaults, tasks, handlers, meta)
- [x] Playbooks: 9router.yml→ai-gateway.yml; hermes.yml→agent.yml; omada.yml→network.yml
- [x] host_vars: hermes/→agent/; vault_hermes_*→vault_agent_*
- [x] DNS custom_dns.yml: ai-rag removido; short-names + FQDNs renomeados
- [x] NPM defaults: domain_names + forward_host dos 3 proxy hosts
- [x] Docs: README, AGENTS.md, npm-proxy-hosts.md, proxmox-rebuild.md, disaster-recovery.md, credentials.md, backlog.md
- [x] Validações: yamllint, ansible-lint, syntax-check

## Fase 3 — Apply OpenTofu em fases
- [x] apply #1: remover ai-rag
- [x] apply #2: 9router→ai-gateway (110/.18)
- [x] apply #3: hermes→agent (111/.19)
- [x] apply #4: omada→network
- [x] tofu plan 0 changes

## Fase 4 — Restore de dados
- [x] pct restore 110/111/103 dos backups (dados + docker intactos)
- [x] pct set hostname/ip para alinhar com state + hosts internos corrigidos
- [x] tofu apply reconciliação; plan 0 changes

## Fase 5 — Configuração Ansible
- [x] dns.yml (DNS novos via Pi-hole API)
- [x] proxy.yml (proxy hosts novos + wildcard)
- [x] ai-gateway.yml, agent.yml, network.yml
- [x] check.yml corrigido (ansible_facts.* com inject_facts_as_vars=False); 14 hosts OK

## Fase 6 — Verificação e commit
- [x] ansible all -m ping (14 hosts SUCCESS); tofu plan 0 changes
- [x] Testar https://ai-gateway.omni.corp (307), agent.omni.corp (302), network.omni.corp (200)
- [x] DNS: short-names + FQDNs resolvendo
- [x] yamllint, ansible-lint, git diff, commit, push
- [x] Limpeza NPM: proxy hosts antigos removidos via API (router/hermes/omada.omni.corp)
