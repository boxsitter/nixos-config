# tests/eval/assertions.nix
#
# Pure-eval invariant checks. Each entry is a boolean expression that MUST
# hold across the host configs we care about. If any fail, the build fails
# with a list of every violation (not just the first one).
#
# This is the cheapest layer in the test suite: it's just module evaluation,
# no VM, no build. Run it on every change. Anything you'd otherwise write
# `# TODO don't forget to set X` about — encode it here instead.

{
  pkgs,
  self,
  inputs,
  lib,
}:

let
  # The four NixOS hosts. Mac is darwin and uses a different module system,
  # so it doesn't share these invariants directly.
  hosts = {
    desktop = self.nixosConfigurations.desktop.config;
    laptop = self.nixosConfigurations.laptop.config;
    wsl = self.nixosConfigurations.wsl.config;
    server = self.nixosConfigurations.server.config;
  };

  # Helper: build assertions across hosts. `f` takes (name, cfg) and
  # returns a list of {check, msg} records.
  forEachHost = f: lib.flatten (lib.mapAttrsToList (n: c: f n c) hosts);

  assertions =
    # ---- Core user / shell invariants ------------------------------------
    forEachHost (
      name: cfg: [
        {
          check = cfg.users.users ? leyton;
          msg = "${name}: users.users.leyton is not defined";
        }
        {
          check =
            (cfg.users.users.leyton.shell or null) == pkgs.fish
            || (cfg.users.users.leyton.shell.pname or "") == "fish";
          msg = "${name}: leyton's shell isn't fish (got ${
            toString (cfg.users.users.leyton.shell or "<unset>")
          })";
        }
        {
          check = lib.elem "wheel" (cfg.users.users.leyton.extraGroups or [ ]);
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
      ]
    )

    # ---- Nix settings invariants ----------------------------------------
    ++ forEachHost (
      name: cfg: [
        {
          check =
            lib.elem "flakes" cfg.nix.settings.experimental-features
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
      ]
    )

    # ---- Locale / time invariants ---------------------------------------
    ++ forEachHost (
      name: cfg: [
        {
          check = cfg.time.timeZone == "America/Los_Angeles";
          msg = "${name}: time.timeZone should be America/Los_Angeles, got ${toString cfg.time.timeZone}";
        }
        {
          check = cfg.i18n.defaultLocale == "en_US.UTF-8";
          msg = "${name}: i18n.defaultLocale should be en_US.UTF-8";
        }
      ]
    )

    # ---- Console / kernel hygiene ---------------------------------------
    ++ forEachHost (
      name: cfg: [
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
      ]
    )

    # ---- SSH security invariants (the big one) -------------------------
    # These must hold on every host that has SSH enabled. WSL forces ssh
    # off, so it's exempt — assert that explicitly so we'd notice if WSL
    # silently grew ssh again.
    ++ forEachHost (
      name: cfg:
      if cfg.services.openssh.enable then
        [
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
            check = lib.elem 22 (cfg.networking.firewall.interfaces.tailscale0.allowedTCPPorts or [ ]);
            msg = "${name}: port 22 must be allowed on tailscale0 only";
          }
        ]
      else
        [
          {
            check = name == "wsl";
            msg = "${name}: openssh is disabled but only wsl is supposed to have ssh off";
          }
        ]
    )

    # ---- Tailscale invariants -------------------------------------------
    ++ forEachHost (
      name: cfg:
      # WSL is the exception — it has no networkmanager and probably
      # shouldn't run tailscaled (it'd be redundant with WSL's networking).
      if name == "wsl" then
        [ ]
      else
        [
          {
            check = cfg.services.tailscale.enable;
            msg = "${name}: services.tailscale.enable should be true";
          }
          {
            check = lib.elem "tailscale0" cfg.networking.firewall.trustedInterfaces;
            msg = "${name}: tailscale0 must be in firewall.trustedInterfaces";
          }
        ]
    )

    # ---- Hostnames are pinned -------------------------------------------
    ++ [
      {
        check = hosts.desktop.networking.hostName == "nixos-desktop";
        msg = "desktop: hostname must be nixos-desktop";
      }
      {
        check = hosts.laptop.networking.hostName == "nixos-laptop";
        msg = "laptop: hostname must be nixos-laptop";
      }
      {
        check = hosts.wsl.networking.hostName == "nixos-wsl";
        msg = "wsl: hostname must be nixos-wsl";
      }
      {
        check = hosts.server.networking.hostName == "nixos-server";
        msg = "server: hostname must be nixos-server";
      }
    ]

    # ---- system.stateVersion is set on every host ----------------------
    ++ forEachHost (
      name: cfg: [
        {
          check = cfg.system.stateVersion != null && cfg.system.stateVersion != "";
          msg = "${name}: system.stateVersion must be pinned";
        }
      ]
    )

    # ---- Host-specific invariants ---------------------------------------
    # Desktop / laptop are workstations: GNOME, docker, GRUB, NVIDIA license.
    ++ [
      {
        check = hosts.desktop.virtualisation.docker.enable;
        msg = "desktop: docker should be enabled";
      }
      {
        check = hosts.laptop.virtualisation.docker.enable;
        msg = "laptop: docker should be enabled";
      }
      {
        check = hosts.desktop.boot.loader.grub.enable;
        msg = "desktop: GRUB should be enabled (dual-boot host)";
      }
      {
        check = hosts.laptop.boot.loader.grub.enable;
        msg = "laptop: GRUB should be enabled (dual-boot host)";
      }
      {
        check = hosts.desktop.powerManagement.cpuFreqGovernor == "performance";
        msg = "desktop: cpuFreqGovernor should be performance";
      }
      {
        check = hosts.laptop.services.auto-cpufreq.enable;
        msg = "laptop: auto-cpufreq must be enabled (battery management)";
      }
      {
        check = hosts.laptop.services.thermald.enable;
        msg = "laptop: thermald must be enabled";
      }
      {
        check = !hosts.laptop.services.power-profiles-daemon.enable;
        msg = "laptop: power-profiles-daemon must be disabled (conflicts with auto-cpufreq)";
      }
      {
        check = !hosts.desktop.services.power-profiles-daemon.enable;
        msg = "desktop: power-profiles-daemon must be disabled (conflicts with cpuFreqGovernor)";
      }
    ]

    # ---- Hyprland + GNOME coexistence (desktop & laptop) ----------------
    # Hyprland is a *second* session. It must never displace GNOME/GDM, nothing
    # it adds may run inside GNOME, and the GNOME portal fallback must survive
    # next to the Hyprland-specific pick. See docs/hyprland.md.
    ++ lib.flatten (
      map
        (
          name:
          let
            cfg = hosts.${name};
            home = cfg.home-manager.users.leyton;
            hmUnits = home.systemd.user.services // home.systemd.user.sockets // home.systemd.user.timers;
            sessionTarget = "hyprland-session.target";
            # Wanted by something other than the Hyprland session target?
            leaked = lib.filterAttrs (
              _: u: (u.Install.WantedBy or [ ]) != [ sessionTarget ]
            ) hmUnits;
          in
          [
            {
              check = cfg.programs.hyprland.enable;
              msg = "${name}: programs.hyprland.enable should be true";
            }
            {
              check = !cfg.programs.hyprland.withUWSM;
              msg = "${name}: hyprland withUWSM must stay false (the session is scoped by hyprland-session.target; UWSM would compete for graphical-session.target)";
            }
            {
              check = cfg.services.displayManager.gdm.enable;
              msg = "${name}: GDM must remain enabled (Hyprland must not displace it)";
            }
            {
              check = cfg.services.desktopManager.gnome.enable;
              msg = "${name}: GNOME must remain enabled (Hyprland is additive)";
            }
            {
              # nixpkgs' Hyprland also advertises a "uwsm-managed" session that
              # cannot work here; it must not show up in the GDM session list.
              check = cfg.services.displayManager.sessionData.sessionNames == [ "gnome" "hyprland" ];
              msg = "${name}: GDM sessions should be exactly gnome + hyprland (got ${toString cfg.services.displayManager.sessionData.sessionNames})";
            }
            {
              check = cfg.security.pam.services ? hyprlock;
              msg = "${name}: PAM service for hyprlock must exist (or the lock screen can never unlock)";
            }
            {
              # programs.hyprlock/services.hypridle at system level would add a
              # hypridle unit wired to graphical-session.target, i.e. GNOME.
              check = !cfg.services.hypridle.enable && !cfg.programs.hyprlock.enable;
              msg = "${name}: system-level hypridle/hyprlock must stay off (their unit would start inside GNOME); use the home-manager ones";
            }
            {
              check = cfg.services.blueman.enable;
              msg = "${name}: services.blueman.enable must be true (backend for the Hyprland bluetooth applet)";
            }
            {
              # The portal module coerces the list to a ";"-joined string on disk.
              check = cfg.xdg.portal.config.hyprland.default == "hyprland;gtk";
              msg = "${name}: Hyprland portal pick must resolve to \"hyprland;gtk\"";
            }
            {
              check = cfg.xdg.portal.config.common.default == "*";
              msg = "${name}: GNOME portal fallback (common.default = \"*\") must be preserved";
            }
            {
              check = home.wayland.systemd.target == sessionTarget;
              msg = "${name}: wayland.systemd.target must be ${sessionTarget} so Home Manager wayland services stay out of GNOME";
            }
            {
              # The core isolation guarantee. Every Home Manager user unit on a
              # GUI host belongs to the Hyprland session; one that is also (or
              # instead) wanted by graphical-session.target, default.target or
              # tray.target would start inside GNOME. Several Home Manager
              # modules do exactly that (udiskie, playerctld, nm-applet); we
              # write those by hand. Add a unit outside the session? Give it an
              # explicit exemption here.
              check = leaked == { };
              msg = "${name}: home-manager user units not scoped to ${sessionTarget} (would run inside GNOME): ${toString (lib.attrNames leaked)}";
            }
            {
              check = home.systemd.user.targets ? hyprland-session;
              msg = "${name}: hyprland-session.target must be defined (nixpkgs does not ship it)";
            }
            {
              # Hyprland 0.56 imports its environment but does not start the
              # session target; Home Manager's hook does. Without it none of the
              # session's services (bar, notifications, wallpaper, ...) start.
              check = home.wayland.windowManager.hyprland.systemd.enable;
              msg = "${name}: wayland.windowManager.hyprland.systemd.enable must be true (it starts hyprland-session.target)";
            }
          ]
        )
        [
          "desktop"
          "laptop"
        ]
    )

    # ---- WSL-specific invariants ----------------------------------------
    ++ [
      {
        check = hosts.wsl.wsl.enable;
        msg = "wsl: wsl.enable must be true";
      }
      {
        check = hosts.wsl.wsl.defaultUser == "leyton";
        msg = "wsl: defaultUser should be leyton";
      }
      {
        check = !hosts.wsl.services.openssh.enable;
        msg = "wsl: openssh must remain disabled (sshd fails on WSL boot)";
      }
      {
        check = !hosts.wsl.networking.networkmanager.enable;
        msg = "wsl: networkmanager must be disabled (conflicts with WSL networking)";
      }
      {
        check = hosts.wsl.programs.nix-ld.enable;
        msg = "wsl: nix-ld must be enabled (needed for VS Code Remote-SSH)";
      }
    ]

    # ---- Sops invariants (any host that imports secrets.nix) -----------
    ++ forEachHost (
      name: cfg: [
        {
          check = cfg.sops.age.generateKey == true;
          msg = "${name}: sops.age.generateKey should be true (auto-generate on first boot)";
        }
        {
          check = cfg.sops.age.keyFile == "/var/lib/sops-nix/key.txt";
          msg = "${name}: sops.age.keyFile should be /var/lib/sops-nix/key.txt";
        }
      ]
    );

  failed = lib.filter (a: !a.check) assertions;
  passedCount = lib.length assertions - lib.length failed;

  failureReport = lib.concatMapStringsSep "\n" (a: "  - ${a.msg}") failed;
in
if failed == [ ] then
  pkgs.runCommand "config-assertions" { meta.description = "Cross-host configuration invariants"; } ''
    echo "All ${toString passedCount} configuration assertions passed." > $out
  ''
else
  throw ''

    Configuration assertion failures (${toString (lib.length failed)} of ${toString (lib.length assertions)}):
    ${failureReport}
  ''
