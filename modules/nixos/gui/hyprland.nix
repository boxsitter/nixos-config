{ config, pkgs, ... }:

{
  # Disable X11 display manager; we'll run Wayland/Hyprland directly
  services.xserver.enable = false;

  # Hyprland compositor (system provides it, user configures it via Home Manager)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # XWayland for legacy X11 apps
  };

  # Login manager: greetd with tuigreet (simple TUI greeter)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Start a user session with Hyprland wrapped in dbus
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'dbus-run-session ${pkgs.hyprland}/bin/Hyprland'";
        user = "greeter";
      };
    };
  };

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

  # Portals for Wayland (screenshare, file pickers, etc.)
  xdg.portal = {
    enable = true;
    # hyprland portal alongside gtk for broader compatibility
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  };

  # System packages needed for Wayland/Hyprland to function
  # User apps (kitty, waybar, etc.) are now in Home Manager
  environment.systemPackages = with pkgs; [
    # Only essential system-level tools
    tuigreet
  ];

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                # Prefer Wayland for Electron/Chromium apps
    WLR_NO_HARDWARE_CURSORS = "1";      # Workaround for cursor glitches
    WLR_RENDERER_ALLOW_SOFTWARE = "1";  # Allow software rendering fallback
  };
}
