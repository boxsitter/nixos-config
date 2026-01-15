# modules/home-manager/desktop-apps.nix
# Shared desktop applications (not tied to GNOME/Hyprland).
# Keep app *installation* here; avoid managing per-app preferences unless desired.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode   # Editor/IDE (settings are user-managed via VS Code sync)
    insync   # Google Drive sync client
    legcord  # Discord client with better performance on Linux
  ];

  # Auto-start Insync on login with proper environment
  systemd.user.services.insync = {
    Unit = {
      Description = "Insync - Google Drive sync";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.insync}/bin/insync start";
      Restart = "on-failure";
      Environment = [
        "PATH=${pkgs.nautilus}/bin:${pkgs.xdg-utils}/bin"
        "XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
  