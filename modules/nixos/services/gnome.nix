{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour epiphany geary gnome-music gnome-photos totem
    gnome-contacts gnome-maps gnome-weather simple-scan cheese yelp
  ];

  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.gnome.gnome-keyring.enable = true;
  
  environment.systemPackages = with pkgs; [
    gnome-tweaks gnomeExtensions.appindicator
    firefox vlc
    wl-clipboard pavucontrol networkmanagerapplet
  ];
}
