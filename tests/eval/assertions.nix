# tests/eval/assertions.nix
#
# Pure-eval invariant checks. Each entry is a boolean expression that MUST
# hold across the host configs we care about. If any fail, the build fails
# with a list of every violation (not just the first one).
#
# This is the cheapest layer in the test suite: it's just module evaluation,
# no VM, no build. Run it on every change. Anything you'd otherwise write
# `# TODO don't forget to set X` about — encode it here instead.

{ pkgs, self, inputs, lib }:

let
  # The four NixOS hosts. Mac is darwin and uses a different module system,
  # so it doesn't share these invariants directly.
  hosts = {
    desktop = self.nixosConfigurations.desktop.config;
    laptop  = self.nixosConfigurations.laptop.config;
    wsl     = self.nixosConfigurations.wsl.config;
    server  = self.nixosConfigurations.server.config;
  };

  # Helper: build assertions across hosts. `f` takes (name, cfg) and
  # returns a list of {check, msg} records.
  forEachHost = f: lib.flatten (lib.mapAttrsToList (n: c: f n c) hosts);

  assertions =
    # ---- Core user / shell invariants ------------------------------------
    forEachHost (name: cfg: [
      {
        check = cfg.users.users ? leyton;
        msg = "${name}: users.users.leyton is not defined";
      }
      {
        check = (cfg.users.users.leyton.shell or null) == pkgs.fish
             || (cfg.users.users.leyton.shell.pname or "") == "fish";
        msg = "${name}: leyton's shell isn't fish (got ${toString (cfg.users.users.leyton.shell or "<unset>")})";
      }
      {
        check = lib.elem "wheel" (cfg.users.users.leyton.extraGroups or []);
        msg = "${name}: leyton must be in the wheel group";
      }
      {
        check = cfg.programs.fish.enable;
        msg = "${name}: programs.fish.enable should be true";
      }
      {
        check = cfg.programs.direnv.enable;
        msg = "${name}: programs.direnv.enable should be true (used everywhere)";
      }
      {
        check = cfg.programs.direnv.nix-direnv.enable;
        msg = "${name}: programs.direnv.nix-direnv.enable should be true";
      }
    ])

    # ---- Nix settings invariants ----------------------------------------
    ++ forEachHost (name: cfg: [
      {
        check = lib.elem "flakes" cfg.nix.settings.experimental-features
             && lib.elem "nix-command" cfg.nix.settings.experimental-features;
        msg = "${name}: nix-command and flakes must be enabled in experimental-features";
      }
      {
        check = lib.elem "https://cache.nixos.org" cfg.nix.settings.substituters;
        msg = "${name}: cache.nixos.org missing from substituters";
      }
      {
        check = cfg.nix.gc.automatic;
        msg = "${name}: automatic gc must be enabled";
      }
      {
        check = lib.elem "@wheel" cfg.nix.settings.trusted-users;
        msg = "${name}: @wheel must be in nix.settings.trusted-users";
      }
    ])

    # ---- Locale / time invariants ---------------------------------------
    ++ forEachHost (name: cfg: [
      {
        check = cfg.time.timeZone == "America/Los_Angeles";
        msg = "${name}: time.timeZone should be America/Los_Angeles, got ${toString cfg.time.timeZone}";
      }
      {
        check = cfg.i18n.defaultLocale == "en_US.UTF-8";
        msg = "${name}: i18n.defaultLocale should be en_US.UTF-8";
      }
    ])

    # ---- Console / kernel hygiene ---------------------------------------
    ++ forEachHost (name: cfg: [
      {
        check = cfg.boot.consoleLogLevel == 4;
        msg = "${name}: boot.consoleLogLevel should be 4 (warning), got ${toString cfg.boot.consoleLogLevel}";
      }
      {
        check = cfg.boot.kernel.sysctl."kernel.perf_event_paranoid" == 1;
        msg = "${name}: kernel.perf_event_paranoid sysctl should be 1";
      }
      {
        check = cfg.boot.kernel.sysctl."kernel.kptr_restrict" == 0;
        msg = "${name}: kernel.kptr_restrict sysctl should be 0";
      }
      {
        check = cfg.systemd.coredump.enable;
        msg = "${name}: systemd.coredump.enable should be true";
      }
    ])

    # ---- SSH security invariants (the big one) -------------------------
    # These must hold on every host that has SSH enabled. WSL forces ssh
    # off, so it's exempt — assert that explicitly so we'd notice if WSL
    # silently grew ssh again.
    ++ forEachHost (name: cfg:
      if cfg.services.openssh.enable then [
        {
          check = !cfg.services.openssh.openFirewall;
          msg = "${name}: openssh.openFirewall MUST be false (SSH is tailscale-only)";
        }
        {
          check = cfg.services.openssh.settings.PermitRootLogin == "no";
          msg = "${name}: openssh PermitRootLogin must be 'no'";
        }
        {
          check = cfg.services.openssh.settings.PasswordAuthentication == false;
          msg = "${name}: openssh PasswordAuthentication must be false";
        }
        {
          check = lib.elem 22 (cfg.networking.firewall.interfaces.tailscale0.allowedTCPPorts or []);
          msg = "${name}: port 22 must be allowed on tailscale0 only";
        }
      ] else [
        {
          check = name == "wsl";
          msg = "${name}: openssh is disabled but only wsl is supposed to have ssh off";
        }
      ])

    # ---- Tailscale invariants -------------------------------------------
    ++ forEachHost (name: cfg:
      # WSL is the exception — it has no networkmanager and probably
      # shouldn't run tailscaled (it'd be redundant with WSL's networking).
      if name == "wsl" then [] else [
        {
          check = cfg.services.tailscale.enable;
          msg = "${name}: services.tailscale.enable should be true";
        }
        {
          check = lib.elem "tailscale0" cfg.networking.firewall.trustedInterfaces;
          msg = "${name}: tailscale0 must be in firewall.trustedInterfaces";
        }
      ])

    # ---- Hostnames are pinned -------------------------------------------
    ++ [
      { check = hosts.desktop.networking.hostName == "nixos-desktop";
        msg = "desktop: hostname must be nixos-desktop"; }
      { check = hosts.laptop.networking.hostName == "nixos-laptop";
        msg = "laptop: hostname must be nixos-laptop"; }
      { check = hosts.wsl.networking.hostName == "nixos-wsl";
        msg = "wsl: hostname must be nixos-wsl"; }
      { check = hosts.server.networking.hostName == "nixos-server";
        msg = "server: hostname must be nixos-server"; }
    ]

    # ---- system.stateVersion is set on every host ----------------------
    ++ forEachHost (name: cfg: [
      {
        check = cfg.system.stateVersion != null && cfg.system.stateVersion != "";
        msg = "${name}: system.stateVersion must be pinned";
      }
    ])

    # ---- Host-specific invariants ---------------------------------------
    # Desktop / laptop are workstations: GNOME, docker, GRUB, NVIDIA license.
    ++ [
      { check = hosts.desktop.virtualisation.docker.enable;
        msg = "desktop: docker should be enabled"; }
      { check = hosts.laptop.virtualisation.docker.enable;
        msg = "laptop: docker should be enabled"; }
      { check = hosts.desktop.boot.loader.grub.enable;
        msg = "desktop: GRUB should be enabled (dual-boot host)"; }
      { check = hosts.laptop.boot.loader.grub.enable;
        msg = "laptop: GRUB should be enabled (dual-boot host)"; }
      { check = hosts.desktop.powerManagement.cpuFreqGovernor == "performance";
        msg = "desktop: cpuFreqGovernor should be performance"; }
      { check = hosts.laptop.services.auto-cpufreq.enable;
        msg = "laptop: auto-cpufreq must be enabled (battery management)"; }
      { check = hosts.laptop.services.thermald.enable;
        msg = "laptop: thermald must be enabled"; }
      { check = !hosts.laptop.services.power-profiles-daemon.enable;
        msg = "laptop: power-profiles-daemon must be disabled (conflicts with auto-cpufreq)"; }
      { check = !hosts.desktop.services.power-profiles-daemon.enable;
        msg = "desktop: power-profiles-daemon must be disabled (conflicts with cpuFreqGovernor)"; }
    ]

    # ---- WSL-specific invariants ----------------------------------------
    ++ [
      { check = hosts.wsl.wsl.enable;
        msg = "wsl: wsl.enable must be true"; }
      { check = hosts.wsl.wsl.defaultUser == "leyton";
        msg = "wsl: defaultUser should be leyton"; }
      { check = !hosts.wsl.services.openssh.enable;
        msg = "wsl: openssh must remain disabled (sshd fails on WSL boot)"; }
      { check = !hosts.wsl.networking.networkmanager.enable;
        msg = "wsl: networkmanager must be disabled (conflicts with WSL networking)"; }
      { check = hosts.wsl.programs.nix-ld.enable;
        msg = "wsl: nix-ld must be enabled (needed for VS Code Remote-SSH)"; }
    ]

    # ---- Sops invariants (any host that imports secrets.nix) -----------
    ++ forEachHost (name: cfg: [
      {
        check = cfg.sops.age.generateKey == true;
        msg = "${name}: sops.age.generateKey should be true (auto-generate on first boot)";
      }
      {
        check = cfg.sops.age.keyFile == "/var/lib/sops-nix/key.txt";
        msg = "${name}: sops.age.keyFile should be /var/lib/sops-nix/key.txt";
      }
    ]);

  failed = lib.filter (a: !a.check) assertions;
  passedCount = lib.length assertions - lib.length failed;

  failureReport = lib.concatMapStringsSep "\n" (a: "  - ${a.msg}") failed;
in
if failed == [] then
  pkgs.runCommand "config-assertions"
    { meta.description = "Cross-host configuration invariants"; }
    ''
      echo "All ${toString passedCount} configuration assertions passed." > $out
    ''
else
  throw ''

    Configuration assertion failures (${toString (lib.length failed)} of ${toString (lib.length assertions)}):
    ${failureReport}
  ''
