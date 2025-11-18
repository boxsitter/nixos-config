# home/leyton/default.nix
# Minimal shared user configuration

{ config, pkgs, ... }:

{
  home.stateVersion = "24.11";
  home.username = "leyton";
  home.homeDirectory = "/home/leyton";

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
    userName = "Leyton Houck";
    userEmail = "leyton@example.com";
  };

  # Basic packages
  home.packages = with pkgs; [
    eza
    fastfetch
  ];

  # Fastfetch configuration
  xdg.configFile."fastfetch/config.jsonc".source = ./dotfiles/fastfetch-config.jsonc;
}
