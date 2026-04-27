{ pkgs, lib, ... }:

{
  # Desktop performance optimizations
  boot.kernel.sysctl = {
    # Reduce swappiness for better desktop responsiveness
    "vm.swappiness" = 10;
    # Better file cache behavior for SSD
    "vm.vfs_cache_pressure" = 50;
  };

  # Use zram for better memory management on desktop
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Clear LD_LIBRARY_PATH to reduce GUI app startup overhead
  # NixOS packages have proper RPATHs and don't need this
  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.mkForce "";
  };
  services.xserver = {
    enable = true;
    # Disable screen blanking and DPMS to prevent black screen during startup
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Prevent screen blanking during login/startup
  services.displayManager.gdm.autoSuspend = false;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour epiphany geary gnome-music gnome-photos totem
    gnome-contacts gnome-maps gnome-weather simple-scan cheese yelp
    gnome-connections  # Poor NLA/RDP support; replaced by Remmina
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

  # Enable mDNS (.local hostname resolution) via NSS.
  # Fixes: avahi-daemon: WARNING: No NSS support for mDNS detected
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Fix bluetooth wake_allowed error
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };
  services.gnome.gnome-keyring.enable = true;
  
  # Enable PAM integration for GNOME Keyring to fix gkr-pam errors
  security.pam.services.gdm.enableGnomeKeyring = true;
  
  # Enable dconf for fast GTK app startup (prevents runtime schema compilation)
  programs.dconf.enable = true;
  
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
    nautilus  # GNOME Files (file manager)
    firefox
    chromium
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
    remmina  # RDP/VNC client with full NLA support (replaces gnome-connections)

    # JetBrains IDEs & tooling
    jetbrains-toolbox
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
