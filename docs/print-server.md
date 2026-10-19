# Print Server (CUPS + SpliX on NAS)

## Overview

The NAS runs a CUPS print server for the Samsung Xpress M2020W connected
directly through USB. Ubuntu and Windows clients send IPP jobs to the NAS; CUPS
uses the SpliX filter to convert the job to Samsung QPDL and writes it to the
printer.

No VM, LXC container, or Docker container is created. CUPS runs directly on the
NAS operating system, alongside OpenMediaVault. The role does not modify OMV
configuration or OMV-managed services.

```text
Ubuntu / Windows
       |
      IPP (TCP 631)
       |
NAS (Debian + OpenMediaVault)
       |
      CUPS
       |
  SpliX 2.0.2 filter
       |
      USB
       |
Samsung Xpress M2020W
```

## Deployment status

Deployed and validated on the NAS on 2026-10-19.

| Item | Value |
|---|---|
| CUPS | `2.4.10-3+deb13u2`, `enabled` and `active` |
| Queue | `Samsung_M2020W`, idle, enabled, and accepting jobs |
| Device URI | `usb://Samsung/M2020%20Series?serial=<serial>` |
| IPP endpoint | `ipp://192.168.10.12:631/printers/Samsung_M2020W` |
| Admin URL | `https://printers.omni.corp/admin` (user `root`) |
| Admin authentication | CUPS Basic auth via NPM, `root` in `SystemGroup` |
| Physical printing | Confirmed by the operator |
| Driverless IPP | Supported by the CUPS queue |
| IPP versions | 1.0, 1.1, 2.0, 2.1 |
| Document formats | PDF, PostScript, PWG Raster, URF, and others |
| Mopria | 1.3 (`urf-supported: V1.4, CP1, W8, PQ4, RS600, DM1, FN3`) |

A completed print job in CUPS confirms that the job was accepted, filtered, and
sent to the backend. It does not by itself prove that paper was physically
ejected; physical output was confirmed separately by the operator.

## Compatibility note

The NAS runs Debian 13 (trixie), which ships CUPS 2.4.10 and
`printer-driver-splix` 2.0.1. SpliX 2.0.1 does **not** contain a model entry for
the Samsung M2020 series. Support for the M2020 series was added upstream in
SpliX 2.0.2.

The `print_server` role therefore:

1. Installs `cups`, `cups-client`, and `printer-driver-splix` from Debian.
2. Builds the pinned SpliX 2.0.2 source archive from the official OpenPrinting
   release and verifies its SHA-256 checksum.
3. Installs the new filter as `rastertoqpdl-m2020` instead of overwriting the
   Debian-owned `rastertoqpdl` binary.
4. Generates the `m2020.ppd` PPD from the pinned source and points its
   `*cupsFilter` entry to the versioned filter.
5. Registers the CUPS queue with that PPD.

CUPS 2.4 still supports classic PPD drivers. CUPS 3.x removes that support; if
Debian later moves to CUPS 3.x, the driver must be migrated to the
OpenPrinting Ghostscript Printer Application.

## Role integration

The role is declared in `playbooks/nas.yml`:

```yaml
- bootstrap
- docker
- postgres
- redis
- omv
- print_server
- minio
```

Host-specific, non-secret settings live in
`inventories/lab/host_vars/nas/vars.yml`.

## Configuration variables

