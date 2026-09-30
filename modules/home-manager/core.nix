# modules/home-manager/core.nix
# Base home-manager configuration - reusable across any user
# User-specific settings (username, home directory) belong in home/username/ files

{ ... }:

{
  imports = [
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/fastfetch.nix
    ./programs/micro.nix
  ];

  catppuccin = {
    # Global toggle stays on; ports are opted into individually (fish, kitty, ...)
    enable = true;
    autoEnable = false;
    flavor = "macchiato";
    accent = "blue";
    starship.enable = false;
  };
}
