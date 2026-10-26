# Nginx Proxy Manager - Proxy Hosts Configuration

Current NPM proxy hosts configuration extracted from CT 101 (proxy).

---

## Proxy Hosts

| Domain | Backend IP | Port | SSL | Certificate | Notes |
|---|---|---|---|---|---|
| chef.omni.corp | 192.168.10.14 | 80 | Yes | Omni Homelab Wildcard | CyberChef (tools CT) |
| containers.omni.corp | 192.168.10.10 | 8006 | Yes | Omni Homelab Wildcard | Proxmox web UI |
| dns.omni.corp | 192.168.10.2 | 80 | Yes | Omni Homelab Wildcard | Pi-hole admin (dns CT) |
| nas.omni.corp | 192.168.10.12 | 80 | Yes | Omni Homelab Wildcard | OpenMediaVault (nas) |
| printers.omni.corp | 192.168.10.12 | 631 | Yes | Omni Homelab Wildcard | CUPS web UI + authenticated `/admin` (root/SystemGroup, HTTPS upstream with self-signed cert) |
| network.omni.corp | 192.168.10.11 | 8043 | Yes | Omni Homelab Wildcard | Network controller (network CT) |
| proxy.omni.corp | 192.168.10.3 | 81 | Yes | Omni Homelab Wildcard | NPM admin interface |
| site.omni.corp | 192.168.10.13 | 5000 | Yes | Omni Homelab Wildcard | Frigate NVR (site CT) |
| monitor.omni.corp | 192.168.10.10 | 19999 | Yes | Omni Homelab Wildcard | Netdata (Proxmox host) |
| cloud.omni.corp | 192.168.10.15 | 8080 | Yes | Omni Homelab Wildcard | Nextcloud (cloud CT) |
| docs.omni.corp | 192.168.10.16 | 8080 | Yes | Omni Homelab Wildcard | OnlyOffice (docserver CT) |
| media.omni.corp | 192.168.10.17 | 2283 | Yes | Omni Homelab Wildcard | Immich (media CT) |
| switch.omni.corp | 192.168.10.6 | 80 | Yes | Omni Homelab Wildcard | Network switch management |
| database.omni.corp | 192.168.10.14 | 8080 | Yes | Omni Homelab Wildcard | PostgreSQL (tools CT) |
| ai-gateway.omni.corp | 192.168.10.18 | 20128 | Yes | Omni Homelab Wildcard | AI gateway (ai-gateway CT) |
| agent.omni.corp | 192.168.10.19 | 9119 | Yes | Omni Homelab Wildcard | Agent dashboard (agent CT) |
| vault.omni.corp | 192.168.10.20 | 80 | Yes | Omni Homelab Wildcard | Vaultwarden (vault CT) |
| relay.hearthlane.omni.corp | 192.168.10.21 | 8080 | Yes | Omni Homelab Hearthlane Wildcard | Hearthlane Relay (relay CT) |
| relay-uat.hearthlane.omni.corp | 192.168.10.51 | 8080 | Yes | Omni Homelab Hearthlane Wildcard | Hearthlane Relay UAT |
| frigate.hearthlane.omni.corp | 192.168.10.13 | 5000 | Yes | Omni Homelab Hearthlane Wildcard | Frigate NVR (site CT) |

---

## SSL Certificates

Internal certificates are managed by the `internal_ca` role through the NPM API.
Two custom certificates are registered under the current root CA:

- `Omni Homelab Wildcard`: SAN `*.omni.corp`, `omni.corp`.
- `Omni Homelab Hearthlane Wildcard`: SAN `*.hearthlane.omni.corp`,
  `hearthlane.omni.corp`.

NPM assigned IDs 3 and 4 during the migration. These IDs are runtime values; the
role resolves certificates by exact `nice_name` and uses the ID returned by the NPM
API. Do not hardcode these IDs in automation.

For each certificate the role obtains the ID returned by NPM, uploads the leaf
certificate, private key and CA chain, and associates the certificate with the proxy
hosts listed under `internal_ca_domains[].npm_proxy_hosts` in
`inventories/lab/host_vars/proxy/vars.yml`.

The role never infers certificate IDs from `custom_ssl` directory indexes and never
selects certificates by partial name matching. Existing proxy host settings are
preserved because only `certificate_id` is sent in the NPM update request. New
proxy hosts covered by the wildcard must also be added to the corresponding
`npm_proxy_hosts` list.

