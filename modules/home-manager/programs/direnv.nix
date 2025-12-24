# modules/home-manager/programs/direnv.nix
# Direnv configuration for automatic dev environment activation

{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
