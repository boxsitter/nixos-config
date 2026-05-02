# NixOS Configuration

My modular, multi-host NixOS configuration with home-manager integration.

## Hosts

- **desktop** - Gaming/workstation with NVIDIA RTX 5080, GNOME, dual-boot
- **laptop** - Portable machine with NVIDIA RTX 3050 Mobile, GNOME, battery optimization
- **server** - Headless server with SSH and Tailscale
- **wsl** - Windows Subsystem for Linux development environment

## Structure

```
nixos-config/
├── flake.nix                    # Main flake configuration
├── hosts/                       # Host-specific configurations
│   ├── desktop/
│   │   ├── configuration.nix   # System config
│   │   └── user.nix          # User config
│   ├── laptop/
│   ├── server/
│   └── wsl/
└── modules/
    ├── nixos/                   # System-level modules
    │   ├── core.nix            # Base config for all systems
    │   ├── boot/               # Bootloader configurations
    │   ├── hardware/           # Hardware-specific configs
    │   ├── programs/           # System programs
    │   └── services/           # System services (SSH, Tailscale, etc.)
    └── home-manager/           # User-level modules
        ├── core.nix            # Base user config
        ├── desktop.nix         # GUI additions
        ├── programs/           # Program configs (fish, git, etc.)
        ├── dotfiles/           # Configuration files
        └── users/              # User identity configs
            └── user.nix
```

## Design Principles

### Modularity
- **Core modules** provide base functionality shared across all hosts
- **Service modules** add specific features (GNOME, NVIDIA, etc.)
- **Host configs** compose modules and add host-specific settings

### Separation of Concerns
- **NixOS modules** (`modules/nixos/`) - System-level configuration
- **Home-manager modules** (`modules/home-manager/`) - User-level configuration  
- **Hosts** - Minimal composition layer importing relevant modules

### Conventional Package Management
- Packages live in the modules that use them
- CLI packages in `modules/nixos/core.nix`
- GUI packages in `modules/nixos/services/gnome.nix`
- Host-specific packages in host configurations

## Initial Setup (Fresh NixOS Installation)

Starting from a blank NixOS installation with internet access:

```bash
# Enter a temporary shell with git available
nix-shell -p git

# Clone this repository
git clone https://github.com/boxsitter/nixos-config.git ~/nixos-config

# Copy the hardware configuration from your current system
# Set HOSTNAME to: desktop, laptop, server, or wsl
HOSTNAME=desktop
sudo cp /etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/$HOSTNAME/
sudo chown $USER:users ~/nixos-config/hosts/$HOSTNAME/hardware-configuration.nix
git add ~/nixos-config/hosts/$HOSTNAME/hardware-configuration.nix

# Navigate to the config directory
cd ~/nixos-config

# Update flake.lock (first time only)
nix flake update --extra-experimental-features 'nix-command flakes'

# Build and switch to the new configuration
sudo nixos-rebuild switch --flake .#$HOSTNAME

# Reboot to complete the transition
sudo reboot
```

**Note:** WSL does not require hardware-configuration.nix

## Post-Installation Setup

After the initial rebuild, some imperative setup steps are required for specific functionality.

### Setup for All Hosts

#### 1. Configure Tailscale

Authenticate the Tailscale VPN connection:

```bash
sudo tailscale up
```

Follow the authentication URL displayed in the terminal.

**Verify:**
```bash
# Should show "Logged in" or similar status
sudo tailscale status | head -1
```

### Setup for Server Only

#### 2. Generate Age Key (Server)

The secrets system uses an age key to decrypt secrets at runtime. It is auto-generated on first rebuild:

```bash
sudo nixos-rebuild switch --flake .#server
```

**Verify:**
```bash
sudo test -f /var/lib/sops-nix/key.txt && echo "✓ Age key exists" || echo "✗ Age key missing"
```

The server's public key is already in `.sops.yaml`. If you ever need to extract it (e.g. after reimaging):

```bash
nix-shell -p ssh-to-age --run 'sudo cat /var/lib/sops-nix/key.txt | ssh-to-age -public-key'
```

If the key changes, update `.sops.yaml` and re-encrypt from another authorized machine with:

```bash
export SOPS_AGE_KEY=$(sudo cat /var/lib/sops-nix/key.txt)
nix-shell -p sops --run 'sops updatekeys secrets/secrets.yaml'
```

#### 3. Add Cloudflare DNS Token (Server)

Caddy uses Cloudflare's DNS API to complete ACME DNS-01 challenges for TLS certificates. You need a Cloudflare API token with the correct permissions.

**Create the token:**

