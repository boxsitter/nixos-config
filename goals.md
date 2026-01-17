My goals for this config that I haven't yet implemented

- [ ] Global, robust cattpuccin machiato theming
  - [ ] Blurring kitty and vscode background with blur my shell on gnome (not needed
    on hyprland)
    - Notes / approach:
      - GNOME: install `Blur my Shell` via `gnomeExtensions.*` (in NixOS or HM), and set extension prefs via `dconf.settings`.
      - Kitty: enable transparency in kitty + let GNOME blur behind (blur happens in the compositor/extension).
      - VS Code: blur isn’t “native”; you usually rely on window transparency + compositor blur, or keep it opaque and only theme colors.
  - [ ] Cattpuccin just to start, I want to implement a theme switcher with various
    themes eventually
    - Notes / approach:
      - Start with one theme module (Catppuccin Macchiato) and make everything read from it.
      - For switching later, simplest robust approach is NixOS `specialisation` (multiple pre-built variants you can boot/switch to).
        Alternative: multiple HM “profiles” and a small wrapper script that activates a chosen generation.
  - [ ] Wallpaper switcher (package wallpapers in config repo)
    - Notes / approach:
      - Put wallpapers under a repo folder (e.g. `wallpapers/…`) and deploy via `home.file` (HM) to `~/Pictures/Wallpapers`.
      - GNOME: set wallpaper with `dconf.settings` keys under `org.gnome.desktop.background`.
      - Hyprland: use `swww`/`hyprpaper` and wire a small script + keybind; keep the “selected wallpaper” path in one variable.

- [ ] Fix missing icons across os
  - Notes / approach:
    - Ensure a baseline icon theme is installed everywhere you expect a GUI (e.g. `adwaita-icon-theme`, `hicolor-icon-theme`).
    - Set explicit `gtk.iconTheme` (HM) and GNOME `org.gnome.desktop.interface icon-theme` (via `dconf.settings`).
    - If icons are missing in tray/Wayland apps, also verify `xdg.portal` + the right portal backend is enabled per DE/WM.
- [ ] Hide program icons I don't use in app library (if possible)
  - Notes / approach:
    - GNOME menu entries are `.desktop` files. You can “hide” them per-user by overriding the desktop entry in
      `~/.local/share/applications` with `NoDisplay=true` (or `Hidden=true`).
    - In HM, you can deploy overrides via `home.file` (copy a modified `.desktop` file) or create your own `xdg.desktopEntries`.
- [ ] 1Password, Tailscale, CPU temp and usage widgets in top bar
  - Notes / approach:
    - GNOME: this is typically shell extensions + (sometimes) AppIndicator support.
      - CPU/temp: an extension like “Vitals” + ensure sensors tooling (`lm_sensors`) is present.
      - 1Password: may require an AppIndicator/KStatusNotifier extension for tray indicators, depending on how 1Password exposes it.
      - Tailscale: often easiest is a simple status indicator extension or a lightweight “custom menu” extension that runs `tailscale status`.
    - Hyprland: implement in Waybar (cpu/thermal modules + a `custom/*` script that prints Tailscale status).
- [ ] Add gnome extension for dock that auto- [ ]hides
  - Notes / approach:
    - Use a known dock extension (e.g. “Dash to Dock”) installed declaratively, then configure autohide/intellihide via `dconf.settings`.
- [ ] Migrate from the GNOME greeter (GDM) to an aesthetic but minimal text-based greeter
  - Notes / approach:
    - Most common NixOS path is `greetd` + `tuigreet` (terminal UI login) as a replacement for `services.xserver.displayManager.gdm`.
    - Implementation sketch:
      - Disable GDM and enable greetd in a NixOS module (likely `modules/nixos/services/gnome.nix` or your host config).
      - Configure `services.greetd.settings.default_session.command` to launch your session:
        - GNOME: `dbus-run-session gnome-session`
        - Hyprland: `Hyprland` (or a wrapper script)
    - Gotchas:
      - GNOME is most “plug-and-play” with GDM; with greetd you may need to double-check automatic keyring unlock / PAM integration.
      - If you rely on Wayland + GNOME features, verify the session starts correctly and that portals/screen lock behave as expected.
