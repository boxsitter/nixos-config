# modules/home-manager/core.nix
# Base home-manager configuration - reusable across any user
# User-specific settings (username, home directory) belong in home/username/ files

{ ... }:

{
  imports = [
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/fastfetch.nix
  ];

  catppuccin = {
    flavor = "macchiato";
    accent = "blue";
    starship.enable = false;
  };
}
