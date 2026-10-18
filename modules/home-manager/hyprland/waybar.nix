# modules/home-manager/hyprland/waybar.nix
# Status bar: three floating islands (workspaces + window | clock | status), all
# colors from the palette. Runs as a systemd user service bound to the Hyprland
# session only (see the unit overrides at the bottom).
#
# Commands use absolute store paths because Waybar is a systemd unit and should
# not depend on the PATH it happens to inherit.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  t = config.theme.lib;
  fonts = config.theme.fonts;
  scripts = config.session.scripts;

  kitty = lib.getExe pkgs.kitty;
  tui = title: cmd: "${kitty} --class tui-float --title ${title} -e ${cmd}";
  swayncClient = lib.getExe' pkgs.swaynotificationcenter "swaync-client";
  swayosdClient = lib.getExe' pkgs.swayosd "swayosd-client";

  calendarSpan = color: text: "<span color='#${color}'>${text}</span>";
  c = config.theme.colors;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      margin-top = 8;
      margin-left = 10;
      margin-right = 10;
      spacing = 0;

      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "tray"
        "idle_inhibitor"
        "group/status"
        "custom/notification"
        "custom/power"
      ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-click = "activate";
        persistent-workspaces."*" = 5;
        show-special = false;
      };

      "hyprland/window" = {
        format = "{title}";
        max-length = 48;
        separate-outputs = true;
      };

      clock = {
        format = "{:%a %d %b   %H:%M}";
        format-alt = "{:%Y-%m-%d   %H:%M:%S}";
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          on-scroll = 1;
          format = {
            months = calendarSpan c.accent "<b>{}</b>";
            days = calendarSpan c.fgMuted "{}";
            weekdays = calendarSpan c.fgDim "<b>{}</b>";
            today = calendarSpan c.accent "<b><u>{}</u></b>";
          };
        };
      };

      tray = {
        icon-size = 16;
        spacing = 10;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰒲";
        };
        tooltip-format-activated = "Staying awake (idle lock disabled)";
        tooltip-format-deactivated = "Idle lock enabled";
      };

      "group/status" = {
        orientation = "horizontal";
        modules = [
          "pulseaudio"
          "network"
          "bluetooth"
          "battery"
        ];
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = {
          default = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          headphone = "󰋋";
        };
        scroll-step = 5;
        tooltip-format = "{desc}";
        on-click = lib.getExe pkgs.pavucontrol;
        on-click-right = "${swayosdClient} --output-volume mute-toggle";
      };

      network = {
        format-wifi = "󰖩";
        format-ethernet = "󰈀";
        format-disconnected = "󰤭";
        tooltip-format-wifi = "{essid}  ·  {signalStrength}%  ·  {ipaddr}";
        tooltip-format-ethernet = "{ifname}  ·  {ipaddr}";
        tooltip-format-disconnected = "Not connected";
        on-click = tui "network" "nmtui";
        on-click-right = lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯";
        format-off = "󰂲";
        format-disabled = "󰂲";
        format-connected = "󰂱 {num_connections}";
        tooltip-format = "{status}";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click = lib.getExe' pkgs.blueman "blueman-manager";
      };

      battery = {
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-full = "󰁹";
        format-icons = [
          "󰂎"
          "󰁺"
          "󰁻"
          "󰁼"
          "󰁽"
          "󰁾"
          "󰁿"
          "󰂀"
          "󰂁"
          "󰂂"
        ];
        states = {
          warning = 30;
          critical = 15;
        };
        tooltip-format = "{timeTo}";
      };

      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "󱅫";
          none = "󰂚";
          dnd-notification = "󰭕";
          dnd-none = "󰂛";
          inhibited-notification = "󱅫";
          inhibited-none = "󰂚";
          dnd-inhibited-notification = "󰭕";
          dnd-inhibited-none = "󰂛";
        };
        return-type = "json";
        exec = "${swayncClient} -swb";
        on-click = "${swayncClient} -t -sw";
        on-click-right = "${swayncClient} -d -sw";
        escape = true;
      };

      "custom/power" = {
        format = "󰐥";
        tooltip = false;
        on-click = lib.getExe scripts.power-menu;
      };
    };

    style = ''
      ${t.cssDefines}

      * {
        font-family: "${fonts.ui}", "${fonts.icons}";
        font-size: 13px;
        font-weight: 500;
        min-height: 0;
        border: none;
        border-radius: 0;
        box-shadow: none;
        text-shadow: none;
      }

      window#waybar {
        background: transparent;
        color: @fg;
      }

      tooltip {
        background: ${t.css "bgAlt" 0.96};
        border: 1px solid @surfaceAlt;
        border-radius: 10px;
      }
      tooltip label {
        color: @fg;
        padding: 2px 4px;
      }

      /* Every top-level module is a pill floating over the wallpaper. */
      #workspaces,
      #clock,
      #tray,
      #idle_inhibitor,
      #status,
      #custom-notification,
      #custom-power {
        background: ${t.css "bg" 0.82};
        border-radius: 14px;
        margin: 0 3px;
        padding: 0 12px;
      }

      /* Workspaces */
      #workspaces {
        padding: 0 4px;
      }
      #workspaces button {
        padding: 0 9px;
        margin: 4px 2px;
        border-radius: 10px;
        background: transparent;
        color: @fgDim;
        transition: background 150ms ease, color 150ms ease;
      }
      #workspaces button:hover {
        background: @surface;
        color: @fg;
      }
      #workspaces button.active {
        background: @accent;
        color: @bgDeep;
        font-weight: 700;
      }
      #workspaces button.urgent {
        background: @red;
        color: @bgDeep;
      }

      /* Focused window title: plain text, no pill. */
      #window {
        color: @fgMuted;
        padding: 0 10px;
      }
      window#waybar.empty #window {
        padding: 0;
      }

      #clock {
        font-weight: 600;
      }

      /* Status group: one pill, tight spacing inside. */
      #status {
        padding: 0 6px;
      }
      #pulseaudio,
      #network,
      #bluetooth,
      #battery {
        padding: 0 8px;
        background: transparent;
      }
      #pulseaudio.muted,
      #network.disconnected,
      #bluetooth.off,
      #bluetooth.disabled {
        color: @fgDim;
      }
      #battery.charging,
      #battery.plugged {
        color: @green;
      }
      #battery.warning:not(.charging) {
        color: @yellow;
      }
      #battery.critical:not(.charging) {
        color: @red;
      }

      #idle_inhibitor {
        color: @fgDim;
      }
      #idle_inhibitor.activated {
        color: @yellow;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      #custom-notification {
        color: @fgMuted;
      }
      #custom-power {
        color: @red;
      }
    '';
  };

  # Waybar's own unit is WantedBy tray.target as well as the session target.
  # tray.target is pulled in by tray-hosting services, so keep Waybar strictly on
  # the Hyprland target; it must never start inside GNOME.
  systemd.user.services.waybar = {
    Unit.PartOf = lib.mkForce [ "hyprland-session.target" ];
    Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  };
}
