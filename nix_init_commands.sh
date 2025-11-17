# 1. Save hardware configuration to /tmp (we'll move it later)
sudo cp /etc/nixos/hardware-configuration.nix /tmp/

# 2. Enter a shell with git available
nix-shell -p git

# 3. Clone your config (replace with your actual repo URL)
git clone https://github.com/boxsitter/nixos-config.git ~/nixos-config

# 4. Determine which host configuration to use (desktop, vm, or wsl)
# For desktop:
HOSTNAME=desktop
# For VM:
# HOSTNAME=vm
# For WSL:
# HOSTNAME=wsl

# 5. Copy hardware configuration to the appropriate host directory
sudo cp /tmp/hardware-configuration.nix ~/nixos-config/hosts/$HOSTNAME/

# 6. Update flake.lock (first time only)
cd ~/nixos-config
nix --extra-experimental-features "nix-command flakes" flake update

# 7. Exit the nix-shell
exit
HOSTNAME=desktop

# 8. Build and switch to your configuration
sudo nixos-rebuild switch --flake .#$HOSTNAME

# 9. Reboot to ensure everything loads properly
sudo reboot