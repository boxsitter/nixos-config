# modules/home-manager/hyprland/hyprland.nix
# The compositor itself: environment, look and feel, input. Keybinds and window
# rules live in binds.nix and rules.nix; per-host settings (monitors, GPU
# quirks, lid handling) are added from hosts/*/leyton.nix as an extra Lua file.
#
# Hyprland 0.55+ is configured in Lua. Each `extraLuaFiles` entry becomes
# ~/.config/hypr/<name>.lua and is require()d from the generated hyprland.lua in
# name order, so the numeric prefixes below are the load order:
#   10 env · 20 look · 30 input · 40 binds · 50 rules · 90 host overrides
#
# GNOME isolation: everything here is read only by Hyprland, and every user
# service in this tree hangs off hyprland-session.target, which only exists
# while a Hyprland session runs. Nothing is added to graphical-session.target's
# wants, nothing is exported globally.

{ config, ... }:

let
  t = config.theme.lib;
in
{
  # Master scoping switch: Home Manager modules that honour it (swaync, swayosd,
  # hypridle, awww, cliphist, hyprpolkitagent, hyprsunset, ...) rally on
  # hyprland-session.target instead of graphical-session.target.
  wayland.systemd.target = "hyprland-session.target";

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Binary and portal come from the NixOS programs.hyprland module.
    package = null;
    portalPackage = null;

    # Home Manager creates hyprland-session.target and, at compositor start,
    # imports the Wayland environment into systemd/D-Bus and (re)starts the
    # target. The stop-then-start matters: after a compositor crash/restart in
    # the same login, services come back with the new instance's environment
    # instead of a stale HYPRLAND_INSTANCE_SIGNATURE. (Hyprland 0.56 only
    # imports the environment itself; upstream main also starts the target, so a
    # later nixpkgs bump merely makes this hook redundant, not wrong.)
    systemd = {
      enable = true;
      # Besides the defaults, hand the session-scoped theming variables from
      # appearance.nix to services and D-Bus-activated apps, which Hyprland's
      # own `hl.env` does not reach.
      variables = [
        "DISPLAY"
        "HYPRLAND_INSTANCE_SIGNATURE"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "GTK_THEME"
        "XCURSOR_THEME"
        "XCURSOR_SIZE"
        "QT_QPA_PLATFORMTHEME"
        "QT_PLUGIN_PATH"
      ];
    };

    extraLuaFiles = {
      "10-env" = ''
        -- Session-scoped environment: set only inside Hyprland, never globally,
        -- so the GNOME session is unaffected.
        hl.env("NIXOS_OZONE_WL", "1") -- Electron/Chromium: native Wayland
        hl.env("QT_QPA_PLATFORM", "wayland;xcb")
        hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
        hl.env("GDK_BACKEND", "wayland,x11,*")
        hl.env("XDG_SESSION_TYPE", "wayland")
      '';

      "20-look" = ''
        hl.config({
          general = {
            gaps_in = 5,
            gaps_out = 10,
            border_size = 2,
            col = {
              active_border = { colors = { "${t.hyprA "accent" 1}", "${t.hyprA "purple" 1}" }, angle = 45 },
              inactive_border = "${t.hyprA "surfaceAlt" 0.7}",
            },
            resize_on_border = true,
            allow_tearing = false,
            layout = "dwindle",
          },

          decoration = {
            rounding = 12,
            rounding_power = 3,
            active_opacity = 1.0,
            inactive_opacity = 1.0,

            shadow = {
              enabled = true,
              range = 18,
              render_power = 3,
              color = "${t.hyprA "bgDeep" 0.55}",
            },

            -- Behind the scratchpad: darken and blur whatever is underneath.
            dim_special = 0.4,

            blur = {
              special = true,
              enabled = true,
              size = 6,
              passes = 3,
              vibrancy = 0.17,
              noise = 0.015,
              new_optimizations = true,
            },
          },

          dwindle = {
            preserve_split = true,
          },

          misc = {
            -- Never show the stock Hyprland wallpaper/logo; the wallpaper daemon
            -- paints the real one and this is the color underneath until it does.
            force_default_wallpaper = 0,
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            background_color = 0xff${config.theme.colors.bgDeep},
            -- Do not let background apps yank focus.
            focus_on_activate = false,
            mouse_move_enables_dpms = true,
            key_press_enables_dpms = true,
          },

          cursor = {
            hide_on_key_press = true,
            inactive_timeout = 8,
            -- Hyprland would otherwise write the cursor theme into dconf, which
            -- GNOME shares. Keep the two sessions' settings independent.
            sync_gsettings_theme = false,
          },

          ecosystem = {
            no_update_news = true,
            no_donation_nag = true,
          },

          animations = { enabled = true },
        })

        -- Curves and animations: the upstream defaults, with workspaces sliding
        -- (spatial, matches the swipe gesture) instead of fading.
        hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
        hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
        hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
        hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
        hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })
        hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

        hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
        hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
        hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy", style = "popin 90%" })
        hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear", style = "popin 90%" })
        hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
        hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
        hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
        hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
        hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear", style = "fade" })
        hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
        hl.animation({ leaf = "workspaces",    enabled = true, speed = 3,    bezier = "easeOutQuint", style = "slide" })
        -- The scratchpad fades in while the whole workspace grows slightly from
        -- the center of the screen (and the reverse on the way out), instead of
        -- sliding across a very wide monitor.
        hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 95%" })
        hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 95%" })
      '';

      "30-input" = ''
        hl.config({
          input = {
            kb_layout = "us",
            follow_mouse = 1,
            sensitivity = 0,
            repeat_rate = 40,
            repeat_delay = 250,
            numlock_by_default = true,

            touchpad = {
              natural_scroll = true,
              tap_to_click = true,
              disable_while_typing = true,
            },
          },
        })

        -- Three-finger horizontal swipe switches workspaces.
        hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
      '';
    };
  };
}
