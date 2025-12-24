# modules/home-manager/programs/swaync.nix
# Sway Notification Center (swaync) for notifications + control center.
# Nix-native: config values based on Symphony; styling kept minimal for now.

{ pkgs, ... }:

{
  home.packages = [ pkgs.swaynotificationcenter ];

  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    "ignore-gtk-theme" = true;
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    "control-center-layer" = "top";
    "layer-shell" = true;
    "layer-shell-cover-screen" = true;
    "cssPriority" = "user";
    "control-center-margin-top" = 7;
    "control-center-margin-bottom" = 0;
    "control-center-margin-right" = 7;
    "control-center-margin-left" = 0;
    "notification-2fa-action" = true;
    "notification-inline-replies" = false;
    "notification-body-image-height" = 100;
    "notification-body-image-width" = 500;
    timeout = 10;
    "timeout-low" = 5;
    "timeout-critical" = 0;
    "fit-to-screen" = false;
    "relative-timestamps" = true;
    "control-center-width" = 350;
    "control-center-height" = 800;
    "notification-window-width" = 350;
    "keyboard-shortcuts" = true;
    "notification-grouping" = true;
    "image-visibility" = "when-available";
    "transition-time" = 200;
    "hide-on-clear" = false;
    "hide-on-action" = true;
    "text-empty" = "No Notifications";
    "script-fail-notify" = true;
    widgets = [ "mpris" "dnd" "title" "notifications" ];
    "widget-config" = {
      notifications.vexpand = true;
      title = {
        text = "Notifications";
        "clear-all-button" = true;
        "button-text" = "Clear All";
      };
      dnd.text = "";
      mpris = {
        blacklist = [ ];
        autohide = false;
        "show-album-art" = "always";
        "loop-carousel" = false;
      };
    };
  };

  # Minimal style, leaving full Symphony CSS for later.
  xdg.configFile."swaync/style.css".text = ''
    * {
      font-family: FiraCode Nerd Font;
    }
  '';
}