The certificate is renewed automatically when it enters the renewal window
(`internal_ca_cert_renewal_threshold_days`, default 30 days) or when required
extensions are missing. Explicit operations are available with
`internal_ca_force_certificate_renewal` (re-sign with the existing key) and
`internal_ca_rotate_certificate_keys` (generate a new private key). Both options
default to `false`. Pass them as one-off extra variables
(e.g. `-e internal_ca_force_certificate_renewal=true`), not as permanent inventory
settings.

Apply certificate lifecycle changes with:

```bash
ansible-playbook playbooks/certificates.yml --limit proxy
```

Certificate files are backed up under `/opt/internal-ca/backups/` before renewal or
rotation. NPM certificate files are backed up under
`/data/custom_ssl/backups/npm-<certificate-id>/` before an upload. The legacy
`Omni Root CA` certificate is intentionally preserved during migration.

The `*.omni.corp` certificate does not cover multi-label names under
`hearthlane.omni.corp`. Those hosts use the separate
`Omni Homelab Hearthlane Wildcard` certificate instead.

Force-SSL (HTTP→HTTPS redirect) remains disabled on most proxy hosts so
container-to-container integrations (e.g. OnlyOffice→Nextcloud callbacks) work over
plain HTTP without certificate trust issues. The exceptions are:

- `media.omni.corp`, because Immich v3 keeps the session in a `Secure` cookie.
- `vault.omni.corp`, because Vaultwarden is only consumed over HTTPS.

HSTS is not enabled.

`printers.omni.corp` proxies to CUPS over HTTPS on port 631. Because CUPS uses a
self-signed certificate, this host's advanced configuration sets
`proxy_ssl_verify off` for the private NPM-to-CUPS hop. CUPS authentication remains
enabled and administrator access is limited to the NPM proxy address.

### Certificate verification

The `internal_ca` role verifies the actual HTTPS endpoints after deploying
certificates. For every managed proxy host it checks the TLS chain against the
current CA, validates the hostname, and compares the SHA-256 fingerprint served by
NPM with the fingerprint of the IaC certificate. Verification fails when NPM serves
a different certificate from the expected one.

Run the read-only verification independently with:

```bash
ansible-playbook playbooks/verify-certificates.yml --limit proxy
```

For lifecycle, rotation, migration and rollback procedures, see
[`certificate-management.md`](certificate-management.md).

---

## Configuration Files

NPM stores proxy host configs in `/opt/npm/data/nginx/proxy_host/*.conf`.

### Example: chef.omni.corp (HTTP only)

```nginx
server {
  set $forward_scheme http;
  set $server         "192.168.10.14";
  set $port           80;

  listen 80;
  listen [::]:80;

  server_name chef.omni.corp;
  http2 off;

  include conf.d/include/assets.conf;

  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection $http_connection;
  proxy_http_version 1.1;

  access_log /data/logs/proxy-host-1_access.log proxy;
  error_log /data/logs/proxy-host-1_error.log warn;

  location / {
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_http_version 1.1;
    include conf.d/include/proxy.conf;
  }

  include /data/nginx/custom/server_proxy[.]conf;
}
```

### Example: containers.omni.corp (HTTPS)

```nginx
server {
  set $forward_scheme https;
  set $server         "192.168.10.10";
  set $port           8006;

  listen 80;
  listen [::]:80;
  listen 443 ssl;
  listen [::]:443 ssl;

  server_name containers.omni.corp;
  http2 on;

  ssl_certificate /data/custom_ssl/npm-<certificate-id>/fullchain.pem;
  ssl_certificate_key /data/custom_ssl/npm-<certificate-id>/privkey.pem;

  include conf.d/include/assets.conf;

  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection $http_connection;
  proxy_http_version 1.1;

  access_log /data/logs/proxy-host-2_access.log proxy;
  error_log /data/logs/proxy-host-2_error.log warn;

  location / {
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_http_version 1.1;
    include conf.d/include/proxy.conf;
  }

  include /data/nginx/custom/server_proxy[.]conf;
}
```

---

## Management

NPM is managed via web UI at `http://192.168.10.3:81` (or `https://proxy.omni.corp`).

To reconfigure proxy hosts, use the NPM web interface. Configuration changes are persisted in SQLite database at `/opt/npm/data/database.sqlite` and generated nginx configs in `/opt/npm/data/nginx/proxy_host/`.
