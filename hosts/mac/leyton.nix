# hosts/mac/leyton.nix
# Home Manager configuration for leyton on macOS

{ ... }:

{
  imports = [
    ../../modules/home-manager/core.nix
  ];

  # Home Manager needs to know about the user
  home = {
    username = "leyton";
    homeDirectory = "/Users/leyton";
    stateVersion = "24.11";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
