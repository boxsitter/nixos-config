# modules/home-manager/hyprland/notifications.nix
# SwayNotificationCenter: notification daemon + control center with history and
# DND, the closest match to GNOME's notification UX. The unit follows
# wayland.systemd.target, so it only runs inside Hyprland and never contends
# with gnome-shell for org.freedesktop.Notifications. Phase 2 adds themed CSS
# via `style`.

{ ... }:

{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 380;
      notification-icon-size = 48;
      notification-window-width = 400;
      timeout = 8;
      timeout-low = 4;
      timeout-critical = 0;
    };
  };
}
