# ./modules/hardware/nvidia.nix
# NVIDIA RTX 5080 configuration for desktop

{ config, pkgs, ... }:

{
  # Use latest kernel for best NVIDIA support
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Kernel parameters for NVIDIA RTX 5080 with DP 2.1 support
  boot.kernelParams = [
    "nvidia-drm.modeset=1"           # Enable modesetting
    "nvidia-drm.fbdev=1"             # Enable framebuffer device
    "nvidia.NVreg_EnableGpuFirmware=1"  # Enable GPU firmware loading (required for DP 2.1)
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Better power management
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"  # Temp file location
    "nvidia.NVreg_DynamicPowerManagement=0x00"  # Disable dynamic PM for stability
  ];

  # Blacklist nouveau driver
  boot.blacklistedKernelModules = [ "nouveau" ];
  
  # Set NVIDIA as the video driver
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Graphics configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications and games
  };

  # NVIDIA RTX 5080 configuration
  hardware.nvidia = {
    # Use open-source kernel modules (recommended for RTX 40/50 series)
    # IMPORTANT: Open drivers have better DP 2.1 support
    open = true;
    
    # Required for most Wayland compositors and proper display configuration
    modesetting.enable = true;
    
    # Disable power management for maximum performance (desktop)
    # Power management can interfere with DP 2.1 link training and reduce performance
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    
    # Enable nvidia-settings GUI
    nvidiaSettings = true;
    
    # Use beta/production driver for RTX 5080 support
    # RTX 5000 series requires driver 560+ for proper DP 2.1 UHBR support
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  nixpkgs.config.nvidia.acceptLicense = true;
}
