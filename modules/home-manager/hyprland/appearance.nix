# modules/home-manager/hyprland/appearance.nix
# Toolkit theming for apps *inside the Hyprland session*: GTK, Qt and the
# cursor, all derived from the same palette as everything else.
#
# GTK: a theme derived from adw-gtk3 (the theme gnome.nix already uses, so every
# widget style is identical) with the palette's colors appended to its
# stylesheets. adw-gtk3 and libadwaita read the same named colors, so GTK3 apps
# and libadwaita/GTK4 apps (Nautilus, ...) both pick it up. It is selected with
# GTK_THEME, which only Hyprland sets.
#
# GNOME isolation: nothing here is global. The settings reach apps through
# `hl.env` (Hyprland's own environment) and config files that are inert unless
# that environment is present. We deliberately avoid the NixOS `qt.*` options,
# Home Manager's `qt.*` and `gtk.theme`, which would change the GNOME session
# too; the shared adw-gtk3 + dark-mode setup from gnome.nix is left alone.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  c = config.theme.colors;
  fonts = config.theme.fonts;

  cursor = {
    name = "Bibata-Modern-Ice";
    size = 24;
    package = pkgs.bibata-cursors;
  };

  qt6ct = pkgs.kdePackages.qt6ct;

  # qt6ct color scheme (21 roles, same order as QPalette without NoRole).
  mkColors = roles: lib.concatMapStringsSep ", " (r: "#ff${r}") roles;

  palette =
    {
      text,
      highlight,
    }:
    mkColors [
      text # WindowText
      c.surface # Button
      c.surfaceHi # Light
      c.surfaceAlt # Midlight
      c.bgDeep # Dark
      c.bgAlt # Mid
      text # Text
      c.fg # BrightText
      text # ButtonText
      c.bgAlt # Base
      c.bg # Window
      c.bgDeep # Shadow
      highlight # Highlight
      c.bgDeep # HighlightedText
      c.blue # Link
      c.purple # LinkVisited
      c.bg # AlternateBase
      c.bgAlt # ToolTipBase
      c.fg # ToolTipText
      c.fgDim # PlaceholderText
      c.accent # Accent
    ];

  colorScheme = pkgs.writeText "hyprland-session.conf" ''
    [ColorScheme]
    active_colors=${palette { text = c.fg; highlight = c.accent; }}
    inactive_colors=${palette { text = c.fg; highlight = c.accent; }}
    disabled_colors=${palette { text = c.fgDim; highlight = c.surfaceAlt; }}
  '';

  # --- GTK -------------------------------------------------------------------
  gtkThemeName = "adw-gtk3-${config.theme.name}";

  rgba = alpha: "rgba(0, 0, 0, ${toString alpha})";

  gtkColors = pkgs.writeText "${gtkThemeName}-colors.css" ''
    /* Generated from the ${config.theme.name} palette. */
    @define-color accent_color #${c.accent};
    @define-color accent_bg_color #${c.accent};
    @define-color accent_fg_color #${c.bgDeep};
    @define-color destructive_color #${c.red};
    @define-color destructive_bg_color #${c.red};
    @define-color destructive_fg_color #${c.bgDeep};
    @define-color success_color #${c.green};
    @define-color success_bg_color #${c.green};
    @define-color success_fg_color #${c.bgDeep};
    @define-color warning_color #${c.yellow};
    @define-color warning_bg_color #${c.yellow};
    @define-color warning_fg_color #${c.bgDeep};
    @define-color error_color #${c.red};
    @define-color error_bg_color #${c.red};
    @define-color error_fg_color #${c.bgDeep};

    @define-color window_bg_color #${c.bg};
    @define-color window_fg_color #${c.fg};
    @define-color view_bg_color #${c.bgAlt};
    @define-color view_fg_color #${c.fg};
    @define-color headerbar_bg_color #${c.bgAlt};
    @define-color headerbar_fg_color #${c.fg};
    @define-color headerbar_border_color #${c.surfaceAlt};
    @define-color headerbar_backdrop_color #${c.bg};
    @define-color headerbar_shade_color ${rgba 0.36};
    @define-color sidebar_bg_color #${c.bgAlt};
    @define-color sidebar_fg_color #${c.fg};
    @define-color sidebar_backdrop_color #${c.bg};
    @define-color sidebar_shade_color ${rgba 0.36};
    @define-color card_bg_color #${c.surface};
    @define-color card_fg_color #${c.fg};
    @define-color card_shade_color ${rgba 0.36};
    @define-color dialog_bg_color #${c.bg};
    @define-color dialog_fg_color #${c.fg};
    @define-color popover_bg_color #${c.surface};
    @define-color popover_fg_color #${c.fg};
    @define-color popover_shade_color ${rgba 0.25};
    @define-color thumbnail_bg_color #${c.surface};
    @define-color thumbnail_fg_color #${c.fg};
    @define-color shade_color ${rgba 0.36};
    @define-color scrollbar_outline_color ${rgba 0.5};
  '';

  gtkTheme =
    pkgs.runCommand gtkThemeName { }
      ''
        dst="$out/share/themes/${gtkThemeName}"
        mkdir -p "$dst"
        cp -rL ${pkgs.adw-gtk3}/share/themes/adw-gtk3/. "$dst/"
        chmod -R u+w "$dst"
        sed -i 's/^Name=.*/Name=${gtkThemeName}/' "$dst/index.theme"
        for f in gtk-3.0/gtk.css gtk-3.0/gtk-dark.css gtk-4.0/gtk.css gtk-4.0/gtk-dark.css; do
          cat ${gtkColors} >> "$dst/$f"
        done
      '';

  # --- Qt --------------------------------------------------------------------
  qtFont = family: "\"${family},11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\"";
in
{
  home.packages = [
    cursor.package
    gtkTheme
    qt6ct
  ];

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${colorScheme}
    custom_palette=true
    icon_theme=Papirus-Dark
    standard_dialogs=default
    style=Fusion

    [Fonts]
    fixed=${qtFont fonts.mono}
    general=${qtFont fonts.ui}

    [Interface]
    activate_item_on_single_click=1
    dialog_buttons_have_icons=1
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    toolbutton_style=4
  '';

  wayland.windowManager.hyprland.extraLuaFiles."12-appearance" = ''
    -- Cursor (XCursor; works for native Wayland and XWayland apps alike).
    hl.env("XCURSOR_THEME", "${cursor.name}")
    hl.env("XCURSOR_SIZE", "${toString cursor.size}")

    -- GTK3 and GTK4/libadwaita: adw-gtk3 recolored with the palette.
    hl.env("GTK_THEME", "${gtkThemeName}:${config.theme.scheme}")

    -- Qt: platform theme plugin from qt6ct, colors from the generated scheme.
    hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
    hl.env("QT_PLUGIN_PATH", "${qt6ct}/lib/qt-6/plugins")
  '';
}
