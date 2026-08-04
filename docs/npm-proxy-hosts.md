# Nginx Proxy Manager - Proxy Hosts Configuration

Current NPM proxy hosts configuration extracted from CT 101 (proxy).

---

## Proxy Hosts

| Domain | Backend IP | Port | SSL | Notes |
|---|---|---|---|---|
| chef.omni.corp | 192.168.10.14 | 80 | No | CyberChef (tools CT) |
| containers.omni.corp | 192.168.10.10 | 8006 | Yes | Proxmox web UI |
| dns.omni.corp | 192.168.10.2 | 80 | No | Pi-hole admin (dns CT) |
| nas.omni.corp | 192.168.10.12 | 80 | Yes | OpenMediaVault (nas) |
| network.omni.corp | 192.168.10.11 | 8043 | Yes | Network controller (network CT) |
| proxy.omni.corp | 192.168.10.3 | 81 | Yes | NPM admin interface |
| site.omni.corp | 192.168.10.13 | 5000 | No | Frigate NVR (site CT) |
| monitor.omni.corp | 192.168.10.10 | 19999 | No | Netdata (Proxmox host) |
| cloud.omni.corp | 192.168.10.15 | 8080 | Yes | Nextcloud (cloud CT) |
| docs.omni.corp | 192.168.10.16 | 8080 | Yes | OnlyOffice (docserver CT) |
| media.omni.corp | 192.168.10.17 | 2283 | Yes | Immich (media CT) |
| switch.omni.corp | 192.168.10.6 | 80 | Yes | Network switch management |
| database.omni.corp | 192.168.10.14 | 8080 | Yes | PostgreSQL (tools CT) |
| ai-gateway.omni.corp | 192.168.10.18 | 20128 | Yes | AI gateway (ai-gateway CT) |
| agent.omni.corp | 192.168.10.19 | 9119 | Yes | Agent dashboard (agent CT) |
| network.omni.corp | 192.168.10.11 | 8043 | Yes | Network controller (network CT) |

---

## SSL Certificates

SSL-enabled hosts (containers, nas, network, proxy, cloud, docs, media, switch, database, ai-gateway, agent) use custom certificates stored in `/data/custom_ssl/npm-*/`. Force-SSL (HTTP→HTTPS redirect) is **disabled** on all proxy hosts so container-to-container integrations (e.g. OnlyOffice→Nextcloud callbacks) work over plain HTTP without certificate trust issues.

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

  ssl_certificate /data/custom_ssl/npm-2/fullchain.pem;
  ssl_certificate_key /data/custom_ssl/npm-2/privkey.pem;

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
