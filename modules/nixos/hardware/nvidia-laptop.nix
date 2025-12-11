# ./modules/hardware/nvidia-laptop.nix
# NVIDIA RTX 3050 Mobile configuration for laptop
# Optimized for battery life with power management enabled

{ config, pkgs, ... }:

{
  # Use latest kernel for best NVIDIA support
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Kernel parameters for NVIDIA RTX 3050 Mobile
  boot.kernelParams = [
    "nvidia-drm.modeset=1"           # Enable modesetting
    "nvidia-drm.fbdev=1"             # Enable framebuffer device
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Required for suspend/resume
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

  # NVIDIA RTX 3050 Mobile configuration
  hardware.nvidia = {
    # Use proprietary drivers for RTX 30 series mobile (better power management)
    # Open drivers are recommended for 40/50 series, but proprietary is more stable for 30 series mobile
    open = false;
    
    # Required for Wayland compositors
    modesetting.enable = true;
    
    # Enable power management for battery life
    powerManagement.enable = true;
    
    # Fine-grained power management (allows GPU to fully power down when not in use)
    powerManagement.finegrained = true;
    
    # Enable nvidia-settings GUI
    nvidiaSettings = true;
    
    # Use stable driver for RTX 3050 Mobile
    # RTX 30 series has excellent support in stable drivers
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    
    # PRIME configuration for laptops with hybrid graphics (Intel + NVIDIA)
    # Uncomment and configure if you have Intel integrated graphics
    # prime = {
    #   # Make sure to set these with your actual bus IDs
    #   # Find them with: lspci | grep -E "VGA|3D"
    #   intelBusId = "PCI:0:2:0";
    #   nvidiaBusId = "PCI:1:0:0";
    #   
    #   # Offload mode - uses Intel by default, NVIDIA on demand (best for battery)
    #   offload = {
    #     enable = true;
    #     enableOffloadCmd = true;  # Provides nvidia-offload command
    #   };
    #   
    #   # Alternative: Sync mode - both GPUs active (better performance, worse battery)
    #   # sync.enable = true;
    #   
    #   # Alternative: Reverse PRIME - uses NVIDIA as primary (worst for battery)
    #   # reverseSync.enable = true;
    # };
  };

  nixpkgs.config.nvidia.acceptLicense = true;
}
