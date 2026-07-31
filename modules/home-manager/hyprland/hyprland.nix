# modules/home-manager/hyprland/hyprland.nix
# The Hyprland compositor itself: session scoping, environment, input, and
# keybinds. Per-host settings (monitor layout, GPU env vars) are appended in
# each host's leyton.nix and merge into settings via the module system.

{ pkgs, lib, ... }:

{
  # Master scoping switch. Every home-manager wayland service that follows
  # wayland.systemd.target (waybar, swaync, hypridle, hyprpaper,
  # hyprpolkitagent, cliphist) now rallies on hyprland-session.target, which
  # only exists while a Hyprland session runs. GNOME drives
  # graphical-session.target itself and must not pull these units in.
  wayland.systemd.target = "hyprland-session.target";

  wayland.windowManager.hyprland = {
    enable = true;

    # The compositor binary and its portal come from the NixOS
    # programs.hyprland module; null here avoids installing a second copy.
    package = null;
    portalPackage = null;

    # Creates hyprland-session.target and imports WAYLAND_DISPLAY etc. into the
    # systemd/D-Bus user environment at session start.
    systemd.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";

      # Fallback monitor rule; each host overrides with real connectors.
      monitor = lib.mkDefault [ ",preferred,auto,1" ];

      # Session-scoped only (not a global environment.sessionVariables), so it
      # never touches the GNOME session. Makes Electron/Chromium apps run native
      # Wayland inside Hyprland.
      env = [ "NIXOS_OZONE_WL,1" ];

      input = {
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
      };

      bind = [
        # Core
        "$mod, Return, exec, $terminal"
        "$mod, Space, exec, rofi -show drun"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, E, exec, nautilus"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, L, exec, loginctl lock-session"
        "$mod SHIFT, E, exec, rofi -show power-menu -modi power-menu:rofi-power-menu"

        # Clipboard history picker
        "$mod, C, exec, cliphist list | rofi -dmenu -p clip | cliphist decode | wl-copy"

        # Screenshots (hyprshot)
        ", Print, exec, hyprshot -m region --freeze"
        "SHIFT, Print, exec, hyprshot -m window --freeze"
        "CTRL, Print, exec, hyprshot -m output"

        # Focus movement
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Move windows
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        # Workspaces 1-9,0
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
      ];

      # Mouse drag move/resize.
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Repeatable while held (volume/brightness).
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 5%+"
        ",XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 5%-"
      ];

      # Work even while locked (mute/media keys).
      bindl = [
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
        ",XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
        ",XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
      ];
    };
  };

  home.packages = with pkgs; [
    hyprshot
    rofi-power-menu # `power-menu` modi used by the $mod+SHIFT+E bind
  ];
}
