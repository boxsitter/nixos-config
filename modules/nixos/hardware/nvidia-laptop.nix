# ./modules/hardware/nvidia-laptop.nix
# NVIDIA RTX 3050 Mobile configuration for laptop
# Optimized for battery life with power management enabled

{ config, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Required for suspend/resume
    "quiet"         # Suppress most kernel messages
    "splash"        # Enable boot splash (if available)
    "loglevel=3"    # Only show errors and critical messages
    "rd.udev.log_level=3"  # Reduce udev logging
    "vt.global_cursor_default=0"  # Hide blinking cursor
  ];

  boot.blacklistedKernelModules = [ "nouveau" "spd5118" ];  # Blacklist nouveau and DDR5 temp sensor
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = false;  # Proprietary is more stable for RTX 30 mobile
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    
    # PRIME offload (hybrid graphics): Intel drives the desktop; NVIDIA powers
    # up only for offloaded apps. This is typically the most power-efficient.
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  nixpkgs.config.nvidia.acceptLicense = true;
}
