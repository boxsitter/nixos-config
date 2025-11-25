# home/leyton/wsl.nix
# WSL-specific user configuration (no GUI)

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home-manager/common.nix
    # No shell.nix - WSL uses Windows terminal
    # No hyprland.nix - WSL has no GUI
  ];

  home.username = "leyton";
  home.homeDirectory = "/home/leyton";

  # Always start in home directory when WSL launches
  programs.fish.loginShellInit = ''
    if test "$PWD" != "$HOME"
      cd ~
    end
  '';

  # VS Code via Windows (Remote-WSL)
  programs.fish.shellAliases = {
    code = "/mnt/c/Users/leyton/AppData/Local/Programs/'Microsoft VS Code'/bin/code";
  };

  # WSL-specific packages (minimal)
  home.packages = with pkgs; [
    # Add any WSL-specific tools here
  ];
}