| Variable | Default | Description |
|---|---|---|
| `print_server_packages` | `cups`, `cups-client`, `printer-driver-splix` | Debian packages installed from the distribution |
| `print_server_build_packages` | build tools and CUPS headers | Only used to build the pinned SpliX release |
| `print_server_listen_address` | `ansible_facts.default_ipv4.address` (fallback `ansible_host`) | NAS IPv4 address used by the CUPS `Listen` directive; no IP is hardcoded |
| `print_server_port` | `631` | IPP port |
| `print_server_allowed_networks` | `192.168.10.0/24` | LAN networks allowed by the CUPS access controls |
| `print_server_admin_networks` | `[]` (NAS host vars: `192.168.10.3/32`) | Networks allowed to reach the authenticated admin locations |
| `print_server_web_interface` | `true` | Enables the web interface |
| `print_server_printer_name` | `Samsung_M2020W` | CUPS queue name used in the IPP URL |
| `print_server_printer_description` | `Samsung Xpress M2020W` | Human-readable queue description |
| `print_server_printer_location` | `USB - NAS` | Human-readable queue location |
| `print_server_printer_uri` | empty | Optional explicit CUPS device URI; when empty, the role detects it with `lpinfo -v` |
| `print_server_usb_uri_pattern` | `^direct usb://Samsung/.*M2020.*` | Pattern used to select the USB printer from `lpinfo -v` |
| `print_server_make_default` | `false` | Sets the queue as the CUPS default printer |
| `print_server_splix_version` | `2.0.2` | Pinned SpliX release used for the M2020 filter and PPD |
| `print_server_splix_archive_checksum` | SHA-256 of 2.0.2 | Integrity check for the downloaded source archive |
| `print_server_splix_filter_name` | `rastertoqpdl-m2020` | Versioned filter name installed under `/usr/lib/cups/filter` |
| `print_server_splix_ppd_path` | `/usr/share/cups/ppd/samsung-m2020.ppd` | PPD generated from the pinned SpliX source |

When changing `print_server_splix_version`, update
`print_server_splix_archive_checksum` as well.

## Deployment

```bash
# Validate
yamllint .
ansible-lint .
ansible-playbook playbooks/nas.yml --syntax-check

# Preview only the print server changes on the NAS
ansible-playbook playbooks/nas.yml --limit nas --tags print_server --check --diff

# Apply only the print server role, without touching OMV, MinIO, or PostgreSQL
ansible-playbook playbooks/nas.yml --limit nas --tags print_server
```

The `print_server` role is tagged in `playbooks/nas.yml`, so the `--tags
print_server` selector runs only that role. The untagged OMV, MinIO, PostgreSQL,
Redis, Netdata, bootstrap, and Docker roles are skipped.

The first run installs packages, builds SpliX, creates the CUPS configuration,
and registers the queue. The build step requires outbound HTTPS access to
`github.com` to download the pinned release archive. The USB printer must be
connected and powered on for automatic URI detection. If it is not detected,
the role stops with a message instead of inventing a device URI.

## Networking and security

CUPS listens on the NAS LAN IPv4 address, on `127.0.0.1:631` for local
administration, and on the local Unix socket. It does not listen on `0.0.0.0`
unless `print_server_listen_address` is explicitly overridden with that value.

Access is restricted in `cupsd.conf` to:

- localhost (IPv4 loopback and the local Unix socket);
- the networks listed in `print_server_allowed_networks`.

Administrative locations (`/admin`, `/admin/conf`, `/admin/log`) require
authentication (`AuthType Default`, `Require user @SYSTEM`). They are reachable
from localhost and from the addresses/networks listed in
`print_server_admin_networks`. The NAS host vars allow only the NPM proxy
address (`192.168.10.3/32`). The NPM proxy connects to CUPS over HTTPS
(`https://192.168.10.12:631`). CUPS uses its self-signed certificate, so NPM
disables upstream certificate verification for this private hop
(`proxy_ssl_verify off`). CUPS keeps its default encryption requirement, and
authentication is never bypassed.

Do not publish TCP 631 on the internet and do not create a public port forward.
The NPM proxy is internal-only.

The NAS CUPS `SystemGroup` is `root lpadmin`, so the existing `root` account is
authorized. No additional CUPS users are created. Root authentication uses the
standard Debian PAM stack configured for CUPS (`/etc/pam.d/cups`).

### Browser-based administration via Nginx Proxy Manager

The NPM proxy host `printers.omni.corp` forwards to
`https://192.168.10.12:631` and uses the internal wildcard certificate:

