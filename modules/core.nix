# ./modules/core.nix

{ config, pkgs, ... }:

{
  imports = [
    # Copy /etc/nixos/hardware-configuration.nix to your config directory
    # Then use: ../hardware-configuration.nix
    # For now, this will cause an error until you copy the file
    /etc/nixos/hardware-configuration.nix
  ];
  # GRUB bootloader configuration for dual-boot
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;  # This detects Windows
      # Remember last choice, or set to 1 for Windows default
      timeout = 10;
      # 10 seconds to choose
    };
    efi.canTouchEfiVariables = true;
  };
  # Configure console with a modern font and Catppuccin theme
  console = {
    # Use Terminus font which is a standard, reliable console font
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v20n.psf.gz";
    # Larger size (20) for better readability
    packages = with pkgs; [ terminus_font ];
    # Enable Catppuccin theme for console
    catppuccin = {
      enable = true;
      # The flavor is already set in configuration.nix
    };
  };

  # Set hostname - change this to your preferred hostname
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # Intel WiFi driver support
  hardware.enableRedistributableFirmware = true;
  # Enable Intel WiFi drivers
  boot.kernelModules = [ "iwlwifi" ];
  # Intel WiFi firmware and drivers
  hardware.enableAllFirmware = true;

  # Use latest kernel for best NVIDIA support
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Kernel parameters for NVIDIA RTX 5080 with DSC support
  boot.kernelParams = [
    "nvidia-drm.modeset=1"           # Enable modesetting
    "nvidia-drm.fbdev=1"             # Enable framebuffer device
    "nvidia.NVreg_EnableGpuFirmware=1"  # Enable GPU firmware loading
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Better power management
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"  # Temp file location
  ];

  # Blacklist nouveau driver
  boot.blacklistedKernelModules = [ "nouveau" ];
  
  # Set NVIDIA as the video driver
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Graphics configuration (replaces deprecated hardware.opengl)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications and games
  };

  # NVIDIA RTX 5080 configuration
  hardware.nvidia = {
    # Use open-source kernel modules (recommended for RTX 40/50 series)
    open = true;
    
    # Required for most Wayland compositors and proper display configuration
    modesetting.enable = true;
    
    # Enable power management (helps with display issues)
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    
    # Enable nvidia-settings GUI
    nvidiaSettings = true;
    
    # Use beta/production driver for RTX 5080 support
    # RTX 5000 series requires very recent drivers
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    
    # No hybrid graphics setup needed - single GPU system
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.leyton = {
    isNormalUser = true;
    description = "Leyton Houck";
    home = "/home/leyton";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.fish;
  };

  # Security configuration
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # Core system tools
    git nano wget curl pciutils usbutils lshw htop tree

    # Shell and terminal
    fish neofetch eza starship

    # Development tools
    vscode gcc mono jdk python3 racket bc

    # System utilities
    os-prober   # For detecting other operating systems in dual-boot
    ntfs3g      # For NTFS support (Windows partitions)

    unzip zip   # Archive utilities

    # Network tools
    networkmanagerapplet
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "leyton" ];
  };
}
