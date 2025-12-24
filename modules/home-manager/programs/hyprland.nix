# modules/home-manager/programs/hyprland.nix
# Hyprland (Wayland compositor) user session configuration
# Nix-native translation of Symphony's Hyprland config.

{ pkgs, ... }:

let
  terminal = "kitty";

  # Emergency fallback terminal (minimal + dependable).
  emergencyTerminal = "foot";

  # Nix-managed equivalents for Symphony scripts.
  launchBrowser = pkgs.writeShellScriptBin "hypr-launch-browser" ''
    exec ${pkgs.firefox}/bin/firefox
  '';

  # Simple webapp launcher: uses Firefox in app-like window.
  launchWebapp = pkgs.writeShellScriptBin "hypr-launch-webapp" ''
    set -e
    if test (count $argv) -lt 1
      echo "usage: hypr-launch-webapp <url>" >&2
      exit 2
    end
    set url $argv[1]
    exec ${pkgs.firefox}/bin/firefox --new-window "$url"
  '';

  # Minimal "lock" command (hyprlock will read HM-provisioned config later).
  lockScreen = pkgs.writeShellScriptBin "hypr-lock-screen" ''
    exec ${pkgs.hyprlock}/bin/hyprlock
  '';

  toggleWaybar = pkgs.writeShellScriptBin "hypr-toggle-waybar" ''
    if ${pkgs.procps}/bin/pgrep -x waybar >/dev/null
      ${pkgs.procps}/bin/pkill -x waybar
    else
      exec ${pkgs.waybar}/bin/waybar
    end
  '';

  # Simple powermenu (lock/logout/reboot/poweroff) via rofi.
  powerMenu = pkgs.writeShellScriptBin "hypr-powermenu" ''
    set -l choice (printf "lock\nlogout\nreboot\npoweroff\n" | ${pkgs.rofi-wayland}/bin/rofi -dmenu -p "power")
    switch "$choice"
      case lock
        exec ${pkgs.hyprlock}/bin/hyprlock
      case logout
        exec ${pkgs.hyprland}/bin/hyprctl dispatch exit
      case reboot
        exec ${pkgs.systemd}/bin/systemctl reboot
      case poweroff
        exec ${pkgs.systemd}/bin/systemctl poweroff
      case '*'
        exit 0
    end
  '';

  # Screenshot helpers (minimal, functional).
  screenshot = pkgs.writeShellScriptBin "hypr-screenshot" ''
    set -l mode region
    if test (count $argv) -ge 1
      set mode $argv[1]
    end
    switch "$mode"
      case clipboard
        ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) - | ${pkgs.wl-clipboard}/bin/wl-copy
      case region
        set -l dir "$HOME/Pictures/Screenshots"
        mkdir -p "$dir"
        set -l file "$dir/(date +%Y-%m-%d_%H-%M-%S).png"
        ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) "$file"
      case '*'
        echo "usage: hypr-screenshot [region|clipboard]" >&2
        exit 2
    end
  '';

  # Clipboard history menu using cliphist + rofi.
  clipboardMenu = pkgs.writeShellScriptBin "hypr-clipboard" ''
    set -l selection (${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi-wayland}/bin/rofi -dmenu -p "clipboard")
    test -n "$selection"; or exit 0
    ${pkgs.cliphist}/bin/cliphist decode <<<"$selection" | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  # Show keybindings by dumping current Hyprland binds.
  keyhints = pkgs.writeShellScriptBin "hypr-keyhints" ''
    ${pkgs.hyprland}/bin/hyprctl binds | ${pkgs.rofi-wayland}/bin/rofi -dmenu -i -p "keys" >/dev/null
  '';

  # Toggle idle inhibitor by stopping/starting hypridle.
  toggleIdle = pkgs.writeShellScriptBin "hypr-toggle-idle" ''
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet hypridle
      ${pkgs.systemd}/bin/systemctl --user stop hypridle
    else
      ${pkgs.systemd}/bin/systemctl --user start hypridle
    end
  '';

  osdClient = pkgs.writeShellScriptBin "hypr-osdclient" ''
    # Keep it simple for now; Symphony uses swayosd-client per-focused monitor.
    exec ${pkgs.swayosd}/bin/swayosd-client $argv
  '';

  # Polkit agent for Hyprland sessions (GNOME provides one; Hyprland needs it).
  polkitAgent = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      # --- Environment (from Symphony envs.conf; keep only functional bits) ---
      env = [
        # Editors / misc
        "EDITOR,nvim"

        # Cursor sizes
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"

        # Wayland preference
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "OZONE_PLATFORM,wayland"
        "XDG_SESSION_TYPE,wayland"

        # Portals/screenshare expectations
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"

        # NVIDIA bits that are harmless if unused
        "NVD_BACKEND,direct"
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];

      # --- Monitors ---
      # Safe default: apply preferred mode to whatever outputs exist.
      # This avoids getting stuck with a black screen due to mismatched connector names.
      monitor = [
        ",preferred,auto,1"
      ];

      # --- Autostart (from Symphony autostart.conf; minimal functional set) ---
      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user import-environment"

        # Clipboard persistence/history
        "wl-paste --watch cliphist store"

        # Polkit agent
        polkitAgent

        # Idle daemon + lock integration
        "${pkgs.hypridle}/bin/hypridle"

        # OSD server
        "${pkgs.swayosd}/bin/swayosd-server"

        # Set cursor (as Symphony)
        "hyprctl setcursor Bibata-Modern-Ice 24"

        # Delay waybar slightly
        "sleep 1 && ${pkgs.waybar}/bin/waybar"
      ];

      # --- Variables used by binds (translated from Symphony bindings.conf) ---
      "$terminal" = terminal;
      "$browser" = "${launchBrowser}/bin/hypr-launch-browser";
      "$webapp" = "${launchWebapp}/bin/hypr-launch-webapp";
      "$lock" = "${lockScreen}/bin/hypr-lock-screen";
      "$toggleIdle" = "${toggleIdle}/bin/hypr-toggle-idle";
      "$toggleWaybar" = "${toggleWaybar}/bin/hypr-toggle-waybar";
      "$powermenu" = "${powerMenu}/bin/hypr-powermenu";
      "$screenshot" = "${screenshot}/bin/hypr-screenshot";
      "$clipboard" = "${clipboardMenu}/bin/hypr-clipboard";
      "$keyhints" = "${keyhints}/bin/hypr-keyhints";
      "$osdclient" = "${osdClient}/bin/hypr-osdclient";

      # --- Keybinds (start with core, safe subset; expand iteratively) ---
      bind = [
        # Core app launch
        "SUPER,RETURN,exec,${terminal}"
        "SUPER SHIFT,RETURN,exec,${emergencyTerminal}"
        "SUPER,B,exec,$browser"
        "SUPER,E,exec,${pkgs.nautilus}/bin/nautilus --new-window"
        "SUPER,N,exec,${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw"

        # Launchers / rofi tools
        "SUPER,SPACE,exec,pkill rofi || ${pkgs.rofi-wayland}/bin/rofi -show drun"
        "ALT,comma,exec,$clipboard"
        "ALT,SPACE,exec,pkill rofi || ${pkgs.rofi-wayland}/bin/rofi -show drun"

        # Window management
        "SUPER,Q,killactive,"

        # Lock / idle
        "SUPER SHIFT,L,exec,$lock"
        "SUPER CTRL,I,exec,$toggleIdle"

        # Toggle bar
        "SUPER SHIFT,SPACE,exec,$toggleWaybar"

        # Power menu
        "SUPER,ESCAPE,exec,$powermenu"

        # Kill helper
        "SUPER SHIFT,K,exec,hyprctl kill"

        # Key hints
        "SUPER,K,exec,$keyhints"

        # Screenshots
        "SUPER,P,exec,$screenshot region"
        "SHIFT,PRINT,exec,$screenshot clipboard"

        # Color picker (core tool, handy)
        "SUPER SHIFT,P,exec,${pkgs.procps}/bin/pkill hyprpicker || ${pkgs.hyprpicker}/bin/hyprpicker -a"

        # Monitor toggles from Symphony monitors.conf
        "SUPER ALT,H,exec,hyprctl keyword monitor 'eDP-1,disable'"
        "SUPER ALT,l,exec,hyprctl keyword monitor 'eDP-1, preferred, 0x0, 1'"
      ];

      # Mouse/media keys and special binds can be added later.
    };
  };

  # Packages required for the minimal translated config to function.
  home.packages = with pkgs; [
    hypridle                # Idle daemon (lock/suspend timers)
    hyprlock                # Lock screen used by Hyprland sessions
    foot                    # Emergency fallback terminal (simple + reliable)
    wl-clipboard            # Wayland clipboard utilities (wl-copy/wl-paste)
    cliphist                # Clipboard history backend (pairs with rofi)
    swayosd                 # On-screen display (volume/brightness popups)
    polkit_gnome            # Polkit authentication agent (GUI sudo prompts)
    jq                      # JSON parser (used by scripts/diagnostics)
    nautilus                # File manager
    grim                    # Screenshot tool for Wayland
    slurp                   # Region selection tool (used with grim)
    hyprpicker              # Color picker
    procps                  # Provides pgrep/pkill used by toggle scripts
  ];

  # Cursor theme used by `hyprctl setcursor ...`.
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    size = 24;
    package = pkgs.bibata-cursors;
  };

  # Ensure rofi sees the expected terminal.
  home.sessionVariables = {
    TERMINAL = terminal;
  };
}
