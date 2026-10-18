# modules/home-manager/hyprland/notifications.nix
# SwayNotificationCenter: popups plus a slide-in center (Super+N) with history,
# Do Not Disturb, media controls and volume/brightness sliders, the closest
# thing to GNOME's quick settings panel. The unit follows wayland.systemd.target,
# so it only runs inside Hyprland and never fights gnome-shell for
# org.freedesktop.Notifications.

{ config, ... }:

let
  t = config.theme.lib;
  fonts = config.theme.fonts;
in
{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "user";

      control-center-width = 400;
      control-center-margin-top = 8;
      control-center-margin-right = 10;
      control-center-margin-bottom = 10;
      control-center-margin-left = 0;

      notification-window-width = 400;
      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      image-visibility = "when-available";
      transition-time = 150;
      hide-on-clear = true;
      hide-on-action = true;
      fit-to-screen = false;
      keyboard-shortcuts = true;

      timeout = 8;
      timeout-low = 4;
      timeout-critical = 0;

      widgets = [
        "title"
        "dnd"
        "mpris"
        "volume"
        "backlight"
        "notifications"
      ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear";
        };
        dnd.text = "Do Not Disturb";
        mpris = {
          image-size = 64;
          image-radius = 10;
          autohide = true; # no empty player card when nothing is playing
        };
        volume.label = "Volume";
        backlight.label = "Brightness";
      };
    };

    style = ''
      ${t.cssDefines}

      * {
        font-family: "${fonts.ui}", "${fonts.icons}";
        font-size: 13px;
      }

      /* Popups ------------------------------------------------------------ */
      .floating-notifications.background {
        background: transparent;
      }
      .notification-row {
        outline: none;
        background: transparent;
      }
      .notification-row .notification-background {
        padding: 6px 10px;
        background: transparent;
      }
      .notification-row .notification-background .notification {
        background: ${t.css "bg" 0.97};
        border: 1px solid @surfaceAlt;
        border-radius: 14px;
        padding: 0;
        box-shadow: none;
      }
      .notification-row .notification-background .notification.critical {
        border-color: @red;
      }
      .notification-content {
        background: transparent;
        padding: 10px 12px;
      }
      .notification .summary {
        color: @fg;
        font-weight: 700;
      }
      .notification .time {
        color: @fgDim;
      }
      .notification .body {
        color: @fgMuted;
      }
      /* The whole card is a button; keep the theme's button look out of it. */
      .notification-default-action,
      .notification-default-action:hover {
        background: transparent;
        border: none;
        box-shadow: none;
        border-radius: 14px;
      }
      .notification-default-action:hover {
        background: ${t.css "surface" 0.5};
      }
      .notification-action {
        border-top: 1px solid @surfaceAlt;
        border-radius: 0;
        background: transparent;
        color: @fg;
      }
      .notification-action:hover {
        background: @surface;
      }
      .close-button {
        background: @surface;
        color: @fg;
        border-radius: 99px;
        margin: 8px;
        padding: 0;
        min-width: 22px;
        min-height: 22px;
      }
      .close-button:hover {
        background: @red;
        color: @bgDeep;
      }

      /* Control center ---------------------------------------------------- */
      .control-center {
        background: ${t.css "bg" 0.97};
        border: 1px solid @surfaceAlt;
        border-radius: 16px;
      }
      .control-center .notification-row .notification-background {
        padding: 4px 8px;
      }
      .control-center .notification-row .notification-background .notification {
        background: @surface;
        border: none;
      }
      .control-center-list-placeholder {
        color: @fgDim;
      }
      /* List rows come with the GTK theme's row background; the cards inside
         are what should be visible. */
      .control-center list,
      .control-center row,
      .control-center viewport,
      .control-center scrolledwindow,
      .control-center .notification-group,
      .control-center .notification-row {
        background: transparent;
        border: none;
        box-shadow: none;
      }

      .widget-title {
        margin: 14px 16px 6px;
        font-size: 15px;
        font-weight: 700;
        color: @fg;
      }
      .widget-title > button {
        background: @surface;
        color: @fg;
        border-radius: 10px;
        padding: 4px 12px;
      }
      .widget-title > button:hover {
        background: @surfaceAlt;
      }

      .widget-dnd {
        margin: 6px 16px;
        color: @fg;
      }
      .widget-dnd > switch {
        background: @surface;
        border-radius: 99px;
      }
      .widget-dnd > switch:checked {
        background: @accent;
      }
      .widget-dnd > switch slider {
        background: @fg;
        border-radius: 99px;
      }

      .widget-mpris {
        margin: 6px 16px;
        padding: 6px;
        background: @surface;
        border-radius: 12px;
        color: @fg;
      }
      .widget-mpris button {
        color: @fg;
        border-radius: 99px;
      }
      .widget-mpris button:hover {
        background: @surfaceAlt;
      }

      .widget-volume,
      .widget-backlight {
        margin: 6px 16px;
        padding: 8px 14px;
        background: @surface;
        border-radius: 12px;
        color: @fg;
      }
      .widget-volume trough,
      .widget-backlight trough {
        background: @surfaceAlt;
        border-radius: 99px;
        min-height: 6px;
      }
      .widget-volume highlight,
      .widget-backlight highlight {
        background: @accent;
        border-radius: 99px;
      }
      .widget-volume slider,
      .widget-backlight slider {
        background: @accent;
        border-radius: 99px;
        min-width: 14px;
        min-height: 14px;
        margin: -4px;
      }
    '';
  };
}
