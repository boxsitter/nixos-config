# modules/home-manager/programs/fish.nix
# Fish shell configuration

{ ... }:

{
  programs.fish = {
    enable = true;
    shellInit = ''
      starship init fish | source
      set fish_greeting ""
      fastfetch
    '';
    shellAliases = {
      # Modern replacements for core utilities
      ls = "eza";
      ll = "eza -lah";
      la = "eza -a";
      lt = "eza --tree";
      tree = "eza --tree";
      cat = "bat";
      grep = "rg";
      find = "fd";
      top = "btop";
      htop = "btop";
    };
  };
}
