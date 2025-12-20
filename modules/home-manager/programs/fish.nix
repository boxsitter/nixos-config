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
      ls = "eza -F";
      ll = "eza -lah";
      g = "git";
    };
  };
}
