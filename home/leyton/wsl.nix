# home/leyton/wsl.nix
# WSL-specific user configuration - minimal, no GUI

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./default.nix  # Import shared config (fish, starship, etc.)
  ];

  # Add VS Code server bin to PATH for 'code' command
  home.sessionPath = [
    "$HOME/.vscode-server/bin/*/bin"
  ];

  # Fallback: VS Code via Windows if server not available
  programs.fish.functions.code = {
    description = "VS Code (prefers WSL server, falls back to Windows)";
    body = ''
      if test -d ~/.vscode-server/bin
        set vscode_bin (find ~/.vscode-server/bin -name 'code' -type f 2>/dev/null | head -n 1)
        if test -n "$vscode_bin"
          $vscode_bin $argv
          return
        end
      end
      # Fallback to Windows VS Code
      /mnt/c/Users/leyto/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code $argv
    '';
  };

  # WSL-specific packages (minimal)
  home.packages = with pkgs; [
    # Add any WSL-specific tools here
  ];
}
