# modules/home-manager/hyprland/hyprlock.nix
# Lock screen. The PAM service that authenticates unlocks is provided by the
# NixOS module (programs.hyprlock.enable in services/hyprland.nix); this only
# supplies the user-side config. Phase 1 is a clean default; Phase 2 styles it
# from the palette and blurs the wallpaper.

{ ... }:

{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 2;
      };

      background = [
        {
          monitor = "";
          color = "rgb(30, 32, 48)"; # macchiato mantle; replaced by wallpaper in Phase 2
          blur_passes = 2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 55";
          position = "0, -80";
          halign = "center";
          valign = "center";
          outline_thickness = 2;
          placeholder_text = "Password...";
          fade_on_empty = false;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 90;
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
