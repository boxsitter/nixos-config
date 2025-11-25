# modules/nixos/packages/gui.nix
# GUI applications and Wayland/Hyprland tools
# Import only on desktop/laptop/vm, NOT on WSL

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # GUI applications
    vscode firefox vlc
    
    # Wayland/Hyprland utilities
    wl-clipboard grim slurp hyprpaper hyprlock wofi
    
    # Qt/GTK theming
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];
}
