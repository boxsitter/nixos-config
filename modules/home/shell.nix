# modules/home-manager/shell.nix
# Terminal and shell configuration for GUI systems

{ config, pkgs, inputs, ... }:

{
  # Catppuccin theme for terminal apps
  catppuccin = {
    kitty.enable = true;
  };

  # Kitty terminal with Catppuccin theme
  programs.kitty = {
    enable = true;
    font = {
      name = "0xProto Nerd Font";
      size = 14;
    };
    settings = {
      background_opacity = "0.9";
      cursor_shape = "beam";
    };
  };
}
