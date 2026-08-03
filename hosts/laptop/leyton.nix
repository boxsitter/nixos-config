# hosts/laptop/leyton.nix
# User configuration for leyton on laptop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/hyprland
  ];

  home.sessionVariables = {
    XCURSOR_SIZE = "14";
  };

  # Laptop-specific overrides
  programs.kitty.font.size = 13;  # Slightly smaller for laptop screen

  # Laptop Hyprland: XPS 15 9530, Intel iGPU + NVIDIA (PRIME offload, RTD3).
  # We deliberately do NOT set AQ_DRM_DEVICES. aquamarine's own device
  # enumeration already picks the right GPU: it skips the NVIDIA card (which
  # advertises no KMS while runtime-suspended) and selects the Intel iGPU. An
  # explicit AQ_DRM_DEVICES is also a trap here — its list separator is ':', and
  # every stable device path (/dev/dri/by-path/pci-0000:00:02.0-card) contains
  # PCI colons, so aquamarine shreds the path into non-existent devices and dies
  # with `CBackend::create() failed!`. Leaving it unset auto-selects Intel and,
  # in the worst case (dGPU awake at login), renders on NVIDIA — never a crash.
  wayland.windowManager.hyprland.settings = {
    # Confirm panel mode/scale with `hyprctl monitors` on first login.
    monitor = [ "eDP-1,preferred,auto,1.5" ];
  };

  # On battery, suspend after deep idle. Merges with the shared lock/dpms
  # listeners from modules/home-manager/hyprland/hypridle.nix.
  services.hypridle.settings.listener = [
    {
      timeout = 1200; # 20 min → suspend
      on-timeout = "systemctl suspend";
    }
  ];
}
