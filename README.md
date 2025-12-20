# NixOS Configuration

A modular, multi-host NixOS configuration with home-manager integration.

## Hosts

- **desktop** - Gaming/workstation with NVIDIA RTX 5080, GNOME, dual-boot
- **laptop** - Portable machine with NVIDIA RTX 3050 Mobile, GNOME, battery optimization
- **wsl** - Windows Subsystem for Linux development environment

## Structure

```
nixos-config/
├── flake.nix                    # Main flake configuration
├── hosts/                       # Host-specific configurations
│   ├── desktop/
│   ├── laptop/
│   ├── server/
│   └── wsl/
├── modules/
│   ├── nixos/                   # System-level modules
│   │   ├── core.nix            # Base config for all systems
│   │   ├── boot/               # Bootloader configurations
│   │   ├── hardware/           # Hardware-specific configs (NVIDIA, etc.)
│   │   └── services/           # Desktop environments and services
│   └── home-manager/           # User-level modules
│       ├── core.nix            # Base user config
│       ├── desktop.nix         # GUI user config
│       ├── server.nix          # Server user config
│       └── programs/           # Individual program configs
└── home/
    └── leyton/                 # Per-host user configurations
        ├── desktop.nix
        ├── laptop.nix
        ├── server.nix
        └── wsl.nix
```

## Design Principles

### Modularity
- **Core modules** provide base functionality shared across all hosts
- **Service modules** add specific features (GNOME, NVIDIA, etc.)
- **Host configs** compose modules and add host-specific settings

### Separation of Concerns
- **NixOS modules** (`modules/nixos/`) - System-level configuration
- **Home Manager modules** (`modules/home-manager/`) - User-level configuration
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
# Set HOSTNAME to: desktop, laptop, or wsl
HOSTNAME=desktop
sudo cp /etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/$HOSTNAME/
sudo chown $USER:users ~/nixos-config/hosts/$HOSTNAME/hardware-configuration.nix

# Exit the temporary shell
exit

# Navigate to the config directory
cd ~/nixos-config

# Update flake.lock (first time only)
nix flake update

# Build and switch to the new configuration
sudo nixos-rebuild switch --flake .#$HOSTNAME

# Reboot to complete the transition
sudo reboot
```