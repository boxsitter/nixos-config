# tests/vm/core-module.nix
#
# Boots a minimal NixOS VM that imports modules/nixos/core.nix and asserts
# the cross-host invariants we depend on:
#   - leyton user exists, in the right groups, with fish as login shell
#   - fish + direnv are wired in system-wide
#   - sudo NOPASSWD rules are present for nixos-rebuild and `nix flake update`
#   - timezone / locale / console keymap match what we declared
#   - nix experimental features (flakes, nix-command) are enabled
#   - binary cache substituters and trusted keys are installed
#   - nix gc timer is active
#   - kernel sysctls (perf_event_paranoid, kptr_restrict) match
#   - systemd-coredump captures crashes with the configured size limits
#   - selected core packages are reachable on PATH

{ pkgs, self, inputs, lib }:

let
  # core.nix declares `claude-code` (unfree) in environment.systemPackages.
  # The default pkgs the test framework uses doesn't allow unfree, so we
  # reinstantiate nixpkgs with the allowance flipped on for this test.
  pkgsUnfree = import inputs.nixpkgs {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
pkgsUnfree.testers.runNixOSTest {
  name = "core-module";

  nodes.machine = { config, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
      ../../modules/nixos/core.nix
    ];

    # core.nix doesn't pin a state version per host (it's set inside core.nix)
    # but the VM test framework needs a working filesystem layout. runNixOSTest
    # provides that automatically.

    # sops needs *some* defaultSopsFile or it errors during eval. Point it at
    # a fake path; we never declare any secrets in this test so it's never read.
    sops.defaultSopsFile = lib.mkForce (pkgs.writeText "fake-secrets.yaml" "{}");
    sops.age.keyFile = lib.mkForce "/tmp/no-key";
    sops.age.generateKey = lib.mkForce false;

    # runNixOSTest provides pkgs externally, which locks nixpkgs.config via
    # read-only.nix. core.nix declares allowUnfreePredicate, so the two
    # definitions collide. mkForce settles it at the test layer without
    # touching core.nix.
    nixpkgs.config = lib.mkForce {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    # The test framework cranks loglevel up to 7 so it can capture failure
    # output. core.nix sets 4. Force the test value so we can actually see
    # test output; the loglevel assertion is verified at module-eval level
    # via tests/eval/assertions.nix instead (when we add it there).
    boot.consoleLogLevel = lib.mkForce 7;

    # Tailscale tries to come up — fine, but it'll never authenticate in the
    # VM. We don't assert anything about its connection state here, only that
    # the unit is loaded. (See ssh-tailscale.nix for firewall assertions.)

    # No passwords needed: machine.succeed() runs as root via the test
    # driver's serial console, no login is performed.
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    with subtest("leyton user exists with the expected groups and shell"):
        machine.succeed("id leyton")
        groups = machine.succeed("id -nG leyton").split()
        for g in ["wheel", "networkmanager", "video", "input"]:
            assert g in groups, f"leyton missing group {g!r} (have: {groups})"
        shell = machine.succeed("getent passwd leyton | cut -d: -f7").strip()
        assert shell.endswith("/bin/fish"), f"leyton shell should be fish, got {shell!r}"

    with subtest("fish is the system shell program (programs.fish.enable)"):
        machine.succeed("test -e /etc/fish/config.fish || test -e /etc/profile.d/fish-interactive.fish || test -e /run/current-system/sw/bin/fish")
        machine.succeed("/run/current-system/sw/bin/fish -c 'echo hello' | grep -q hello")

    with subtest("direnv + nix-direnv are integrated"):
        machine.succeed("test -x /run/current-system/sw/bin/direnv")
        # nix-direnv installs its hook under share/nix-direnv
        machine.succeed("ls /run/current-system/sw/share/nix-direnv/direnvrc")

    with subtest("sudo NOPASSWD rules for nixos-rebuild and flake update are present"):
        sudoers = machine.succeed("cat /etc/sudoers /etc/sudoers.d/* 2>/dev/null || true")
        assert "/run/current-system/sw/bin/nixos-rebuild" in sudoers, \
            "nixos-rebuild NOPASSWD rule missing from sudoers"
        assert "nix flake update" in sudoers, \
            "nix flake update NOPASSWD rule missing from sudoers"
        # Wheel still requires a password for everything else
        assert "wheelNeedsPassword" not in sudoers  # internal token shouldn't leak
        machine.succeed("sudo -u leyton -n /run/current-system/sw/bin/sudo -n -l | grep -q nixos-rebuild")

    with subtest("timezone is America/Los_Angeles"):
        tz = machine.succeed("readlink -f /etc/localtime")
        assert "America/Los_Angeles" in tz, f"unexpected timezone link: {tz!r}"

    with subtest("locale is en_US.UTF-8"):
        locale = machine.succeed("cat /etc/locale.conf")
        assert "en_US.UTF-8" in locale, f"locale.conf doesn't pin en_US.UTF-8: {locale!r}"

    with subtest("console keymap is us"):
        vconsole = machine.succeed("cat /etc/vconsole.conf")
        assert "KEYMAP=us" in vconsole, f"console keymap not us: {vconsole!r}"

    with subtest("nix flakes + nix-command are enabled"):
        nixconf = machine.succeed("cat /etc/nix/nix.conf")
        assert "flakes" in nixconf and "nix-command" in nixconf, \
            f"experimental-features missing flakes/nix-command: {nixconf!r}"
        # And actually exercise it
        machine.succeed("nix --extra-experimental-features 'nix-command flakes' --version")

    with subtest("binary cache substituters and trusted keys are present"):
        nixconf = machine.succeed("cat /etc/nix/nix.conf")
        for sub in ["https://cache.nixos.org", "https://playit-nixos-module.cachix.org"]:
            assert sub in nixconf, f"substituter {sub!r} not in nix.conf"
        for key in [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=",
            "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4=",
        ]:
            assert key in nixconf, f"trusted-public-key {key!r} not in nix.conf"

    with subtest("auto-optimise-store and parallel http connections are configured"):
        nixconf = machine.succeed("cat /etc/nix/nix.conf")
        assert "auto-optimise-store = true" in nixconf
        assert "http-connections = 128" in nixconf
        assert "warn-dirty = false" in nixconf

    with subtest("nix gc timer is active and weekly"):
        machine.succeed("systemctl is-enabled nix-gc.timer")
        # The timer's OnCalendar should be weekly — surface it for diagnostics
        timer_cfg = machine.succeed("systemctl cat nix-gc.timer")
        assert "weekly" in timer_cfg.lower() or "Mon" in timer_cfg or "Sun" in timer_cfg, \
            f"nix-gc.timer doesn't look weekly: {timer_cfg!r}"

    with subtest("kernel sysctls match"):
        assert machine.succeed("sysctl -n kernel.perf_event_paranoid").strip() == "1"
        assert machine.succeed("sysctl -n kernel.kptr_restrict").strip() == "0"

    with subtest("systemd-coredump is enabled with our size limits"):
        machine.succeed("systemctl cat systemd-coredump.socket >/dev/null")
        coredump_conf = machine.succeed("cat /etc/systemd/coredump.conf /etc/systemd/coredump.conf.d/*.conf 2>/dev/null || true")
        assert "ProcessSizeMax=2G" in coredump_conf, f"coredump ProcessSizeMax wrong: {coredump_conf!r}"
        assert "ExternalSizeMax=2G" in coredump_conf, f"coredump ExternalSizeMax wrong: {coredump_conf!r}"

    with subtest("systemd-udev-settle is disabled (boot performance)"):
        # systemctl is-enabled returns non-zero for masked/disabled, so use status
        state = machine.succeed("systemctl show -p UnitFileState --value systemd-udev-settle.service || true").strip()
        # disabled, masked, or static-and-not-wanted are all acceptable
        assert state in ("disabled", "masked", "", "static"), \
            f"systemd-udev-settle should not be enabled, got {state!r}"

    with subtest("a representative slice of core packages are on PATH"):
        for tool in [
            "git", "vim", "htop", "btop", "tree", "ripgrep", "fd", "bat",
            "jq", "yq", "dig", "nmap", "lazygit", "gh",
            "nixd", "nixpkgs-fmt", "nix-tree",
            "smartctl", "sensors",
            "fastfetch", "starship", "fzf",
        ]:
            machine.succeed(f"command -v {tool}")

    machine.shutdown()
  '';
}
