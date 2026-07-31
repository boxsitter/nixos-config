# modules/home-manager/hyprland/waybar.nix
# Status bar for the Hyprland session. Phase 1: functional module layout with
# Waybar's stock styling. Phase 2 adds a themed `style` from the theme module.

{ ... }:

{
  programs.waybar = {
    enable = true;

    # systemd.targets defaults to [ config.wayland.systemd.target ] =
    # hyprland-session.target, so the bar only runs inside Hyprland.
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;

      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "tray"
        "pulseaudio"
        "network"
        "bluetooth"
        "battery"
        "cpu"
        "temperature"
      ];

      "hyprland/workspaces".on-click = "activate";

      "hyprland/window".max-length = 60;

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<tt><big>{calendar}</big></tt>";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 muted";
        format-icons.default = [
          "󰕿"
          "󰖀"
          "󰕾"
        ];
        on-click = "pavucontrol";
      };

      network = {
        format-wifi = "󰤨 {essid}";
        format-ethernet = "󰈀 {ipaddr}";
        format-disconnected = "󰤭 offline";
        tooltip-format = "{ifname}: {ipaddr}";
      };

      bluetooth = {
        format = "󰂯";
        format-disabled = "󰂲";
        format-connected = "󰂱 {num_connections}";
        on-click = "blueman-manager";
      };

      battery = {
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = [
          "󰁺"
          "󰁻"
          "󰁽"
          "󰁿"
          "󰂁"
          "󰁹"
        ];
        states = {
          warning = 30;
          critical = 15;
        };
      };

      cpu.format = "󰻠 {usage}%";
      temperature.format = "{temperatureC}°C";

      tray.spacing = 10;
    };
  };
}
