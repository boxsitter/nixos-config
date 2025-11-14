{ config, pkgs, ... }:

{
  # Disable X11 display manager; we'll run Wayland/Hyprland directly
  services.xserver.enable = false;

  # Hyprland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # XWayland for legacy X11 apps
  };

  # Login manager: greetd with tuigreet (simple TUI greeter)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Start a user session with Hyprland under dbus-run-session
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --remember-user --time --cmd 'dbus-run-session Hyprland'";
        user = "greeter";
      };
    };
  };

  # Audio: PipeWire with PulseAudio compatibility
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing and Bluetooth (kept from KDE module)
  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Portals for Wayland (screenshare, file pickers, etc.)
  xdg.portal = {
    enable = true;
    # hyprland portal alongside gtk for broader compatibility
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  };

  # Helpful Wayland desktop tools
  environment.systemPackages = with pkgs; [
    # Core apps
    kitty
    waybar
    wofi
    hyprpaper
    hyprlock
    wl-clipboard
    grim slurp
    # Browsers/media (from KDE module)
    firefox
    vlc
  ];

  # NVIDIA + Wayland friendly environment
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                # Prefer Wayland for Electron/Chromium apps
    WLR_NO_HARDWARE_CURSORS = "1";      # Workaround for NVIDIA cursor glitches
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";         # GBM backend for NVIDIA
    LIBVA_DRIVER_NAME = "nvidia";       # VA-API via NVIDIA
  };

  # Provide a minimal, safe default Hyprland config so Super+Enter opens a terminal
  environment.etc."xdg/hypr/hyprland.conf".text = ''
    $mod = SUPER

    # Launch essentials on start
    exec-once = waybar
    exec-once = hyprpaper

    # Keybinds
    bind = $mod, RETURN, exec, kitty
    bind = $mod, Q, killactive
    bind = $mod, C, exec, wofi --show drun

    # General sane defaults
    misc { vfr = true }
    input { kb_layout = us }
    decoration { blur { enabled = false } }
  '';
}
