# modules/nixos/packages/cli.nix
# Core CLI packages for all systems (including WSL)

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core system tools
    git nano vim wget curl pciutils usbutils lshw htop btop tree file which
    
    # System monitoring & debugging
    strace lsof tcpdump
    
    # Shell and terminal
    fish fastfetch eza starship direnv nnn fzf ripgrep fd bat
    
    # Text processing & search
    jq yq-go gnused gawk gnugrep
    
    # Network tools
    dig nmap netcat-gnu inetutils openssh rsync
    
    # Version control
    git git-lfs lazygit gh
    
    # Container & orchestration
    docker docker-compose lazydocker kubectl k9s helm
    
    # Database clients
    postgresql sqlite
    
    # Nix development
    nil nixpkgs-fmt nix-tree nix-index
    
    # Archive utilities
    unzip zip gzip bzip2 xz p7zip
    
    # Misc utilities
    bc man-pages man-pages-posix tldr entr watchexec
  ];
}
