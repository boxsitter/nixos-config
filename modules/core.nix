# ./modules/core.nix

{ config, pkgs, ... }:

{
  imports = [
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

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "video=DP-2:7680x2160@240"
  ];

  # Graphics drivers configuration
  boot.blacklistedKernelModules = [ "nouveau" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  # Change to "amdgpu" for AMD or remove for Intel integrated
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For 32-bit applications
  };

  # NVIDIA configuration (comment out if not using NVIDIA)
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    # Disable power management during troubleshooting
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    # Use the 'production' driver for newer hardware support
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    prime = {
      reverseSync.enable = false;
      offload.enable = true;

      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:4:0:0";
    };
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
      pulseaudio = true;
      nvidia.acceptLicense = true;
      packageOverrides = pkgs: { inherit (pkgs) linuxPackages_latest nvidia_x11; };
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
    polkitPolicyOwners = [ "yourUsernameHere" ];
  };
}
