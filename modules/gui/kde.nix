# ./modules/gui/kde.nix
{ pkgs, ... }:

{
  # Enable the X11 windowing system and KDE Plasma 6
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    dpi = 140;
    
    # Additional configuration for high refresh rate displays
    config = ''
      Section "Screen"
        Identifier "Screen0"
        Option "metamodes" "DP-0: 7680x2160_240 +0+0 {ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}"
        Option "AllowIndirectGLXProtocol" "off"
        Option "TripleBuffer" "on"
      EndSection
    '';
    
    screenSection = ''
      Option "RegistryDwords" "EnableBrightnessControl=1"
    '';
  };

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Install KDE applications and utilities
  environment.systemPackages = with pkgs; [
    # Essential KDE applications
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.ark
    kdePackages.okular        # PDF viewer
    kdePackages.gwenview      # Image viewer
    kdePackages.partitionmanager  # Useful for dual-boot management
    
    # Web and media
    firefox
    vlc
    
    # System monitoring
    kdePackages.ksystemlog
    kdePackages.kinfocenter
  ];

  # Enable CUPS for printing
  services.printing.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  
  # Environment variables for NVIDIA high refresh rate support
  environment.sessionVariables = {
    # Enable NVIDIA threaded optimization
    "__GL_THREADED_OPTIMIZATION" = "1";
    # Ensure proper sync for high refresh rates
    "__GL_SYNC_TO_VBLANK" = "0";
    # Allow unofficial protocols (may help with refresh rate detection)
    "KWIN_DRM_USE_MODIFIERS" = "1";
  };
}
