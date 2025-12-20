# modules/home-manager/programs/fastfetch.nix
# Fastfetch system information display configuration

{ ... }:

{
  # Fastfetch configuration file
  xdg.configFile."fastfetch/config.jsonc".source = ../dotfiles/fastfetch-config.jsonc;
}
