# hosts/laptop/leyton.nix
# User configuration for leyton on laptop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
  ];

  home.sessionVariables = {
    XCURSOR_SIZE = "14";
  };

  # Laptop-specific overrides
  programs.kitty.font.size = 13;  # Slightly smaller for laptop screen
}
