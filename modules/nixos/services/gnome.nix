{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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
  
  # Enable xdg-desktop-portal for file pickers and other integrations
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Fonts (system-wide)
  # Ensures "FiraCode Nerd Font" is available for Kitty/VS Code/etc.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];
  
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
    firefox
    vlc
    wl-clipboard
    pavucontrol
    networkmanagerapplet

    # Stable GTK3 theme that matches GNOME's look; avoids oversized buttons
    adw-gtk3

    # Desktop applications
    vscode
    insync
    legcord
  ];

  # Auto-start Insync on login
  systemd.user.services.insync = {
    description = "Insync - Google Drive sync";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.insync}/bin/insync start";
      Restart = "on-failure";
      Environment = [
        "PATH=${pkgs.nautilus}/bin:${pkgs.xdg-utils}/bin"
        "XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };
  };
}
