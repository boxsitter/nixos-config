# modules/home-manager/core.nix
# Base home-manager configuration - reusable across any user
# User-specific settings (username, home directory) belong in home/username/ files

{ ... }:

{
  imports = [
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/direnv.nix
    ./programs/starship.nix
    ./programs/fastfetch.nix
  ];
}
