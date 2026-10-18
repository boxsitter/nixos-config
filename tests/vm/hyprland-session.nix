# tests/vm/hyprland-session.nix
#
# End-to-end check of the Hyprland setup next to GNOME: two VMs share one
# configuration (GDM + GNOME infrastructure + the Hyprland module + the real
# laptop home-manager config) and differ only in which session GDM auto-logs
# into.
#
#   hyprland  logs into the Hyprland session. Everything the session is meant to
#             run must come up, the config must load without errors, and the
#             keybinds must actually work.
#   gnome     logs into GNOME. None of the Hyprland session's services may start
#             (the whole point of keeping the two separate), and GNOME must still
#             own its notification daemon.
#
# Rendering is software (llvmpipe) so no GPU is needed. Hardware-specific parts
# (NVIDIA, lid switch, real monitors) cannot be covered here.
#
# For screenshots while developing, run the driver with a custom --test-script
# (see docs/hyprland.md, "Verifying changes").

{
  pkgs,
  self,
  inputs,
  lib,
}:

let
  # Mirrors the parts of modules/nixos/services/gnome.nix the Hyprland session
  # relies on, without its application list (JetBrains, VS Code, ... are large
  # and unfree). eval-assertions checks the real hosts still provide the same.
  desktopInfra =
    { pkgs, ... }:
    {
      services.xserver.enable = true;
      services.displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
      services.desktopManager.gnome.enable = true;

      security.rtkit.enable = true;
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      hardware.bluetooth.enable = true;
      networking.networkmanager.enable = true;

      services.gnome.gnome-keyring.enable = true;
      security.pam.services.gdm.enableGnomeKeyring = true;
      programs.dconf.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };

      fonts.packages = with pkgs; [
        nerd-fonts.fira-code
        noto-fonts
      ];

      environment.sessionVariables.GTK_THEME = "adw-gtk3";
      environment.systemPackages = with pkgs; [
        adw-gtk3
        papirus-icon-theme
        pavucontrol
        networkmanagerapplet
        wl-clipboard
        nautilus
      ];
    };

  common =
    { lib, ... }:
    {
      imports = [
        desktopInfra
        ../../modules/nixos/services/hyprland.nix
        inputs.home-manager.nixosModules.home-manager
      ];

      virtualisation = {
        memorySize = 6144;
        cores = 4;
        qemu.options = [
          "-vga none"
          "-device virtio-gpu-pci,xres=1920,yres=1080"
        ];
      };

      boot.consoleLogLevel = lib.mkForce 7;

      users.users.leyton = {
        isNormalUser = true;
        uid = 1000;
        initialPassword = "test";
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
        ];
      };

      services.displayManager.autoLogin = {
        enable = true;
        user = "leyton";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = { inherit inputs; };
        sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
        # The real laptop user config: same modules, same Lua, same units.
        users.leyton = import ../../hosts/laptop/leyton.nix;
      };
    };

  # Every user unit the Hyprland session owns. Keep in sync with
  # modules/home-manager/hyprland (the eval test guards the scoping rules).
  sessionUnits = [
    "waybar"
    "swaync"
    "swayosd"
    "awww"
    "hypridle"
    "hyprpolkitagent"
    "cliphist"
    "hyprsunset"
    "udiskie"
    "playerctld"
    "nm-applet"
  ];