```text
https://printers.omni.corp/admin
```

Open that URL from the private network and authenticate as `root` with the
existing NAS root password. NPM forwards the Basic authentication challenge and
the `Authorization` header to CUPS. Unauthenticated requests receive HTTP 401;
requests from addresses outside the allowed admin networks receive HTTP 403.

CUPS uses `ServerAlias *`, so it accepts the `printers.omni.corp` Host header
forwarded by NPM. The web UI entry point is `https://printers.omni.corp`.

TLS terminates at NPM for the browser, and NPM connects to CUPS over HTTPS on
port 631. CUPS uses its self-signed certificate, so NPM disables upstream
certificate verification for this private hop (`proxy_ssl_verify off`). CUPS
keeps its default `Encryption Required` policy for remote administration.
Authentication remains required (`AuthType Default`, `Require user @SYSTEM`),
and the admin locations are reachable only from localhost and
`print_server_admin_networks`. Do not route CUPS through a public proxy.

If end-to-end certificate verification is required, issue a CUPS certificate
from the internal CA and configure NPM with `proxy_ssl_verify on` and the
corresponding trusted certificate; that is outside this role.

Printing clients should keep using the direct IPP endpoint
(`ipp://192.168.10.12:631/printers/Samsung_M2020W` or
`ipp://nas:631/printers/Samsung_M2020W`). The NPM hostname is intended for the
web UI, not as the primary IPP endpoint.

## Validation

Do not assume printing works without completing a real print test.

### USB printer detection

```bash
lsusb | grep -i -E 'samsung|m2020'
lpinfo -v | grep -i usb
ls -l /usr/lib/cups/backend/usb
```

The stable URI reported by CUPS looks like:

```text
usb://Samsung/M2020%20Series?serial=...
```

Always prefer the `usb://...` URI containing the serial number over
`/dev/usb/lp*`, because device node numbers can change after a reconnect or
reboot.

If `lpinfo -v` does not list the printer:

```bash
lsusb -t
dmesg | tail -50
journalctl -u cups --no-pager -n 50
```

Check that `/usr/lib/cups/backend/usb` points to
`/usr/lib/cups/backend-available/usb`; the role creates that link when needed.

### CUPS service and listening socket

```bash
systemctl status cups
systemctl is-enabled cups
ss -tlnp | grep ':631'
```

The socket must be bound to the NAS LAN address (and optionally to localhost),
not to every interface.

### Printer registration and driver

```bash
lpstat -t
lpstat -v
lpstat -p Samsung_M2020W
lpoptions -p Samsung_M2020W -l
```

Check the queue PPD and the versioned filter:

```bash
grep -E '^\*(cupsFilter|ModelName|NickName)' /etc/cups/ppd/Samsung_M2020W.ppd
grep '^\*QPDL SpecialBandWidth' /etc/cups/ppd/Samsung_M2020W.ppd
test -x /usr/lib/cups/filter/rastertoqpdl-m2020 && echo filter-ok
```

The PPD must reference `rastertoqpdl-m2020` and contain
`*QPDL SpecialBandWidth: "True"`.

If a host firewall (nftables, ufw, or the OMV firewall) is enabled, allow TCP
631 from the LAN networks before testing:

```bash
ss -tlnp | grep ':631'
```

### IPP connectivity

From the NAS, using the IPP TCP listener:

```bash
lpstat -h 127.0.0.1:631 -p Samsung_M2020W
curl -sS -o /dev/null -w '%{http_code}\n' \
  http://127.0.0.1:631/printers/Samsung_M2020W
```

From another LAN host:

```bash
lpstat -h <nas-ip>:631 -p Samsung_M2020W
```

A successful `lpstat` query confirms IPP reachability. HTTP 200 on the printer
path confirms the web/IPP endpoint is reachable.

Check driverless capabilities from a client:

