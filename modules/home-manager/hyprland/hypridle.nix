# modules/home-manager/hyprland/hypridle.nix
# Idle management: lock after inactivity, then blank the screen. Suspend is not
# handled here — the laptop host appends its own suspend listener in
# hosts/laptop/leyton.nix, while the desktop deliberately never suspends.
#
# lock_cmd guards against multiple hyprlock instances; loginctl lock-session
# (bound to $mod+L and used by before_sleep_cmd) routes through the same path.

{ pkgs, ... }:

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300; # 5 min → lock
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600; # 10 min → screen off
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
