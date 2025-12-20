# NixOS Configuration

A modular, multi-host NixOS configuration with home-manager integration.

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
│   │   └── leyton.nix          # User config
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
            └── leyton.nix
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

## Core Features

All hosts include:
- **SSH** - Secure shell access (key-based auth only)
- **Tailscale** - VPN for secure remote access
- **Fish shell** with modern CLI tools (eza, bat, ripgrep, fd, btop)
- **1Password CLI** - Password management
- **Docker** - Container runtime

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

### Tailscale Authentication

After first boot, connect to your Tailscale network:

```bash
# Generate a reusable auth key at: https://login.tailscale.com/admin/settings/keys
sudo tailscale up --ssh --authkey=tskey-auth-xxxxxxxxxx
```

The authentication persists across reboots - you only need to do this once per machine.