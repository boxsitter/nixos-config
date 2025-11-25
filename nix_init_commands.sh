nix-shell -p git
git clone https://github.com/boxsitter/nixos-config.git ~/nixos-config

# Copy hardware configuration for this machine
# Set HOSTNAME to: desktop, laptop, vm, or wsl
HOSTNAME=desktop
sudo cp /etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/$HOSTNAME/hardware.nix
sudo chown $USER:users ~/nixos-config/hosts/$HOSTNAME/hardware.nix

# Update flake.lock (first time only)
cd ~/nixos-config
nix --extra-experimental-features "nix-command flakes" flake update

exit
cd ~/nixos-config

# Build and switch to new configuration
sudo nixos-rebuild switch --flake .#$HOSTNAME
sudo reboot