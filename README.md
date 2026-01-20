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

**⚠️ IMPORTANT:** Any imperative (non-declarative) setup steps must be documented here to ensure reproducibility.

### Tailscale Authentication

After first boot, connect to your Tailscale network:

```bash
# Generate a reusable auth key at: https://login.tailscale.com/admin/settings/keys
sudo tailscale up --ssh --authkey=tskey-auth-xxxxxxxxxx
```

The authentication persists across reboots - you only need to do this once per machine.

### Samba Password Setup (Server Only)

After enabling Samba shares, set your Samba password:

```bash
sudo smbpasswd -a $USER
```

**Why this is imperative:** Samba requires SMB-protocol-specific password hashes that cannot be declaratively derived from system passwords. This must be set once per user.

**To connect from Windows:**
1. Press `Win + R`
2. Type: `\\<server-tailscale-ip>` (e.g., `\\100.80.198.94`)
3. Username: `username`
4. Password: The password you set with `smbpasswd`

Available shares:
- `\\<server-ip>\minecraft` - Minecraft server files
- `\\<server-ip>\homes` - Home directory

### Playit Agent Setup (Server Only)

Playit.gg provides tunneling to expose the Minecraft server on a custom domain.

**Initial claim (one-time setup):**

```bash
# Download and run the playit agent to claim it
nix run github:pedorich-n/playit-nixos-module#playit-cli -- start
```

Follow the link provided to claim the agent on playit.gg website. After claiming, exit the program and copy the secret:

```bash
# Copy the generated secret to the expected location
sudo mkdir -p /var/lib/playit
sudo cp ~/.config/playit_gg/playit.toml /var/lib/playit/
sudo chown playit:playit /var/lib/playit/playit.toml
sudo chmod 600 /var/lib/playit/playit.toml
```

**Configure tunnels:**
1. Go to https://playit.gg/account/tunnels
2. Create a tunnel for port `25565` (Minecraft)
3. Optionally set up a custom domain

**Why this is important:** The playit agent secret is generated when you claim the agent and cannot be created declaratively.

After setup, the playit service will automatically start and maintain the tunnel.