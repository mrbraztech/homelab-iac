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
- ai-rag
- nextcloud
- immich
- monitoring

Rotation:
Yearly or immediately after suspected compromise.

Passphrase:
Stored only in password manager.