```bash
ipptool -tv ipp://192.168.10.12:631/printers/Samsung_M2020W \
  get-printer-attributes.test | grep -E \
  'ipp-versions-supported|document-format-supported|urf-supported|mopria-certified'
```

Expected values for this deployment: IPP 1.0/1.1/2.0/2.1, PDF/PWG
Raster/URF support, and Mopria 1.3. These attributes allow Ubuntu and Windows
to configure the queue driverlessly.

### Test page

From the NAS:

```bash
lp -d Samsung_M2020W /usr/share/cups/data/testprint
lpstat -o Samsung_M2020W
lpstat -W completed -o Samsung_M2020W
```

From an Ubuntu client:

```bash
lp -h <nas-ip>:631 -d Samsung_M2020W /usr/share/cups/data/testprint
```

Inspect the result physically. `lpstat` showing a completed job is not proof
that the printer produced the page. Physical output for this deployment was
confirmed by the operator.

### Ubuntu client setup

The NAS queue advertises IPP 2.0/2.1, PDF, PWG Raster, URF, and Mopria 1.3, so
Ubuntu can use driverless IPP. Prefer the `everywhere` model; do not install a
Samsung driver or select a generic PostScript driver on the client.

Graphical:

1. Open Settings -> Printers -> Add Printer.
2. Enter `ipp://192.168.10.12:631/printers/Samsung_M2020W`.
3. Select the detected queue and the `IPP Everywhere`/driverless option if
   prompted.
4. Print a test page.

Command line:

```bash
sudo apt install cups-client
sudo lpadmin -p Samsung_M2020W -E \
  -v ipp://192.168.10.12:631/printers/Samsung_M2020W \
  -m everywhere
lpstat -p Samsung_M2020W
lpoptions -p Samsung_M2020W -l
lp -d Samsung_M2020W /usr/share/cups/data/testprint
```

If `-m everywhere` is rejected, update `cups-client`/`libcups2` on the client
or use the graphical wizard and choose the driverless IPP option. As a last
resort, add the same IPP URL through the system's generic IPP queue; the queue
still uses the NAS PPD and the SpliX filter for rendering.

Verify remote connectivity without adding the queue:

```bash
lpstat -h 192.168.10.12:631 -p Samsung_M2020W
ipptool -tv ipp://192.168.10.12:631/printers/Samsung_M2020W get-printer-attributes.test
```

On Ubuntu, `ipptool` is provided by `cups-ipp-utils`.

### Windows 10/11 client setup

The queue is Mopria 1.3 and IPP Everywhere capable, so prefer the Windows
built-in driverless IPP support over a vendor or generic PostScript driver.

1. Enable the optional Windows feature `Internet Printing Client` if it is not
   already installed (Settings -> Apps -> Optional features -> More Windows
   features -> Print and Document Services -> Internet Printing Client).
2. Open Settings -> Bluetooth & devices -> Printers & scanners -> Add device.
3. Choose "The printer that I want isn't listed".
4. Choose "Select a shared printer by name" and enter
   `http://192.168.10.12:631/printers/Samsung_M2020W`.
5. When Windows asks for a driver, select `Microsoft IPP Class Driver`
   (driverless). The NAS advertises IPP 2.0/2.1, PDF, PWG Raster, URF, and
   Mopria 1.3, so the class driver can render through CUPS and SpliX.
6. Print the Windows test page.

Do not assume a generic PostScript driver is compatible with the M2020W. A
generic PostScript driver only works because CUPS converts PostScript to QPDL
with SpliX on the NAS; it may lose status and feature support and is not the
recommended configuration. A Samsung Windows driver would require a raw queue,
which this deployment intentionally does not expose.

If `Microsoft IPP Class Driver` is not offered, the Windows build may lack
driverless IPP support. In that case, use a Windows version/feature level that
includes the IPP Class Driver, or document the limitation; do not install the
vendor driver against the shared queue.

The canonical IPP URL is:

```text
ipp://<nas-ip>:631/printers/<printer-name>
```

