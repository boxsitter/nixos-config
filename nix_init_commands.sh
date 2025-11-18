nix-shell -p git
git clone https://github.com/boxsitter/nixos-config.git ~/nixos-config

# 6. Update flake.lock (first time only)
cd ~/nixos-config
nix --extra-experimental-features "nix-command flakes" flake update

exit
cd ~/nixos-config

# For desktop:
HOSTNAME=desktop
# For VM:
# HOSTNAME=vm
# For WSL:
# HOSTNAME=wsl

sudo nixos-rebuild switch --flake .#$HOSTNAME
sudo reboot