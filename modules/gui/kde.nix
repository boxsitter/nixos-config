# ./modules/gui/kde.nix
{ pkgs, ... }:

{
  # Enable the X11 windowing system and KDE Plasma 6
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    dpi = 140;
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
}