With the deployed values:

```text
ipp://192.168.10.12:631/printers/Samsung_M2020W
```

The short hostname `nas` also works from clients that use the lab DNS resolver:

```text
ipp://nas:631/printers/Samsung_M2020W
```

## Troubleshooting

### The printer is not detected

```bash
lsusb
lpinfo -v
lpinfo -l -v
```

If the device URI changes or detection is ambiguous, set it explicitly in
`inventories/lab/host_vars/nas/vars.yml`:

```yaml
print_server_printer_uri: "usb://Samsung/M2020%20Series?serial=SERIAL_NUMBER"
```

Then rerun the playbook.

### Ubuntu client cannot add or print

```bash
# IPP reachability from the client
lpstat -h 192.168.10.12:631 -p Samsung_M2020W
curl -sS -o /dev/null -w '%{http_code}\n' \
  http://192.168.10.12:631/printers/Samsung_M2020W

# Client queue state and recent errors
lpstat -p -d
lpstat -t
journalctl -u cups --no-pager -n 50
```

If the queue was added with a stale IP or hostname, remove and recreate it:

```bash
sudo lpadmin -x Samsung_M2020W
sudo lpadmin -p Samsung_M2020W -E \
  -v ipp://192.168.10.12:631/printers/Samsung_M2020W \
  -m everywhere
```

Confirm that the client and the NAS are on an allowed LAN and that no local
firewall blocks outbound TCP 631.

### Windows client cannot add or print

- Confirm that `Internet Printing Client` is enabled in Windows Features.
- Add the printer with the `http://192.168.10.12:631/printers/Samsung_M2020W`
  URL, not a hostname that does not resolve on the client.
- Select `Microsoft IPP Class Driver` when prompted; do not install a Samsung
  or generic PostScript driver against the shared queue.
- Test basic reachability from PowerShell:

```powershell
Test-NetConnection 192.168.10.12 -Port 631
Invoke-WebRequest http://192.168.10.12:631/printers/Samsung_M2020W
```

- Check Windows Event Viewer under `Applications and Services Logs -> Microsoft
  -> Windows -> PrintService` for spooler errors.

### Driverless IPP is not offered

Query the server attributes from a Linux client:

```bash
ipptool -tv ipp://192.168.10.12:631/printers/Samsung_M2020W \
  get-printer-attributes.test | grep -E \
  'ipp-versions-supported|document-format-supported|urf-supported|mopria-certified'
```

The queue should report IPP 2.0/2.1, PDF/PWG Raster/URF, and Mopria 1.3. If
those attributes are missing, verify that CUPS is running on the NAS and that
the client is querying the queue over IPP, not a raw socket or LPD URL.

### Browser administration returns 403 or 401

HTTP 403 means the request did not originate from an allowed admin network.
CUPS sees the NPM proxy address, not the browser address:

```bash
grep -A8 '<Location /admin>' /etc/cups/cupsd.conf
getent hosts proxy
```

The NPM address must be present in `print_server_admin_networks` in
`inventories/lab/host_vars/nas/vars.yml`.

HTTP 426 means CUPS requires TLS for the admin location. Confirm that the NPM
proxy host forwards to `https://192.168.10.12:631`, not `http://...`, and that
the request reaches CUPS through the NPM proxy address. Do not weaken CUPS
encryption; fix the upstream scheme instead.

HTTP 401 means CUPS received the request but authentication failed. Confirm:

```bash
passwd -S root
grep '^SystemGroup' /etc/cups/cups-files.conf
cat /etc/pam.d/cups
tail -n 50 /var/log/cups/error_log
```

Root must have a usable password (`P`), must be included in the CUPS
`SystemGroup`, and PAM for CUPS must include the standard Debian `common-auth`
stack. Do not disable authentication or change the root password to work around
a 401.

Test the challenge and the Authorization forwarding through NPM:

