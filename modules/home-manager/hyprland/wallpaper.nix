# modules/home-manager/hyprland/wallpaper.nix
# Wallpapers with animated transitions (awww). The images are committed under
# resources/wallpapers/<theme> and live in the Nix store; only the *choice* is
# runtime state (see scripts/wallpaper.sh). Pick with Super+W, random with
# Super+Shift+W.
#
# The daemon is a Hyprland-session user service. A oneshot re-applies the saved
# choice at login, and a monitor hotplug does the same (a new output starts
# blank).

{ config, lib, ... }:

let
  wallpaper = lib.getExe config.session.scripts.wallpaper;
in
{
  services.awww.enable = true;

  # The module restarts a crashed daemon only after 10s, which shows as a blank
  # desktop. Come back quickly.
  systemd.user.services.awww.Service.RestartSec = lib.mkForce 2;

  systemd.user.services.wallpaper-restore = {
    Unit = {
      Description = "Apply the saved wallpaper";
      Wants = [ "awww.service" ];
      # Ordered after the session target *explicitly*, like every other unit
      # here. Without it, systemd implicitly orders the target after this unit
      # (it wants it), which closes a cycle through awww.service (itself ordered
      # after the target); systemd then deletes a job to break it, sometimes
      # awww's, and the wallpaper daemon never starts.
      After = [
        "awww.service"
        "hyprland-session.target"
      ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaper} restore";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  wayland.windowManager.hyprland.extraLuaFiles."60-wallpaper" = ''
    -- A newly connected monitor starts blank; give it the saved wallpaper.
    hl.on("monitor.added", function()
      hl.exec_cmd("wallpaper restore")
    end)
  '';
}
