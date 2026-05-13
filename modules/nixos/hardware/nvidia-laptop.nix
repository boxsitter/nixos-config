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
    # Samsung PM9A1 on s2idle miscounts autonomous power state exits as unsafe
    # shutdowns. Disabling APST stops the drive entering those states on its
    # own, so the counter stops incrementing. Negligible real-world impact.
    "nvme_core.default_ps_max_latency_us=0"
    # Intel PSR (Panel Self Refresh) causes a brief blank on resume on
    # Raptor Lake-H. Using psr_safest_params forces conservative timing
    # to avoid the glitch while keeping PSR active for battery life.
    "i915.enable_psr=1"
    "i915.psr_safest_params=1"
  ];

  # Load NVIDIA modules early so udev device nodes (/dev/nvidiactl etc.) are
  # created before userspace services start. Without this, udev fires before
  # the module is ready and mknod fails.
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

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
    # RTD3 (D3cold) is enabled for battery life, but the default 5-second
    # autosuspend delay causes a race: the idle timer fires during GNOME's
    # post-resume compositor startup, producing drmModeAtomicCommit failures
    # on the cursor plane and blacking the screen until input wakes the GPU.
    # 60 seconds is long enough that GNOME always finishes initializing first,
    # while still allowing the GPU to reach D3cold during genuine idle periods.
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

  # Increase NVIDIA RTD3 autosuspend delay from the default 5s to 60s.
  # This ensures the GPU stays awake long enough for GNOME's post-resume
  # compositor initialization to complete before D3cold entry is attempted.
  # Without this, drmModeAtomicCommit fails on the cursor plane mid-transition
  # and the display goes black until the next input event.
  services.udev.extraRules = ''
    ACTION=="bind", SUBSYSTEM=="pci", \
      ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", \
      ATTR{power/autosuspend_delay_ms}="60000"
  '';
}
