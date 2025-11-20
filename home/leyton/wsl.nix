# home/leyton/wsl.nix
# WSL-specific user configuration - minimal, no GUI

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./default.nix  # Import shared config (fish, starship, etc.)
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

  # WSL-specific packages (minimal)
  home.packages = with pkgs; [
    # Add any WSL-specific tools here
  ];
}
