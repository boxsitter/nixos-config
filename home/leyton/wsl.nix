# home/leyton/wsl.nix
# WSL-specific user configuration (no GUI)

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home-manager/common.nix
    # No shell.nix - WSL uses Windows terminal
    # No hyprland.nix - WSL has no GUI
  ];

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

  # WSL packages moved to system-level common.nix
}
