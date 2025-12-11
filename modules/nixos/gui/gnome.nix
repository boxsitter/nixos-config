{ pkgs, ... }:

{
  # Enable X11 and GNOME Desktop
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Exclude unnecessary GNOME packages
  environment.gnome.excludePackages = with pkgs; [
    # Games
    gnome-tour
    epiphany       # GNOME Web browser
    geary          # Email client
    
    # Apps you might not need
    gnome-music
    gnome-photos
    totem          # Video player
    
    # Utilities you might not need
    gnome-contacts
    gnome-maps
    gnome-weather
    simple-scan    # Document scanner
    
    # Accessories
    cheese         # Webcam app
    
    # Other
    yelp           # Help viewer
  ];

  # Audio: PipeWire with PulseAudio compatibility
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing and Bluetooth
  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # GNOME-specific services
  services.gnome.gnome-keyring.enable = true;
  
  # Useful GNOME utilities
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
  ];
}
