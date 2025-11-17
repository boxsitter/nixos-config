# home/leyton/wsl.nix
# WSL-specific user configuration - minimal, no GUI

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./default.nix  # Import shared config (fish, starship, etc.)
  ];

  # Override the code function for WSL to use Windows VSCode
  programs.fish.functions.code = {
    description = "VS Code via Windows";
    body = "/mnt/c/Users/leyto/AppData/Local/Programs/Microsoft\\ VS\\ Code/bin/code $argv";
  };

  # WSL-specific packages (minimal)
  home.packages = with pkgs; [
    # Add any WSL-specific tools here
  ];
}
