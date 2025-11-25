# modules/home-manager/common.nix
# Shared user configuration across all systems

{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  # Catppuccin theme - base configuration
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    accent = "mauve";
  };

  home.stateVersion = "24.11";

  # Fish shell - basic setup
  programs.fish = {
    enable = true;
    shellInit = ''
      starship init fish | source
      set fish_greeting ""
      fastfetch
    '';
    shellAliases = {
      ls = "eza -F";
      ll = "eza -lah";
      g = "git";
    };
  };

  # Direnv for automatic Nix shell activation
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      container.disabled = true;
      python.disabled = true;
    };
  };

  # Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "leyton.houck@gmail.com";
        name = "boxsitter";
      };
      core = {
        autocrlf = "input";  # Convert CRLF to LF on commit, keep LF on checkout
        eol = "lf";          # Always use LF in the working directory
      };
    };
  };

  # Fastfetch configuration
  xdg.configFile."fastfetch/config.jsonc".source = ../../home/leyton/dotfiles/fastfetch-config.jsonc;
}
