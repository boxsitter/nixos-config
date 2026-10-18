# modules/home-manager/hyprland/lock.nix
# Lock screen (hyprlock) and idle policy (hypridle).
#
# hyprlock authenticates through the PAM service registered in the NixOS module
# (security.pam.services.hyprlock); without it the lock screen cannot unlock.
# Its background is the current wallpaper, blurred, via the symlink the
# `wallpaper` command maintains.
#
# Idle: dim at 4 min, lock at 5, screen off at 10. Suspend is added per host
# (hosts/laptop/leyton.nix); the desktop never suspends. Anything fullscreen
# (video) or holding an idle inhibitor (the bar's coffee toggle, browsers
# playing media) keeps the session awake.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  t = config.theme.lib;
  fonts = config.theme.fonts;

  hyprlock = lib.getExe pkgs.hyprlock;
  hyprctl = lib.getExe' pkgs.hyprland "hyprctl";
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;

  dpms = action: "${hyprctl} dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = "${config.home.homeDirectory}/.local/state/wallpaper/current";
          color = t.hypr "bgDeep";
          blur_passes = 3;
          blur_size = 7;
          brightness = 0.55;
          vibrancy = 0.15;
          noise = 0.012;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_family = fonts.ui;
          font_size = 108;
          color = t.hypr "fg";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%A, %B %-d"'';
          font_family = fonts.ui;
          font_size = 20;
          color = t.hypr "fgMuted";
          position = "0, 60";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "320, 54";
          position = "0, -60";
          halign = "center";
          valign = "center";
          rounding = -1;
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.35;
          dots_center = true;
          fade_on_empty = false;
          hide_input = false;
          font_family = fonts.ui;
          font_color = t.hypr "fg";
          inner_color = t.hyprA "bg" 0.85;
          outer_color = t.hypr "accent";
          check_color = t.hypr "yellow";
          fail_color = t.hypr "red";
          capslock_color = t.hypr "orange";
          placeholder_text = ''<span foreground="##${config.theme.colors.fgDim}">Password</span>'';
          fail_text = "<i>$FAIL</i>";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${hyprlock}";
        before_sleep_cmd = "${loginctl} lock-session";
        after_sleep_cmd = dpms "enable";
      };

      listener = [
        {
          timeout = 240;
          on-timeout = "${brightnessctl} --save set 15%";
          on-resume = "${brightnessctl} --restore";
        }
        {
          timeout = 300;
          on-timeout = "${loginctl} lock-session";
        }
        {
          timeout = 600;
          on-timeout = dpms "disable";
          on-resume = "${dpms "enable"} && ${brightnessctl} --restore";
        }
      ];
    };
  };
}