- [ ] Better icon theme, cursor theme, and global system fonts
  - Notes / approach:
    - Prefer setting fonts system-wide in NixOS (`fonts.packages`, `fonts.fontconfig.defaultFonts`) so all users/apps benefit.
    - Set cursor + icon theme in HM `gtk.cursorTheme` / `gtk.iconTheme` and mirror in GNOME via `dconf.settings`.
    - Keep these as theme variables so GNOME + Hyprland stay consistent.
- [ ] Look over list of programs on windows desktop to determine what more desktop
  programs I need
  - Notes / approach:
    - Make a “Windows → Nix” mapping list (app name → nix package/module) and decide whether each is:
      - system-wide (`environment.systemPackages` or NixOS module) vs per-user (`home.packages` / HM module)
    - Put host-specific apps in `hosts/<host>/…` and shared desktop apps in `modules/home-manager/desktop-apps.nix`.
- [ ] Make sure laptop is fully optimized (efficient gpu usage, battery saving)
  - Notes / approach:
    - Pick one power stack (GNOME often prefers `power-profiles-daemon`; others prefer `tlp`). Avoid enabling both.
    - For NVIDIA laptops: ensure PRIME/offload is configured (likely in `modules/nixos/hardware/nvidia-laptop.nix`), and verify which GPU is used per app.
    - Add basics: `thermald` (Intel), `auto-cpufreq` (optional), wifi power save tweaks, and suspend/hibernate sanity checks.
- [ ] If possible, make grub display at a specific resolution on all devices without
  scaling so it doesn't get stretched out on my ultrawide monitor.
  - Notes / approach:
    - GRUB: set an explicit gfx mode (EFI vs BIOS differs) and payload keep.
      In NixOS, this is usually done via `boot.loader.grub.*` options and/or `boot.loader.grub.extraConfig`.
    - Verify the monitor’s “preferred” mode vs what firmware exposes; sometimes the firmware only exposes a subset at boot.
  - [ ] Focusrite scarlet drivers
    - Notes / approach:
      - Many Scarlett devices are class-compliant on Linux; start by verifying PipeWire is enabled and working (and `rtkit`).
      - Debug with `lsusb`, `dmesg`, and PipeWire tools; if features are missing, check if your model needs extra quirks/firmware.
- [ ] Need to ensure that all components are present for a complete system. Things
  that are present by default on windows but need to be manually configured on
  nixos. Things that I, as a windows user, take for granted.
  - Notes / approach:
    - Turn this into a checklist module (one file) that you can import on desktop/laptop:
      - printing/scanning, bluetooth, screenshot tool, archive tools, basic viewers, codecs, clipboard, notifications, portals
      - sane defaults for file associations (xdg mime)
    - For each item: decide NixOS service vs HM program, then add a quick “verification command” you can run.

  - [ ] All basic programs that would be stock on windows or integrated in the OS
    are present (media viewer, unzipper, pdf viewer, ect.)
    - Notes / approach:
      - Create a baseline set of packages and keep it minimal but complete (pdf viewer, image viewer, archive manager, media player).
      - Prefer native GNOME apps when on GNOME to reduce theme/integration issues.
    - [ ] All drivers and hardware functionality is present, configured, and
      working. Even minor things like webcam and mic functionality, fingerprint
      reader and advanced touchpad support on my laptop, etc. are fully working
      - Notes / approach:
        - Webcam/mic: verify PipeWire/Pulse routing + permissions; test with a simple GNOME app.
        - Fingerprint: enable `services.fprintd` + enroll; confirm PAM integration.
        - Touchpad: tune `services.libinput` and verify gestures if desired.
        - Make a “hardware smoke test” doc: what to click/run after a rebuild.

