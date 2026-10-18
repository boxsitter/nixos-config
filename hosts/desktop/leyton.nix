# hosts/desktop/leyton.nix
# User configuration for leyton on desktop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/hyprland
  ];

  # Desktop Hyprland: RTX 5080, single all-NVIDIA render path (no iGPU). Loaded
  # last, after the shared modules (see hyprland.nix).
  wayland.windowManager.hyprland.extraLuaFiles."90-host" = ''
    -- Placeholder until confirmed with `hyprctl monitors`: scale 1.5 suits a 4K
    -- panel. Set the real connector/refresh rate after the first login.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.5 })

    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")

    hl.config({
      -- Software cursor sidesteps the NVIDIA cursor glitches; try removing this
      -- once the session has proven stable.
      cursor = { no_hardware_cursors = true },
      -- Same flat pointer acceleration the GNOME session uses on this machine.
      input = { accel_profile = "flat", sensitivity = 0 },
    })
  '';

  dconf.settings = {
    # "org/gnome/desktop/interface" = {
    #   text-scaling-factor = 1.5;
    # };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      speed = 0.0;
    };
  };

  home.sessionVariables = {
    XCURSOR_SIZE = "24";
  };
}