1. Go to [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Use the **Edit zone DNS** template, or create a custom token with:
   - **Permissions:** `Zone` → `DNS` → `Edit`
   - **Zone Resources:** `Include` → `Specific zone` → `lhsv.net`
4. Set an expiry if desired (note: if it expires, certs will fail to renew — use "no expiry" for a server)
5. Copy the token value

**Add the token to secrets:**

```bash
export SOPS_AGE_KEY=$(sudo cat /var/lib/sops-nix/key.txt)
nix-shell -p sops --run 'sops secrets/secrets.yaml'
```

The token must be in the format Caddy's environment file expects (a `KEY=VALUE` line):

```
CLOUDFLARE_API_TOKEN=your-token-here
```

Save and exit.

**Verify:**
```bash
# Check secret is encrypted
grep -q "cloudflare-dns-token.*ENC\[" secrets/secrets.yaml && echo "✓ Cloudflare token encrypted" || echo "✗ Token not encrypted"

# Check can decrypt
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run 'sops -d secrets/secrets.yaml' | grep -q "cloudflare-dns-token" && echo "✓ Can decrypt token" || echo "✗ Cannot decrypt"

# After rebuild, check it's deployed
sudo test -f /run/secrets/cloudflare-dns-token && echo "✓ Token deployed" || echo "✗ Token not deployed"
```

#### 4. Set Samba Password (Server)

Configure Samba password for file sharing:

```bash
sudo smbpasswd -a leyton
```

Enter password when prompted.

**Verify:**
```bash
# Check user exists in Samba database
sudo pdbedit -L | grep -q "^leyton:" && echo "✓ Samba user configured" || echo "✗ Samba user not found"
```

#### 5. Claim Playit Tunnel (Server)

Start the playit service and claim the tunnel:

```bash
# Start the service to generate claim URL
sudo systemctl start playit

# Get claim URL from logs
sudo journalctl -u playit -n 50 | grep -i "claim"
```

Visit the claim URL and complete setup on playit.gg website.

**Verify:**
```bash
# Check playit is running
sudo systemctl is-active playit && echo "✓ Playit service running" || echo "✗ Playit not running"

# Check for claim status in logs
sudo journalctl -u playit -n 20 | grep -qi "claimed\|connected" && echo "✓ Tunnel claimed" || echo "? Check playit logs manually"
```

#### 6. Configure Monitoring — Prometheus + Grafana (Server)

The monitoring stack (`modules/nixos/services/server/monitoring.nix`) provides:

- **Prometheus** at `https://system.lhsv.net` — metrics store
- **Grafana** at `https://status.lhsv.net` — dashboards (Node Exporter Full, Systemd per-service CPU/network, Process Exporter, smartctl, Loki logs, Exportarr *arr metrics)
- **Loki + Alloy** — log aggregation from systemd journal
- **Per-service network metrics** via `DefaultIPAccounting=yes` (requires one reboot after first deploy)

Setup happens in two phases.

##### Phase A — Before first deploy: add Grafana secrets

```bash
export SOPS_AGE_KEY=$(sudo cat /var/lib/sops-nix/key.txt)
nix-shell -p sops --run 'sops secrets/secrets.yaml'
```

Add the following keys (raw values, **not** `KEY=VALUE` format):

```yaml
grafana-admin-password: <choose a strong password>
grafana-secret-key: <output of: openssl rand -base64 32>
sonarr-api-key: ""
radarr-api-key: ""
lidarr-api-key: ""
prowlarr-api-key: ""
sabnzbd-api-key: ""
```

The five `*-api-key` entries can be left empty for now — their exporter units will stay in a restart loop until backfilled (step B), but the rest of the stack will work.

Save and exit sops, then rebuild and **reboot once**:

```bash
sudo nixos-rebuild switch --flake .#server
sudo reboot
```

The reboot is required for `DefaultIPAccounting=yes` to apply to every systemd unit. Without it, the Systemd Services dashboard's per-service network panels will be empty.

**Verify:**
```bash
# All core services running
for svc in prometheus grafana loki alloy \
  prometheus-node-exporter \
  prometheus-systemd-exporter \
  prometheus-process-exporter \
  prometheus-smartctl-exporter; do
  systemctl is-active --quiet $svc \
    && echo "✓ $svc" || echo "✗ $svc"
done

# Per-service IP accounting flowing (should show non-zero byte counts)
curl -s 127.0.0.1:9558/metrics | grep -m 3 systemd_unit_ip_ingress_bytes

# All Prometheus scrape targets healthy (open in browser over Tailscale)
# https://system.lhsv.net/targets
```

Log in to `https://status.lhsv.net` with `admin` and the password you set above. Both datasources (Prometheus, Loki) should be green and six dashboards should appear.

##### Phase B — After first deploy: backfill *arr and SABnzbd API keys

The five app exporters require each service's API key. Extract them from the running services:

```bash
# *arr keys (look for the <ApiKey> element in each config file)
sudo grep -h "<ApiKey>" \
  /var/lib/sonarr/.config/NzbDrone/config.xml \
  /var/lib/radarr/.config/Radarr/config.xml \
  /var/lib/lidarr/.config/Lidarr/config.xml \
  /var/lib/prowlarr/.config/Prowlarr/config.xml

# SABnzbd key: Settings → General → API Key in the web UI at https://usenet.lhsv.net
```

Then re-open sops and paste each raw key string (no XML tags, no quotes) into the corresponding entry:

```bash
export SOPS_AGE_KEY=$(sudo cat /var/lib/sops-nix/key.txt)
nix-shell -p sops --run 'sops secrets/secrets.yaml'
```

Rebuild (no reboot needed this time):

```bash
sudo nixos-rebuild switch --flake .#server
```

**Verify:**
```bash
# All five app exporters now running
for svc in \
  prometheus-exportarr-sonarr-exporter \
  prometheus-exportarr-radarr-exporter \
  prometheus-exportarr-lidarr-exporter \
  prometheus-exportarr-prowlarr-exporter \
  prometheus-sabnzbd-exporter; do
  systemctl is-active --quiet $svc \
    && echo "✓ $svc" || echo "✗ $svc"
done

# All Prometheus targets UP including exportarr and sabnzbd
# https://system.lhsv.net/targets
```

##### Notes

- **smartctl device list** defaults to `/dev/nvme0` and `/dev/sda`. Confirm with `lsblk -d -o NAME,TYPE,MODEL,TRAN` and adjust the `devices` list in `monitoring.nix` if your drives differ.
- **Caddy metrics** (request rates, latency, status codes per virtualhost) are scraped automatically — no extra steps required.
- **Alerting** is not configured. Prometheus and Grafana support Alertmanager if you want to add it later.

### Final Steps

#### 7. Commit and Deploy

```bash
git add .sops.yaml secrets/secrets.yaml
git commit -m "Add/update encrypted secrets"
git push

# Pull on other hosts and rebuild
git pull
sudo nixos-rebuild switch --flake .#<hostname>
```

**Verify:**
```bash
# Check no uncommitted changes
git status | grep -q "nothing to commit" && echo "✓ All changes committed" || echo "✗ Uncommitted changes"
```

### Complete Verification Checklist

**All hosts:**
```bash
echo "=== Tailscale ==="
sudo tailscale status >/dev/null 2>&1 && echo "✓ Tailscale configured" || echo "✗ Tailscale not configured"
```

**Server only:**
```bash
echo "=== Age Key ==="
sudo test -f /var/lib/sops-nix/key.txt && echo "✓ Age key exists" || echo "✗ Age key missing"

echo "=== Cloudflare Token ==="
sudo test -f /run/secrets/cloudflare-dns-token && echo "✓ Token deployed" || echo "✗ Token not deployed"

echo "=== Samba ==="
sudo pdbedit -L 2>/dev/null | grep -q "^leyton:" && echo "✓ Samba user configured" || echo "✗ Samba user not found"

echo "=== Playit ==="
sudo systemctl is-active playit >/dev/null 2>&1 && echo "✓ Playit tunnel running" || echo "✗ Playit not running"

echo "=== Monitoring (core) ==="
for svc in prometheus grafana loki alloy \
  prometheus-node-exporter \
  prometheus-systemd-exporter \
  prometheus-process-exporter \
  prometheus-smartctl-exporter; do
  systemctl is-active --quiet $svc 2>/dev/null \
    && echo "✓ $svc" || echo "✗ $svc"
done

echo "=== Monitoring (app exporters — requires Phase B secrets) ==="
for svc in \
  prometheus-exportarr-sonarr-exporter \
  prometheus-exportarr-radarr-exporter \
  prometheus-exportarr-lidarr-exporter \
  prometheus-exportarr-prowlarr-exporter \
  prometheus-sabnzbd-exporter; do
  systemctl is-active --quiet $svc 2>/dev/null \
    && echo "✓ $svc" || echo "✗ $svc (needs API key)"
done

echo "=== IPAccounting (per-service network metrics) ==="
curl -s 127.0.0.1:9558/metrics 2>/dev/null | grep -qm1 systemd_unit_ip_ingress_bytes \
  && echo "✓ IPAccounting metrics present" \
  || echo "✗ IPAccounting metrics missing — reboot required"
```