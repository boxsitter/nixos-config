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
    GTK_THEME = "adw-gtk3";
    KITTY_ENABLE_WAYLAND = "1";
  };
  services.xserver.enable = true;

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
  # Noto fonts provide coverage for non-Latin scripts and emoji, preventing
  # missing glyph boxes (□) in browsers, terminals, and documents.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
  
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.tactile
    gnomeExtensions.user-themes  # Loads a custom GNOME Shell theme (see gnome.nix top-bar override)
    nautilus  # GNOME Files (file manager)
    firefox
    chromium
    vlc
    wl-clipboard
    pavucontrol
    networkmanagerapplet
    piper # gaming-mouse config gui (ratbagd frontend)

    # Stable GTK3 theme that matches GNOME's look; avoids oversized buttons
    adw-gtk3
    papirus-icon-theme  # Icon theme set in home-manager dconf
    dconf-editor        # GSettings/dconf tree browser

    # Desktop applications
    vscode
    warp-terminal  # GPU-accelerated terminal (trying it out)
    insync
    legcord
    remmina  # RDP/VNC client with full NLA support (replaces gnome-connections)

    # JetBrains IDEs & tooling
    jetbrains-toolbox

    # Office & productivity
    onlyoffice-desktopeditors  # Microsoft Office format compatible suite (.docx/.xlsx/.pptx)
    copyq           # Searchable clipboard history (GNOME has no built-in clipboard manager)

    # Image editing
    gimp            # Full-featured raster image editor
    gpick           # Screen color picker (hex/RGB output)

    # Audio
    lingot          # Precise graphical instrument tuner (FFT-based, selectable

    # Video editing & recording
    kdePackages.kdenlive  # Non-linear video editor
    obs-studio      # Screen recording and streaming

    # Screenshot & annotation
    flameshot       # Screenshot tool with built-in annotation (arrows, boxes, blur)

    # Download managers
    persepolis      # GUI download manager (aria2 frontend, queued/batch downloads)
    parabolic       # GNOME-native GUI for yt-dlp (YouTube, Twitch, etc.)
    yt-dlp          # CLI video/audio downloader
    aria2           # CLI multi-connection downloader

    # Torrent client (desktop GUI; separate from the headless server qbittorrent-nox)
    qbittorrent

    # Prism Launcher for Minecraft — wrapped to force NVIDIA via PRIME offload
    (pkgs.symlinkJoin {
      name = "prismlauncher";
      paths = [
        (prismlauncher.override {
          jdks = [ jdk21 jdk17 jdk8 ];
        })
      ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/prismlauncher \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only
      '';
    })
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
