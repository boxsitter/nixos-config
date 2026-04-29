# modules/home-manager/desktop.nix
# Desktop/laptop GUI configuration
# Adds GUI programs to core config

{ ... }:

{
  imports = [
    ./gnome.nix
    ./programs/kitty.nix
  ];
}
