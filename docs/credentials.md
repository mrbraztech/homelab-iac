# Credentials Inventory

## SSH Keys

### homelab_ed25519

Purpose:
Administrative access to the homelab.

Private key:
Stored in password manager.

Public key:
~/.ssh/homelab_ed25519.pub

Authorized on:
- pve01
- nextcloud
- immich
- monitoring

Rotation:
Yearly or immediately after suspected compromise.

Passphrase:
Stored only in password manager.

## Services

Service credentials live in the Ansible Vault (`inventories/lab/host_vars/<host>/vault.yml`):

| Service | Host | Variables |
|---|---|---|
| Postfix smarthost (SMTP2GO) | mail | `vault_postfix_smtp_username`, `vault_postfix_smtp_password`, `vault_postfix_sender`, `vault_postfix_root_alias` |
| Vaultwarden | vault | `vault_vaultwarden_admin_token`, `vault_vaultwarden_db_password` |