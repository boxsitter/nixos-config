# modules/nixos/packages/gui.nix
# GUI applications and Wayland/Hyprland tools
# Import only on desktop/laptop/vm, NOT on WSL

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # GUI applications
    vscode firefox vlc kitty
    
    # Wayland/Hyprland utilities
    wl-clipboard       # Clipboard manager
    grim slurp         # Screenshots
    hyprpaper          # Wallpaper daemon
    hyprlock           # Screen locker
    wofi               # Application launcher
    dunst              # Notification daemon
    pavucontrol        # PulseAudio volume control
    networkmanagerapplet  # Network manager tray
    imagemagick        # Image processing (for wallpaper generation)
    
    # Qt/GTK theming
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];
}
