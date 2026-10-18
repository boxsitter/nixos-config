# modules/home-manager/hyprland/rules.nix
# Window rules (how apps behave) and layer rules (how the shell surfaces look).
# Window rules use the 0.53+ syntax: hl.window_rule({ match = {...}, effect = ... }).

{ ... }:

{
  wayland.windowManager.hyprland.extraLuaFiles."50-rules" = ''
    -- General ---------------------------------------------------------------

    -- Apps asking to maximize themselves is never what you want in a tiler.
    hl.window_rule({
      name = "suppress-maximize",
      match = { class = ".*" },
      suppress_event = "maximize",
    })

    -- Fix drag glitches with some XWayland popups.
    hl.window_rule({
      name = "xwayland-drag-fix",
      match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
      no_focus = true,
    })

    -- Do not lock/sleep while something is fullscreen (video, presentations).
    hl.window_rule({
      name = "idle-inhibit-fullscreen",
      match = { class = ".*" },
      idle_inhibit = "fullscreen",
    })

    -- Slightly translucent terminal so the wallpaper and blur read through.
    hl.window_rule({
      name = "terminal-opacity",
      match = { class = "^kitty$" },
      opacity = "0.94 0.88",
    })

    -- Floating utilities ----------------------------------------------------

    -- Settings-style tools that make no sense tiled.
    hl.window_rule({
      name = "float-utilities",
      match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol|\\.?blueman-manager(-wrapped)?|nm-connection-editor|org\\.gnome\\.Calculator|org\\.gnome\\.Characters|1Password)$" },
      float = true,
      center = true,
      size = "900 640",
    })

    -- Our own TUI popups (btop, nmtui, ...): kitty --class tui-float.
    hl.window_rule({
      name = "float-tui",
      match = { class = "^tui-float$" },
      float = true,
      center = true,
      size = "1000 640",
    })

    -- File pickers and other portal dialogs.
    hl.window_rule({
      name = "float-portal-dialogs",
      match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland|hyprland-share-picker|hyprpolkitagent|org\\.freedesktop\\.impl\\.portal\\.desktop\\..*)$" },
      float = true,
      center = true,
    })

    -- Picture-in-picture: small, floating, on every workspace, bottom right.
    hl.window_rule({
      name = "picture-in-picture",
      match = { title = "^(Picture-in-Picture|Picture in picture)$" },
      float = true,
      pin = true,
      size = "480 270",
      move = "monitor_w-window_w-24 monitor_h-window_h-24",
      no_initial_focus = true,
    })

    -- Layer surfaces: blur the shell ----------------------------------------
    -- ignore_alpha keeps fully transparent regions (outside rounded corners and
    -- between Waybar's islands) from being blurred.
    for _, ns in ipairs({ "waybar", "rofi", "swaync-control-center", "swaync-notification-window" }) do
      hl.layer_rule({
        name = "blur-" .. ns,
        match = { namespace = "^" .. ns .. "$" },
        blur = true,
        blur_popups = true,
        ignore_alpha = 0.2,
      })
    end
    hl.layer_rule({
      name = "blur-swayosd",
      match = { namespace = "^swayosd$" },
      blur = true,
      ignore_alpha = 0.2,
    })
    -- Notifications and the OSD should pop, not slide with the default layer animation.
    hl.layer_rule({
      name = "swaync-animation",
      match = { namespace = "^swaync-notification-window$" },
      animation = "slide right",
    })
    hl.layer_rule({
      name = "osd-no-animation",
      match = { namespace = "^swayosd$" },
      no_anim = true,
    })
  '';
}