- [ ] High-Performance Windows VM for Adobe CC (GPU) & FL Studio (ASIO)
  - Notes / approach:
    - **Architecture:** KVM/QEMU on NixOS + Windows 11 IoT Enterprise LTSC 2024 (Guest).
    - **Hardware Isolation (Host):**
      - Use `vfio-pci` kernel modules in NixOS to isolate the secondary GPU and the specific USB controller for audio.
      - Configure `libvirtd` and `looking-glass-client` permissions declaratively.
    - **Video (Looking Glass):**
      - Setup Looking Glass for low-latency, shared-memory frame buffering (seamless window on Linux desktop).
      - Pass through secondary GPU to VM for native Photoshop/Lightroom AI performance.
    - **Audio (Focusrite/ASIO):**
      - Do not use generic USB passthrough. Identify and pass through the entire PCI USB Controller that the Focusrite connects to.
      - Ensures native ASIO driver performance with zero virtualization crackle/latency.
    - **Windows Installation:**
      - Generate `autounattend.xml` (via Schneegans) to automate install, bypass TPM/OOBE, and inject Generic Key.
      - Use "Emulated TPM 2.0" in `virt-manager` (do not pass through host TPM).
      - Install `virtio` drivers for disk/network and specific drivers for GPU/Looking Glass manually post-install.

- [ ] Need to fix the persistent bug of my desktop not being able to drive my
  7680x2160@240hz monitor above 120hz. This is clearly a software issue since my
  RTX 5080 has no issues driving it in windows. I have narrowed it down to
  driver incompatibility with the level of DSP needed for this bandwidth. It may
  be a configuration issue, but it is likely the fact that the nvidia linux
  drivers just haven't caught up. I need to really pin the issue down though and
  make sure that it is truly out of my hands before I give up.
  - Notes / approach:
    - First confirm the link requirements: 7680×2160@240 typically requires DSC / very high DP bandwidth. Check monitor OSD for DSC + DP mode.
    - Collect facts on Linux:
      - Current session (Wayland vs X11), driver version, connector (DP/HDMI), reported max link rate, and whether DSC is active.
    - Try “bandwidth reducers” to see if 240 becomes available (helps identify where the cap is):
      - 8bpc instead of 10/12bpc, disable HDR, different chroma subsampling if supported, different cable/port.
    - If still capped: test on a newer NVIDIA driver (including beta if you’re comfortable) and track whether it’s a known limitation.
    - Goal is to end with a clear repro + a minimal config snippet you can share upstream (or accept as driver limitation).

- [ ] Organize, simplify, and consolidate entire config. Need to make sure all AI
  artifacts and vibe coding slop is removed to get a truly simplified, modular,
  understandable config that is nix-pure and complies with common practices (not
  janky or using unconventional patterns).
  - Notes / approach:
    - Pick a module boundary rule and stick to it (e.g. `modules/nixos/*` for system services/hardware, `modules/home-manager/*` for user UX).
    - Deduplicate: move repeated host settings into shared modules; keep host files as “wiring” + hardware specifics.
    - Remove dead code: grep for unused modules, TODOs, commented blocks; keep a changelog as you delete.
    - Prefer conventional patterns: `mkOption`/`mkIf` for feature flags, avoid hidden magic in scripts.

- [ ] (Eventual stretch goal) Fully usable hyprland setup as an option along with
  gnome. Aesthetic "rice" theming and config. Needs enough separation from the
  gnome setup to not interfere but share configs if they benefit both desktop
  managers.
  - Notes / approach:
    - Keep DE/WM-specific config isolated behind flags (e.g. `my.desktop.gnome.enable`, `my.desktop.hyprland.enable`).
    - Share only the “neutral” pieces (fonts, theme palette, common CLI tools) and avoid sharing portal/notification stacks.
    - Consider NixOS `specialisation` to switch GNOME/Hyprland without two totally separate host definitions.