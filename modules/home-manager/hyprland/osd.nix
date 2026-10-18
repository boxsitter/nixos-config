# modules/home-manager/hyprland/osd.nix
# On-screen display for volume and brightness (the XF86 keys call
# `swayosd-client`, see binds.nix). The server is a user unit that follows
# wayland.systemd.target, so it is Hyprland-only. Caps Lock OSD is skipped: it
# needs a root-run libinput backend, not worth a system service.

{ config, pkgs, ... }:

let
  t = config.theme.lib;
  fonts = config.theme.fonts;
in
{
  services.swayosd = {
    enable = true;
    topMargin = 0.88; # near the bottom of the screen

    stylePath = pkgs.writeText "swayosd.css" ''
      ${t.cssDefines}

      * {
        font-family: "${fonts.ui}", "${fonts.icons}";
      }

      window#osd {
        padding: 12px 22px;
        border-radius: 999px;
        border: 1px solid @surfaceAlt;
        background: ${t.css "bg" 0.92};
      }
      window#osd #container {
        margin: 14px;
      }
      window#osd image,
      window#osd label {
        color: @fg;
      }
      window#osd progressbar:disabled,
      window#osd image:disabled {
        opacity: 0.45;
      }
      window#osd progressbar {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
      }
      window#osd trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: @surfaceAlt;
      }
      window#osd progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: @accent;
      }
    '';
  };
}
