# home/leyton/laptop.nix
# Laptop-specific user configuration

{ ... }:

{
  imports = [
    ../../modules/home/common.nix
  ];

  # Laptop-specific overrides
  programs.kitty.font.size = 13;  # Slightly smaller for laptop screen
}
