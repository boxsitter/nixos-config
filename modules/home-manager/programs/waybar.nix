# modules/home-manager/programs/waybar.nix
# Waybar status bar.
# Nix-native: base config inspired by Symphony; custom script hooks deferred.

{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 28;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "mpris" ];
        modules-right = [
          "memory"
          "disk"
          "network"
          "bluetooth"
          "backlight"
          "pulseaudio"
          "battery"
          "clock"
          "tray"
        ];

        "hyprland/workspaces" = {
          "on-click" = "activate";
          format = "{icon}";
          "format-icons" = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
            default = "";
          };
        };

        disk = {
          interval = 30;
          format = "󱛟 {percentage_free}%";
          "tooltip-format" = "Used: {used}\nFree: {free}\nTotal: {total}";
          path = "/";
        };

        memory = {
          format = " {used:0.1f}gb";
          interval = 2;
          "on-click" = "kitty -e btop";
        };

        clock = {
          format = "{:L%H:%M}";
          "format-alt" = "{:L%A %d %B}";
          tooltip = false;
        };

        network = {
          interface = "wlan*";
          "format" = "{icon} {essid}";
          "format-wifi" = "{icon}";
          "format-ethernet" = "󰀂";
          "format-disconnected" = "󰤮";
          interval = 3;
        };

        bluetooth = {
          format = "";
          "format-disabled" = "󰂲";
          "format-connected" = "";
          "tooltip-format" = "Devices connected: {num_connections}";
        };

        pulseaudio = {
          format = "{icon}";
          "tooltip-format" = "🎵 {volume}%";
          "scroll-step" = 5;
          "format-muted" = "";
          "format-icons" = {
            default = [ "" "" "" ];
          };
          "on-click-right" = "pamixer -t";
        };

        tray = {
          "icon-size" = 13;
          spacing = 4;
        };

        mpris = {
          format = "{player_icon} {artist}{title}";
          "format-paused" = "{status_icon} {artist} - {title}</i>";
          "status-icons" = { paused = "⏸"; };
          "max-length" = 70;
        };
      };
    };

    style = ''
      * {
        font-family: FiraCode Nerd Font;
      }
    '';
  };

  home.packages = with pkgs; [
    pamixer
    playerctl
  ];
}
