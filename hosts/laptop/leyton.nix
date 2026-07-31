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

  # Laptop Hyprland: XPS 15 9530 with NVIDIA PRIME offload. Hyprland must render
  # on the Intel iGPU (primary) so the dGPU can stay runtime-suspended (RTD3).
  wayland.windowManager.hyprland.settings = {
    # Confirm panel mode/scale with `hyprctl monitors` on first login.
    monitor = [ "eDP-1,preferred,auto,1.5" ];

    # Order render devices iGPU-first. by-path names are stable across boots
    # (unlike /dev/dri/cardN); the bus IDs match hardware/nvidia-laptop.nix
    # (intelBusId PCI:0:2:0, nvidiaBusId PCI:1:0:0).
    env = [
      "AQ_DRM_DEVICES,/dev/dri/by-path/pci-0000:00:02.0-card:/dev/dri/by-path/pci-0000:01:00.0-card"
    ];
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
