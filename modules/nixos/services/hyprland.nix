{ pkgs, ... }:

{
  # Hyprland compositor (system provides it, user configures it via Home Manager)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # XWayland for legacy X11 apps
  };

  # Ensure display managers (e.g. GDM) can offer Hyprland as a selectable session.
  services.displayManager.sessionPackages = [ pkgs.hyprland ];

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

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                # Prefer Wayland for Electron/Chromium apps
    WLR_NO_HARDWARE_CURSORS = "1";      # Workaround for cursor glitches
    WLR_RENDERER_ALLOW_SOFTWARE = "1";  # Allow software rendering fallback
    
    # NVIDIA-specific Wayland variables for high refresh rate displays
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    
    # Force enable DSC at environment level
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };
}
