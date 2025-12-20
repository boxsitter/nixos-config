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
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];
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
    
    # PRIME configuration - uncomment and set bus IDs for hybrid graphics
    # Find bus IDs with: lspci | grep -E "VGA|3D"
    # prime = {
    #   intelBusId = "PCI:0:2:0";
    #   nvidiaBusId = "PCI:1:0:0";
    #   offload = {
    #     enable = true;
    #     enableOffloadCmd = true;
    #   };
    # };
  };

  nixpkgs.config.nvidia.acceptLicense = true;
}
