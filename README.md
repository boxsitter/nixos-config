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

#### 1. Generate Age Keys

Each host needs an age key for encrypting/decrypting secrets. This is auto-generated on first rebuild:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

**Verify:**
```bash
sudo test -f /var/lib/sops-nix/key.txt && echo "✓ Age key exists" || echo "✗ Age key missing"
```

#### 2. Get Public Key

Extract the public key from each host:

```bash
nix-shell -p ssh-to-age --run 'sudo cat /var/lib/sops-nix/key.txt | ssh-to-age -public-key'
```

**Example output:** `age1uypa94r4vz7e2jrmruyu6857a6hxyntzxhnsfw2n5eq4n2lfy96qtjc7hq`

**Verify:**
```bash
# Should output an age public key starting with "age1"
nix-shell -p ssh-to-age --run 'sudo cat /var/lib/sops-nix/key.txt | ssh-to-age -public-key' | grep -q "^age1" && echo "✓ Valid public key" || echo "✗ Invalid key"
```

#### 3. Create `.sops.yaml`

From any host, create or update `.sops.yaml` with all host public keys:

```yaml
keys:
  - &server age1uypa94r4vz7e2jrmruyu6857a6hxyntzxhnsfw2n5eq4n2lfy96qtjc7hq
  - &desktop age1k7ktnh8ccl6gj3zc4mtmrt9anhxlnx02l8cnxxdys6uq5re33fas4hhz29
  - &laptop age1psmeqgs6q7v2d8ynqyrss4uvzx5we4khqffa62ech6u7xzw9ysls69pwa8
  - &wsl age1yntm4skd29yc52hlku2gk3te4a9ws2hynqn8wqwkksc4tvv8l98ql4lm4q

creation_rules:
  - path_regex: secrets/secrets.yaml$
    key_groups:
      - age:
        - *server
        - *desktop
        - *laptop
        - *wsl
```

**Verify:**
```bash
# Check .sops.yaml exists and contains this host's key
PUB_KEY=$(nix-shell -p ssh-to-age --run 'sudo cat /var/lib/sops-nix/key.txt | ssh-to-age -public-key')
grep -q "$PUB_KEY" .sops.yaml && echo "✓ This host is in .sops.yaml" || echo "✗ This host missing from .sops.yaml"
```

#### 4. Configure Tailscale

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

#### 5. Add Cloudflare DNS Token (Server)

Edit secrets to add the Cloudflare API token for Caddy DNS-01 ACME challenges:

```bash
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run 'sops secrets/secrets.yaml'
```

Add in the editor:
```yaml
cloudflare-dns-token: your-cloudflare-api-token-here
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

#### 6. Set Samba Password (Server)

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

#### 7. Claim Playit Tunnel (Server)

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

### Setup for Client Hosts (Desktop, Laptop, WSL)

#### 8. Add Samba Credentials (Client Hosts)

Edit secrets to add Samba mount credentials:

```bash
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run 'sops secrets/secrets.yaml'
```

Add in the editor:
```yaml
samba-credentials: |
  username=leyton
  password=your-samba-password
  domain=WORKGROUP
```

Save and exit.

**Verify:**
```bash
# Check secret is encrypted
grep -q "samba-credentials.*ENC\[" secrets/secrets.yaml && echo "✓ Samba credentials encrypted" || echo "✗ Credentials not encrypted"

# Check can decrypt
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run 'sops -d secrets/secrets.yaml' | grep -q "samba-credentials" && echo "✓ Can decrypt credentials" || echo "✗ Cannot decrypt"

# After rebuild with samba-client enabled, check mount point exists
test -d /mnt/server && echo "✓ Samba mount point created" || echo "✗ Mount point missing"

# Try to access the mount (will auto-mount via systemd)
ls /mnt/server >/dev/null 2>&1 && echo "✓ Can access Samba share" || echo "✗ Cannot access share"
```

### Final Steps

#### 9. Re-encrypt After Adding New Host

If you add a new host's key to `.sops.yaml`, re-encrypt the secrets file:

```bash
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run 'sops updatekeys secrets/secrets.yaml'
```

**Verify:**
```bash
# Check last modified timestamp updated
stat -c %y secrets/secrets.yaml
```

#### 10. Commit and Deploy

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

Run on each host to verify full setup:

```bash
echo "=== Age Key Setup ==="
sudo test -f /var/lib/sops-nix/key.txt && echo "✓ Age key exists" || echo "✗ Age key missing"

echo "=== SOPS Configuration ==="
PUB_KEY=$(nix-shell -p ssh-to-age --run 'sudo cat /var/lib/sops-nix/key.txt | ssh-to-age -public-key')
grep -q "$PUB_KEY" .sops.yaml && echo "✓ In .sops.yaml" || echo "✗ Missing from .sops.yaml"

echo "=== Secrets Decryption ==="
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run 'sops -d secrets/secrets.yaml' >/dev/null 2>&1 && echo "✓ Can decrypt" || echo "✗ Cannot decrypt"

echo "=== Tailscale ==="
sudo tailscale status >/dev/null 2>&1 && echo "✓ Tailscale configured" || echo "✗ Tailscale not configured"

echo "=== Secrets Deployment (after rebuild) ==="
sudo test -f /run/secrets/cloudflare-dns-token && echo "✓ Cloudflare token (server)" || echo "- Cloudflare token (not server or not deployed)"
sudo test -f /run/secrets/samba-credentials && echo "✓ Samba credentials (client)" || echo "- Samba credentials (not client or not deployed)"

echo "=== Server-Specific ==="
sudo pdbedit -L 2>/dev/null | grep -q "^leyton:" && echo "✓ Samba user (server)" || echo "- Samba user (not server or not configured)"
sudo systemctl is-active playit >/dev/null 2>&1 && echo "✓ Playit tunnel (server)" || echo "- Playit tunnel (not server or not running)"
```