in
pkgs.testers.runNixOSTest {
  name = "hyprland-session";

  nodes.hyprland = {
    imports = [ common ];
    services.displayManager.defaultSession = "hyprland";
  };

  nodes.gnome = {
    imports = [ common ];
    services.displayManager.defaultSession = "gnome";
  };

  testScript = ''
    import shlex

    SESSION_UNITS = ${builtins.toJSON sessionUnits}

    # `su -` does not give us a logind session, so spell out what a real
    # session's processes would have inherited. These are `export`s rather than
    # inline VAR=value prefixes so a command can still start with `!`.
    BASE_ENV = (
        "export XDG_RUNTIME_DIR=/run/user/1000; "
        "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; "
    )
    WAYLAND_ENV = BASE_ENV + "export WAYLAND_DISPLAY=wayland-1; "
    HYPR_ENV = (
        WAYLAND_ENV
        + "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -n1); "
    )

    def as_user(cmd, env=BASE_ENV):
        return "su - leyton -c " + shlex.quote(env + cmd)

    def user_sh(machine, cmd, env=BASE_ENV):
        return machine.succeed(as_user(cmd, env))

    def hypr_sh(machine, cmd):
        return user_sh(machine, cmd, HYPR_ENV)

    def hypr_until(machine, cmd, timeout=60):
        machine.wait_until_succeeds(as_user(cmd, HYPR_ENV), timeout=timeout)

    # wait_for_unit() refuses to wait on a unit that is inactive with nothing
    # queued yet, which races with the session target being started. Poll.
    def unit_active(machine, unit, timeout=120):
        machine.wait_until_succeeds(as_user("systemctl --user is-active " + unit), timeout=timeout)

    start_all()

    with subtest("hyprland: session starts"):
        hyprland.wait_for_unit("graphical.target")
        hyprland.wait_for_file("/run/user/1000/wayland-1")
        unit_active(hyprland, "hyprland-session.target")

    with subtest("hyprland: config loads without errors"):
        errors = hypr_sh(hyprland, "hyprctl configerrors").strip()
        print("configerrors:", repr(errors))
        assert errors in ("", "no errors"), errors

    with subtest("hyprland: every session service is running"):
        for unit in SESSION_UNITS:
            unit_active(hyprland, unit + ".service")

    with subtest("hyprland: no systemd ordering cycles"):
        # systemd breaks a cycle by silently deleting a job, which can mean a
        # session service randomly never starts. Never acceptable.
        hyprland.fail("journalctl -b --no-pager | grep -i 'ordering cycle'")

    with subtest("hyprland: nothing failed"):
        failed = user_sh(hyprland, "systemctl --user list-units --state=failed --no-legend --plain")
        print("failed units:", repr(failed))
        assert failed.strip() == "", failed

    with subtest("hyprland: the shell owns the notification bus name"):
        owner = user_sh(hyprland, "busctl --user status org.freedesktop.Notifications")
        assert "swaync" in owner or "SwayNotificationCenter" in owner, owner

    with subtest("hyprland: wallpaper is applied and remembered"):
        hyprland.wait_until_succeeds(as_user("awww query", WAYLAND_ENV), timeout=60)
        user_sh(hyprland, "test -L ~/.local/state/wallpaper/current")
        user_sh(hyprland, "wallpaper set horizon", WAYLAND_ENV)
        assert user_sh(hyprland, "cat ~/.local/state/wallpaper/name").strip() == "horizon.jpg"

    with subtest("hyprland: portal config resolves for the Hyprland session"):
        hyprland.succeed("grep -q 'default=hyprland;gtk' /etc/xdg/xdg-desktop-portal/hyprland-portals.conf")

    with subtest("hyprland: cheat sheet is generated from the live binds"):
        binds = hypr_sh(hyprland, "hyprctl binds -j")
        for expected in ("Terminal", "Launcher", "Lock", "Power menu", "Wallpaper picker"):
            assert expected in binds, expected + " missing from hyprctl binds"

    with subtest("hyprland: windows, workspaces and layout binds"):
        hyprland.send_key("meta_l-ret")  # terminal
        hypr_until(hyprland, "hyprctl clients -j | tr -d ' \\n' | grep -q '\"class\":\"kitty\"'")
        hyprland.screenshot("hyprland-terminal")

        hyprland.send_key("meta_l-3")
        hypr_until(hyprland, "hyprctl activeworkspace -j | tr -d ' \\n' | grep -q '\"id\":3'")
        hyprland.send_key("meta_l-1")
        hypr_until(hyprland, "hyprctl activeworkspace -j | tr -d ' \\n' | grep -q '\"id\":1'")

        hyprland.send_key("meta_l-shift-4")  # send the terminal to workspace 4
        hypr_until(hyprland, "hyprctl clients -j | tr -d ' \\n' | grep -q '\"id\":4,'")
        hyprland.send_key("meta_l-4")

        hyprland.send_key("meta_l-v")  # float
        hypr_until(hyprland, "hyprctl activewindow -j | tr -d ' \\n' | grep -q '\"floating\":true'")
        hyprland.send_key("meta_l-v")  # tile again
        hypr_until(hyprland, "hyprctl activewindow -j | tr -d ' \\n' | grep -q '\"floating\":false'")

        hyprland.send_key("meta_l-f")  # fullscreen
        hypr_until(hyprland, "hyprctl activewindow -j | tr -d ' \\n' | grep -qE '\"fullscreen\":[12]'")
        hyprland.send_key("meta_l-f")
        hypr_until(hyprland, "hyprctl activewindow -j | tr -d ' \\n' | grep -q '\"fullscreen\":0'")

        hyprland.send_key("meta_l-q")  # close
        hypr_until(hyprland, "! hyprctl clients -j | tr -d ' \\n' | grep -q '\"class\":\"kitty\"'")

    with subtest("hyprland: scratchpad holds a window and toggles"):
        hyprland.send_key("meta_l-ret")
        hypr_until(hyprland, "hyprctl clients -j | tr -d ' \\n' | grep -q '\"class\":\"kitty\"'")
        hyprland.send_key("meta_l-shift-grave_accent")  # send to scratchpad (it appears)
        hypr_until(hyprland, "hyprctl clients -j | tr -d ' \\n' | grep -q '\"name\":\"special:scratch\"'")
        hypr_until(hyprland, "hyprctl monitors -j | tr -d ' \\n' | grep -q '\"specialWorkspace\":{\"id\":-[0-9]*,\"name\":\"special:scratch\"'")
        hyprland.send_key("meta_l-grave_accent")  # hide it
        hypr_until(hyprland, "! hyprctl monitors -j | tr -d ' \\n' | grep -q '\"specialWorkspace\":{\"id\":-[0-9]*,\"name\":\"special:scratch\"'")
        hyprland.send_key("meta_l-grave_accent")  # and bring it back
        hypr_until(hyprland, "hyprctl monitors -j | tr -d ' \\n' | grep -q '\"specialWorkspace\":{\"id\":-[0-9]*,\"name\":\"special:scratch\"'")
        user_sh(hyprland, "pkill kitty || true")
        hypr_until(hyprland, "! hyprctl clients -j | tr -d ' \\n' | grep -q '\"class\":\"kitty\"'")

    with subtest("hyprland: launcher and menus open"):
        for keys, namespace in (("meta_l-spc", "rofi"), ("meta_l-shift-e", "rofi"), ("meta_l-slash", "rofi")):
            hyprland.send_key(keys)
            hypr_until(hyprland, "hyprctl layers | grep -q 'namespace: %s'" % namespace)
            hyprland.send_key("esc")
            hypr_until(hyprland, "! hyprctl layers | grep -q 'namespace: %s'" % namespace)

    with subtest("hyprland: notification center toggles"):
        user_sh(hyprland, "notify-send -a Test Hello 'from the test'", WAYLAND_ENV)
        hyprland.send_key("meta_l-n")
        hypr_until(hyprland, "hyprctl layers | grep -q 'namespace: swaync-control-center'")
        hyprland.screenshot("hyprland-notification-center")
        hyprland.send_key("meta_l-n")

    with subtest("hyprland: clipboard history records copies"):
        user_sh(hyprland, "wl-copy clipboard-marker-4711", WAYLAND_ENV)
        hyprland.wait_until_succeeds(
            as_user("cliphist list | grep -q clipboard-marker-4711", WAYLAND_ENV), timeout=30)

    with subtest("hyprland: screenshots are saved"):
        user_sh(hyprland, "screenshot output", HYPR_ENV)
        hyprland.wait_until_succeeds(as_user("ls ~/Pictures/Screenshots/*.png"), timeout=60)

    with subtest("hyprland: night light toggles"):
        user_sh(hyprland, "nightlight", HYPR_ENV)
        user_sh(hyprland, "test -e $XDG_RUNTIME_DIR/nightlight-on")
        user_sh(hyprland, "nightlight", HYPR_ENV)
        user_sh(hyprland, "! test -e $XDG_RUNTIME_DIR/nightlight-on")

    with subtest("hyprland: apps receive the session theme"):
        # Imported into the user manager, so services and D-Bus-activated apps get it too.
        env = user_sh(hyprland, "systemctl --user show-environment")
        for var in ("GTK_THEME=adw-gtk3-catppuccin-macchiato:dark", "QT_QPA_PLATFORMTHEME=qt6ct", "XCURSOR_THEME="):
            assert var in env, var + " missing from the user manager environment"
        hyprland.send_key("meta_l-e")  # Nautilus (GTK4/libadwaita), launched by the bind
        hypr_until(hyprland, "hyprctl clients -j | tr -d ' \\n' | grep -q 'org.gnome.Nautilus'", timeout=90)
        # ...and the app itself runs with the themed environment.
        procs = hyprland.succeed(
            "for p in $(pgrep -u leyton -f '^nautilus'); do"
            " echo \"$p $(tr '\\0' '\\n' < /proc/$p/environ | grep '^GTK_THEME=')\"; done")
        print("nautilus processes:", procs)
        assert "GTK_THEME=adw-gtk3-catppuccin-macchiato:dark" in procs, procs
        hyprland.sleep(5)
        hyprland.screenshot("hyprland-nautilus")
        hyprland.send_key("meta_l-q")

    with subtest("hyprland: lock screen locks, a wrong password is refused, the right one unlocks"):
        hyprland.send_key("meta_l-l")
        hyprland.wait_until_succeeds("pgrep -u leyton hyprlock", timeout=60)
        hyprland.sleep(4)
        hyprland.screenshot("hyprland-lock")
        hyprland.send_chars("not-the-password\n")
        hyprland.sleep(3)
        hyprland.succeed("pgrep -u leyton hyprlock")  # still locked
        hyprland.send_chars("test\n")
        hyprland.wait_until_fails("pgrep -u leyton hyprlock", timeout=60)

    with subtest("hyprland: wallpaper picker opens and closes"):
        hyprland.send_key("meta_l-w")
        hypr_until(hyprland, "hyprctl layers | grep -q 'namespace: rofi'")
        hyprland.screenshot("hyprland-wallpaper-picker")
        hyprland.send_key("esc")

    with subtest("hyprland: still healthy after all of that"):
        failed = user_sh(hyprland, "systemctl --user list-units --state=failed --no-legend --plain")
        assert failed.strip() == "", failed
        assert hypr_sh(hyprland, "hyprctl configerrors").strip() in ("", "no errors")

    # ------------------------------------------------------------------------

    with subtest("gnome: session starts"):
        gnome.wait_for_unit("graphical.target")
        gnome.wait_for_file("/run/user/1000/bus")
        gnome.wait_until_succeeds("pgrep -u leyton gnome-shell", timeout=180)
        unit_active(gnome, "graphical-session.target", timeout=180)

    with subtest("gnome: none of the Hyprland session services start"):
        gnome.sleep(20)  # a leaked unit would have started by now
        active = user_sh(gnome, "systemctl --user list-units --state=active,activating --no-legend --plain")
        print(active)
        leaked = [u for u in SESSION_UNITS if (u + ".service") in active]
        assert not leaked, "Hyprland units running under GNOME: %s" % leaked
        assert "hyprland-session.target" not in active

    with subtest("gnome: gnome-shell still owns notifications"):
        owner = user_sh(gnome, "busctl --user status org.freedesktop.Notifications")
        assert "gnome-shell" in owner, owner

    with subtest("gnome: Hyprland's settings did not leak into GNOME's"):
        # Hyprland's cursor sync would have written these into the shared dconf.
        theme = user_sh(gnome, "gsettings get org.gnome.desktop.interface gtk-theme").strip()
        assert theme == "'adw-gtk3'", theme
        env = user_sh(gnome, "systemctl --user show-environment")
        for var in ("GTK_THEME=adw-gtk3-", "QT_QPA_PLATFORMTHEME=qt6ct", "HYPRLAND_INSTANCE_SIGNATURE"):
            assert var not in env, var + " leaked into the GNOME session environment"

    gnome.screenshot("gnome-desktop")
  '';
}
