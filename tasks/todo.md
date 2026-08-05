# Task List: Remover gateway → Postfix (SMTP2GO) + Vaultwarden

## Fase 0 — Entradas do usuário
- [x] SMTP2GO: SMTP user (username/password) + verified sender
- [x] Vaultwarden: ADMIN_TOKEN, conta inicial, senha DB
- [x] Confirmar que SOCKS5 .5:1080 não é mais usado

## Fase 1 — Gateway → CT mail (Terraform + repo)
- [x] containers_gateway.tf → containers_mail.tf (vm_id 109, hostname mail, ip .5)
- [x] outputs.tf: gateway_id/ipv4 → mail_id/ipv4
- [x] Inventory: gateway → mail
- [x] Remover role gateway/, playbook gateway.yml, host_vars/gateway/
- [x] tofu plan (feito via `state mv` → rename in-place, sem destroy/create)

## Fase 2 — Role postfix (CT mail)
- [x] Role postfix: defaults (relayhost [mail.smtp2go.com]:587, STARTTLS, mynetworks loopback+LAN, creds vault)
- [x] Tasks: postfix + libsasl2-modules, sasl_passwd+postmap, smtp_generic_maps, aliases, service
- [x] playbooks/mail.yml (bootstrap + postfix + limpeza legados gateway)
- [x] host_vars/mail/vault.yml (smtp user/pass, sender, admin email)
- [x] DNS: short-name gateway → mail
- [x] Verificação: sendmail teste (250 OK via smtp2go), mailq vazio

## Fase 3 — Role vaultwarden (CT vault)
- [x] containers_vaultwarden.tf (vm_id 112, hostname vault, ip .20)
- [x] outputs.tf: vault_id/vault_ipv4
- [x] Inventory: host vault (.20)
- [x] Role vaultwarden: docker-compose (imagem vaultwarden/server, porta 80, DATABASE_URL postgres nas, DOMAIN, ADMIN_TOKEN)
- [x] playbooks/vault.yml (bootstrap + docker + vaultwarden)
- [x] nas.yml: user + db vaultwarden
- [x] host_vars/vault/vault.yml
- [x] DNS: vault.omni.corp → .3; short-name vault → .20
- [x] NPM: proxy host vault.omni.corp → .20:80 (criado via proxy.yml/internal_ca, cert wildcard) + docs/npm-proxy-hosts.md

## Fase 4 — Consumidores do smarthost (opcional)
- [ ] Apps de e-mail apontando para 192.168.10.5:25

## Fase 5 — Documentação e validação
- [x] README, AGENTS.md, docs (npm-proxy-hosts, access, credentials)
- [x] yamllint, ansible-lint, syntax-check, tofu validate/plan
- [x] Apply: tofu → dns.yml → mail.yml → nas.yml → vault.yml
- [x] Testes: sendmail (250 OK), check.yml (14 CTs + nas ok), tofu plan 0 changes
- [x] NPM: proxy host vault.omni.corp → validado https://vault.omni.corp (200, cert *.omni.corp)
- [x] SIGNUPS_ALLOWED=true (mantido por decisão do usuário; 1ª conta criada)
- [ ] git diff, commit, push
