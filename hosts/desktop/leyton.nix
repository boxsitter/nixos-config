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

  # Desktop Hyprland: RTX 5080, single all-NVIDIA render path (no iGPU).
  wayland.windowManager.hyprland.settings = {
    # Placeholder until confirmed with `hyprctl monitors`; ",preferred,auto,1.5"
    # is a safe default for a 4K display. Adjust connector/refresh after first login.
    monitor = [ ",preferred,auto,1.5" ];

    env = [
      "LIBVA_DRIVER_NAME,nvidia"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "NVD_BACKEND,direct"
    ];

    # Start safe on NVIDIA; software cursors avoid the well-known cursor
    # disappearing/flicker. Trial-remove once explicit sync is confirmed stable.
    cursor.no_hardware_cursors = true;

    # Crisp XWayland apps under fractional scaling.
    xwayland.force_zero_scaling = true;
  };

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
