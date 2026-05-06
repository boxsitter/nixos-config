# modules/home-manager/gnome.nix
# GNOME preferences and desktop theming managed via Home Manager.

{ pkgs, ... }:

{
  # GTK theming
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  # Prevent catppuccin from injecting CSS into GTK4 (avoids mismatched headerbars)
  xdg.configFile."gtk-4.0/gtk.css".text = "";

  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/wm/preferences" = {
        # Buttons on the right; left side empty (before the ':').
        button-layout = ":minimize,maximize,close";
      };

      # Enable user extensions
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "dash-to-dock@micxgx.gmail.com"
          "tactile@lundal.io"
          # gSnap removed: crashes GNOME Shell on login with:
          # JS ERROR: TypeError: can't access property Symbol.iterator,
          # this.connected.changed is undefined (extension.js:1580)
          # The extension is abandoned and incompatible with current GNOME.
        ];
      };

      # Dash to Dock: auto-hide enabled
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-fixed = false;
        autohide = true;
      };

      # Tactile: 3-zone layout (25% | 50% | 25%) on a single row
      # col-1 = 2 makes the centre column twice as wide as the sides
      # row-1 = 0 removes the second row so there is only one horizontal band
      "org/gnome/shell/extensions/tactile" = {
        col-0 = 1;
        col-1 = 2;
        col-2 = 1;
        col-3 = 0;
        row-0 = 1;
        row-1 = 0;
      };

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3";
        icon-theme = "Papirus-Dark";
        font-antialiasing = "rgba";
        font-hinting = "slight";
      };

      # Background (Catppuccin Macchiato base/mantle)
      "org/gnome/desktop/background" = {
        primary-color = "#24273a";
        secondary-color = "#1e2030";
      };

      # ── App drawer folder organization ─────────────────────────────────────
      # Apps not listed in any folder appear in the drawer root.
      # Folder order in the drawer matches folder-children order.
      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "Internet" "Media" "Graphics" "Office" "Development" "System" "Downloads"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Internet" = {
        name = "Internet";
        apps = [
          "firefox.desktop"
          "chromium-browser.desktop"
          "legcord.desktop"
          "org.remmina.Remmina.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Media" = {
        name = "Media";
        apps = [
          "vlc.desktop"
          "org.gnome.Showtime.desktop"
          "org.gnome.Decibels.desktop"
          "com.obsproject.Studio.desktop"
          "org.kde.kdenlive.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Graphics" = {
        name = "Graphics";
        apps = [
          "gimp.desktop"
          "org.gnome.Loupe.desktop"
          "org.flameshot.Flameshot.desktop"
          "org.gpick.gpick.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Office" = {
        name = "Office";
        apps = [
          "onlyoffice-desktopeditors.desktop"
          "org.gnome.Papers.desktop"
          "org.gnome.Calendar.desktop"
          "org.gnome.clocks.desktop"
          "org.gnome.Calculator.desktop"
          "org.gnome.TextEditor.desktop"
          "org.gnome.Characters.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Development" = {
        name = "Development";
        apps = [
          "code.desktop"
          "jetbrains-toolbox.desktop"
          "ca.desrt.dconf-editor.desktop"
          "com.github.hluk.copyq.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/System" = {
        name = "System";
        apps = [
          "org.gnome.Settings.desktop"
          "org.gnome.Nautilus.desktop"
          "kitty.desktop"
          "org.gnome.Console.desktop"
          "org.gnome.DiskUtility.desktop"
          "org.gnome.SystemMonitor.desktop"
          "org.gnome.baobab.desktop"
          "org.gnome.Logs.desktop"
          "org.gnome.tweaks.desktop"
          "org.gnome.Extensions.desktop"
          "org.gnome.Sysprof.desktop"
          "org.gnome.Software.desktop"
          "org.gnome.Snapshot.desktop"
          "nvidia-settings.desktop"
          "auto-cpufreq-gtk.desktop"
          "org.pulseaudio.pavucontrol.desktop"
          "org.freedesktop.Piper.desktop"
          "btop.desktop"
          "insync.desktop"
          "1password.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Downloads" = {
        name = "Downloads";
        apps = [
          "org.qbittorrent.qBittorrent.desktop"
          "com.github.persepolisdm.persepolis.desktop"
          "org.nickvision.tubeconverter.desktop"
        ];
      };
    };
  };

  # ── Hide apps that should stay installed but not clutter the drawer ────────
  # Creates a user-level .desktop override in ~/.local/share/applications/ with
  # NoDisplay=true, which shadows the system entry for that app.
  xdg.desktopEntries = {
    # Terminal / TUI tools — launch from a terminal instead
    "htop"                                       = { name = "htop";                          noDisplay = true; };
    "nnn"                                        = { name = "nnn";                           noDisplay = true; };
    "vim"                                        = { name = "Vim";                           noDisplay = true; };
    "gvim"                                       = { name = "GVim";                          noDisplay = true; };
    "xterm"                                      = { name = "xterm";                         noDisplay = true; };

    # GTK developer demos — not useful as desktop apps
    "gtk3-demo"                                  = { name = "GTK 3 Demo";                    noDisplay = true; };
    "gtk3-icon-browser"                          = { name = "GTK 3 Icon Browser";            noDisplay = true; };
    "gtk3-widget-factory"                        = { name = "GTK 3 Widget Factory";          noDisplay = true; };

    # GNOME internals, file-handlers, and background-service helpers
    "bluetooth-sendto"                           = { name = "Bluetooth Send File";           noDisplay = true; };
    "code-url-handler"                           = { name = "VS Code URL Handler";           noDisplay = true; };
    "cups"                                       = { name = "CUPS";                          noDisplay = true; };
    "gcm-calibrate"                              = { name = "Color Calibration";             noDisplay = true; };
    "gcm-import"                                 = { name = "Color Profile Import";          noDisplay = true; };
    "gcm-picker"                                 = { name = "Color Picker";                  noDisplay = true; };
    "geoclue-where-am-i"                         = { name = "Where Am I";                    noDisplay = true; };
    "gnome-disk-image-mounter"                   = { name = "Disk Image Mounter";            noDisplay = true; };
    "gnome-disk-image-writer"                    = { name = "Disk Image Writer";             noDisplay = true; };
    "gnome-initial-setup"                        = { name = "Initial Setup";                 noDisplay = true; };
    "gnome-system-monitor-kde"                   = { name = "System Monitor (KDE)";          noDisplay = true; };
    "gnome-user-share-webdav"                    = { name = "Personal File Sharing";         noDisplay = true; };
    "insync-helper"                              = { name = "Insync Helper";                 noDisplay = true; };
    "nautilus-autorun-software"                  = { name = "Autorun Software";              noDisplay = true; };
    "nixos-manual"                               = { name = "NixOS Manual";                  noDisplay = true; };
    "nm-applet"                                  = { name = "Network Manager Applet";        noDisplay = true; };
    "nm-connection-editor"                       = { name = "Network Connections";           noDisplay = true; };
    "rygel"                                      = { name = "Rygel";                         noDisplay = true; };
    "rygel-preferences"                          = { name = "Rygel Preferences";             noDisplay = true; };
    "user-dirs-update-gtk"                       = { name = "User Dirs Update";              noDisplay = true; };
    "xdg-desktop-portal-gnome"                  = { name = "GNOME Desktop Portal";          noDisplay = true; };
    "xdg-desktop-portal-gtk"                    = { name = "GTK Desktop Portal";            noDisplay = true; };
    "org.freedesktop.IBus.Panel.Emojier"        = { name = "IBus Emoji";                    noDisplay = true; };
    "org.freedesktop.IBus.Panel.Extension.Gtk3" = { name = "IBus GTK Extension";            noDisplay = true; };
    "org.freedesktop.IBus.Panel.Wayland.Gtk3"   = { name = "IBus Wayland Panel";            noDisplay = true; };
    "org.freedesktop.IBus.Setup"                = { name = "IBus Setup";                    noDisplay = true; };
    "org.gnome.BrowserConnector"                = { name = "GNOME Browser Connector";       noDisplay = true; };
    "org.gnome.ColorProfileViewer"              = { name = "Color Profile Viewer";          noDisplay = true; };
    "org.gnome.Evolution-alarm-notify"          = { name = "Evolution Alarm";               noDisplay = true; };
    "org.gnome.evolution-data-server.OAuth2-handler" = { name = "Evolution OAuth2";         noDisplay = true; };
    "org.gnome.OnlineAccounts.OAuth2"           = { name = "Online Accounts OAuth2";        noDisplay = true; };
    "org.gnome.Papers-previewer"                = { name = "Papers Previewer";              noDisplay = true; };
    "org.gnome.RemoteDesktop.Handover"          = { name = "Remote Desktop Handover";       noDisplay = true; };
    "org.gnome.Shell.Extensions"               = { name = "Shell Extensions";              noDisplay = true; };
    "org.gnome.Shell.PortalHelper"             = { name = "Portal Helper";                 noDisplay = true; };
  };
}
