# modules/nixos/core.nix
# Shared base configuration for all systems

{ pkgs, lib, ... }:

{
  imports = [
    ./services/ssh.nix
    ./services/tailscale.nix
  ];

  networking.networkmanager.enable = lib.mkDefault true;

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

  programs.fish.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Run non-Nix prebuilt binaries (uv-downloaded pythons, npm native addons,
  # editor-downloaded language servers/debuggers, curl|sh tools) that expect a
  # standard FHS dynamic loader. Needed on every host now that toolchains are
  # global and projects lean less on per-project flake shells.
  programs.nix-ld.enable = true;

  security.sudo = {
    wheelNeedsPassword = true;
    extraRules = [{
      users = [ "leyton" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix flake update";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/journalctl -u minecraft-server-main -f --no-hostname -o cat";
          options = [ "NOPASSWD" ];
        }
      ];
    }];
  };
  security.polkit.enable = lib.mkDefault true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Enable binary cache
    substituters = [
      "https://cache.nixos.org"
      "https://playit-nixos-module.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4="
    ];
    # Optimize nix store
    auto-optimise-store = true;  # Automatically deduplicate
    # Use new experimental fetcher for faster downloads
    use-xdg-base-directories = true;
    # Download in parallel
    http-connections = 128;
    # Trust your user to use flake config settings
    trusted-users = [ "root" "@wheel" ];
    # Suppress dirty tree warnings system-wide
    warn-dirty = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = 1;
    "kernel.kptr_restrict" = 0;
  };

  # Suppress cosmetic ACPI/firmware log spam on the console without blanking
  # acpi_osi (which breaks device detection on Dell/ASUS hardware).
  # Errors are still fully recorded in journalctl, just not shown on screen.
  boot.consoleLogLevel = 4; # 4 = WARNING; default is 7 (DEBUG)

  # Capture crash dumps so you can diagnose what killed a process or the kernel.
  systemd.coredump = {
    enable = true;
    extraConfig = ''ProcessSizeMax=2G
ExternalSizeMax=2G'';
  };

  # Performance: Use systemd in initrd for faster parallel boot
  boot.initrd.systemd.enable = lib.mkDefault true;

  # Performance: Don't wait for all devices during boot
  systemd.services.systemd-udev-settle.enable = false;

  environment.systemPackages = with pkgs; [
    # Core utilities
    nano # terminal editor
    vim # terminal editor
    wget # file downloader
    curl # http client
    pciutils # lspci
    usbutils # lsusb
    lshw # hardware lister
    htop # process viewer
    btop # process viewer
    tree # directory tree
    file # file type detector
    which # locate a command
    strace # syscall tracer
    lsof # open-file lister
    tcpdump # packet capture
    sysprof # system profiler

    # Shell and CLI enhancements
    fish # shell
    fastfetch # system info
    eza # ls replacement
    starship # shell prompt
    direnv # per-directory env
    nnn # file manager
    fzf # fuzzy finder
    ripgrep # fast grep
    fd # fast find
    bat # cat with syntax
    tmux # terminal multiplexer

    # Text processing
    jq # json processor
    yq-go # yaml processor
    gnused # sed
    gawk # awk
    gnugrep # grep

    # Version control
    git # version control
    git-lfs # large-file storage
    lazygit # git tui
    gh # github cli

    # Networking
    dig # dns lookup
    nmap # port scanner
    netcat-gnu # netcat
    inetutils # basic net tools
    openssh # ssh client/server
    rsync # file sync
    iftop # bandwidth by connection
    nload # bandwidth monitor
    vnstat # traffic stats
    speedtest-cli # speed test
    nethogs # bandwidth by process

    # Archives
    unzip # unzip
    zip # zip
    gzip # gzip
    bzip2 # bzip2
    xz # xz
    p7zip # 7-zip

    # System health & diagnostics
    nvme-cli # nvme ssd health
    smartmontools # disk health
    lm_sensors # temperature sensors

    # Documentation
    bc # calculator
    man-pages # man pages
    man-pages-posix # posix man pages
    tldr # simplified man pages
    entr # run on file change
    watchexec # run on file change

    # Nix tools
    nix-output-monitor # pretty build output
    nix-fast-build # parallel builds
    nixd # nix language server
    nixfmt # nix formatter (rfc style)
    nixpkgs-fmt # nix formatter
    nix-tree # dependency explorer
    nix-index # file-to-package search

    # AI tools
    claude-code # claude cli
    claude-mergetool # claude merge driver
    claude-monitor # claude usage monitor

    # Containers
    lazydocker # docker tui

    # Language toolchains (interpreters/managers only; libraries stay per-project)
    python3 # python interpreter
    uv # python env/dependency manager
    nodejs_22 # node + npm
    jdk # java (current lts)
    maven # java build tool
    gradle # java build tool
    dart # dart sdk

    # Build toolchain (compiles native pip/npm extensions and c/c++ sources)
    gcc # c/c++ compiler
    gnumake # make
    pkg-config # build-flag helper
    cmake # build system

    # Databases — client tools only. Actual servers run per-project (docker or
    # services.postgresql), not as a global stateful daemon.
    # (pgcli/litecli omitted: their shared dep `cli-helpers` has failing tests
    #  in the current nixpkgs. psql and sqlite3 provide REPLs in the meantime.)
    sqlite # embedded db + sqlite3 cli
    postgresql # psql, pg_dump, pg_restore, createdb
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  # DO NOT CHANGE - set once at initial install
  system.stateVersion = "24.11";
}
