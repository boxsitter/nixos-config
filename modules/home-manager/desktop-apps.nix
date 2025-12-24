# modules/home-manager/desktop-apps.nix
# Shared desktop applications (not tied to GNOME/Hyprland).
# Keep app *installation* here; avoid managing per-app preferences unless desired.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode   # Editor/IDE (settings are user-managed via VS Code sync)
  ];
}
