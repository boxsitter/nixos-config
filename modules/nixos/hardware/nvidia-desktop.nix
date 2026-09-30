# ./modules/hardware/nvidia-desktop.nix
# NVIDIA RTX 5080 configuration for desktop

{ config, pkgs, ... }:

{
  # Default (LTS) kernel: linuxPackages_latest often outpaces the NVIDIA driver
  # (e.g. 7.2 broke nvidia-open 595), leaving the desktop unbuildable.
  boot.kernelPackages = pkgs.linuxPackages;
  
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_EnableGpuFirmware=1"  # Required for DP 2.1
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "nvidia.NVreg_DynamicPowerManagement=0x00"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = true;  # Better DP 2.1 support
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;  # RTX 5000 requires 560+
  };

  nixpkgs.config.nvidia.acceptLicense = true;
}
