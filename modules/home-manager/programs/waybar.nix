# modules/home-manager/programs/waybar.nix
{ pkgs, ... }:

let
  # Color palette (Symphony Void as default; can be parameterized later)
  colorsCss = ''
    @define-color waybar_accent rgba(187, 154, 247, 0.25);
    @define-color waybar_accent_fg @on_background;
    @define-color on_background #f0dfd8;
    @define-color surface_container #271e1a;
    @define-color error #ffb4ab;
  '';

  # Minimal stubs for yet-unimplemented custom modules (emit empty JSON)
  indicatorRecord = pkgs.writeShellApplication {
    name = "waybar-indicator-record";
    runtimeInputs = [];
    text = ''
      echo "{\"text\": \"\"}"
    '';
  };

  indicatorIdle = pkgs.writeShellApplication {
    name = "waybar-indicator-idle";
    runtimeInputs = [];
    text = ''
      echo "{\"text\": \"\"}"
    '';
  };
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        reload_style_on_change = true;
        layer = "top";
        position = "top";
        spacing = 0;
        height = 28;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "mpris" ];
        modules-right = [
          "memory"
          "disk"
          "custom/screenrecording-indicator"
          "custom/idle-indicator"
          "network"
          "bluetooth"
          "backlight"
          "pulseaudio"
          "battery"
          "clock"
          "tray"
        ];

        "custom/screenrecording-indicator" = {
          "on-click" = "";
          exec = "${indicatorRecord}/bin/waybar-indicator-record";
          signal = 8;
          "return-type" = "json";
        };

        "custom/idle-indicator" = {
          "on-click" = "";
          exec = "${indicatorIdle}/bin/waybar-indicator-idle";
          signal = 9;
          "return-type" = "json";
        };

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

        backlight = {
          format = "{icon}";
          "tooltip-format" = "🌕 {percent}%";
          "format-icons" = [ "󰃜" "󰃝" "󰃞" "󰃟" "󰃠" ];
          "scroll-step" = 10;
        };

        disk = {
          interval = 30;
          format = "󱛟 {percentage_free}%";
          "tooltip-format" = "Used: {used}\nFree: {free}\nTotal: {total}";
          path = "/";
        };

        cpu = {
          interval = 2;
          format = "󰍛 {usage}%";
          "on-click" = "kitty -e btop";
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
          "format-icons" = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          format = "{icon} {essid}";
          "format-wifi" = "{icon}";
          "format-ethernet" = "󰀂";
          "format-disconnected" = "󰤮";
          "tooltip-format-wifi" = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          "tooltip-format-ethernet" = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          "tooltip-format-disconnected" = "Disconnected";
          interval = 3;
          spacing = 1;
          "on-click" = "kitty -e --class=impala impala";
        };

        battery = {
          format = "{icon}";
          "format-discharging" = "{icon} {capacity}%";
          "format-charging" = "{icon}";
          "format-plugged" = "";
          "format-icons" = {
            charging = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
            default = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          };
          "format-full" = "󰂅";
          "tooltip-format-discharging" = "{power:>1.0f}W↓ {capacity}%";
          "tooltip-format-charging" = "{power:>1.0f}W↑ {capacity}%";
          interval = 5;
          states = { warning = 20; critical = 10; };
        };

        bluetooth = {
          format = "";
          "format-disabled" = "󰂲";
          "format-connected" = "";
          "tooltip-format" = "Devices connected: {num_connections}";
          "on-click" = "blueberry";
        };

        pulseaudio = {
          format = "{icon}";
          "on-click" = "kitty --class=Wiremix -e wiremix";
          "on-click-right" = "pamixer -t";
          "tooltip-format" = "🎵 {volume}%";
          "scroll-step" = 5;
          "format-muted" = "";
          "format-icons" = { default = [ "" "" "" ]; };
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
      /* Symphony theme (Waybar) */
      ${colorsCss}

      * {
        background-color: transparent;
        color: @on_background;
        border: none;
        border-radius: 0;
        font-family: 'CaskaydiaMono Nerd Font Propo';
        font-size: 13px;
      }

      tooltip {
        background: rgba(15, 15, 15, 0.95);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 4px;
        padding: 6px 10px;
      }

      menu {
        background: rgba(20, 20, 20, 0.95);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 0px;
        padding: 4px;
      }

      menu menuitem:hover { background: rgba(255, 255, 255, 0.1); }

      window#waybar { background: rgba(16, 16, 16, 0.75); }

      .modules-center { border-radius: 0; padding: 0 80px; }

      #workspaces button {
        all: initial;
        padding: 0 5px;
        margin: 0 0px;
        min-width: 5px;
      }
      #workspaces button.active {
        background: @waybar_accent;
        color: @waybar_accent_fg;
        font-weight: 700;
      }
      #workspaces button.empty { opacity: 0.5; }
      #workspaces button:hover { background: rgba(255, 255, 255, 0.15); border-radius: 0px; }

      #mpd { margin-right: 5px; font-weight: 600; }

      #cpu, #disk, #memory, #battery, #network, #clock, #bluetooth, #pulseaudio, #backlight, #window, #mpris, #tray, #custom-screenrecording-indicator, #custom-idle-indicator {
        padding: 0 5px;
        font-weight: 600;
      }

      #custom-screenrecording-indicator {
        min-width: 12px;
        margin-top: 2px;
        margin-left: 8.75px;
        font-size: 13px;
      }
      #custom-screenrecording-indicator.active { color: #a55555; }

      #custom-logo {
        padding: 0 6px;
        font-size: 15px;
        background: @waybar_accent;
        color: @waybar_accent_fg;
      }
    '';
  };

  home.packages = with pkgs; [
    pamixer
    playerctl
  ];
}