```bash
curl -k -sS -D - -o /dev/null https://printers.omni.corp/admin
curl -k -sS -o /dev/null -w '%{http_code}\n' \
  -u root:wrong-password https://printers.omni.corp/admin
```

The first request must return `401` with a `WWW-Authenticate` header. The second
must return `401`, not `200`.

### CUPS configuration fails to validate

```bash
cupsd -t -c /etc/cups/cupsd.conf
```

The role uses the same command as an Ansible template validation step. Fix the
reported line or restore the pre-Ansible backup:

```bash
cp /etc/cups/cupsd.conf.pre-ansible /etc/cups/cupsd.conf
systemctl restart cups
```

### Queue is stopped or rejecting jobs

```bash
cupsenable Samsung_M2020W
cupsaccept Samsung_M2020W
lpstat -t
```

### Jobs stay in the queue or fail

```bash
tail -n 100 /var/log/cups/error_log
journalctl -u cups --no-pager -n 100
lpstat -o
lpstat -W not-completed -o
```

Common causes:

- USB backend not enabled or USB cable disconnected;
- printer powered off or in error state (paper, toner, cover);
- PPD does not contain `*QPDL SpecialBandWidth: "True"`;
- filter `rastertoqpdl-m2020` missing or not executable.

Cancel stale jobs and test again:

```bash
cancel -a Samsung_M2020W
lp -d Samsung_M2020W /usr/share/cups/data/testprint
```

### AppArmor blocks the USB backend

On Debian 13, the CUPS AppArmor profile can deny libusb access to symlinks under
`/sys`. Confirm with:

```bash
aa-status | grep cupsd
journalctl -k | grep -i apparmor
```

If the denial is present, add this local override:

```bash
printf '/ r,\n' > /etc/apparmor.d/local/usr.sbin.cupsd
apparmor_parser -r /etc/apparmor.d/usr.sbin.cupsd
systemctl restart cups
```

### Wrong driver or wrong queue

```bash
grep -E '^\*(cupsFilter|ModelName)' /etc/cups/ppd/Samsung_M2020W.ppd
```

To force a clean rebuild of the queue:

```bash
lpadmin -x Samsung_M2020W
ansible-playbook playbooks/nas.yml --limit nas
```

### Increase CUPS log verbosity temporarily

```bash
cupsctl --debug-logging
# reproduce the problem
tail -f /var/log/cups/error_log
cupsctl --no-debug-logging
systemctl restart cups
```

## Maintenance

Reapply the role after changing variables:

```bash
ansible-playbook playbooks/nas.yml --limit nas --check --diff
ansible-playbook playbooks/nas.yml --limit nas
```

Useful commands:

```bash
# Queue and device status
lpstat -t
lpstat -v

# PPD and filter
ls -l /usr/lib/cups/filter/rastertoqpdl-m2020
grep -E '^\*(cupsFilter|QPDL SpecialBandWidth)' /etc/cups/ppd/Samsung_M2020W.ppd

# CUPS configuration
cupsd -t -c /etc/cups/cupsd.conf

# Service and logs
systemctl restart cups
journalctl -u cups --no-pager -n 100
tail -f /var/log/cups/error_log

# Remove a queue
lpadmin -x Samsung_M2020W
```

The pre-Ansible CUPS configuration is preserved at
`/etc/cups/cupsd.conf.pre-ansible` on the NAS.

## Manual steps after deployment

1. Deployment, queue registration, and physical printing are confirmed.
2. Add the printer on the Ubuntu workstation using driverless IPP
   (`-m everywhere`); see the Ubuntu section above.
3. Add the printer on Windows 10/11 using `Microsoft IPP Class Driver`; see the
   Windows section above.
4. If a client cannot use driverless IPP, collect the server attributes with
   `ipptool` and follow the troubleshooting section before selecting any
   vendor or generic PostScript driver.
5. If automatic USB detection ever fails after a hardware change, identify the
   URI with `lpinfo -v`, set `print_server_printer_uri`, and rerun the role.
