# modules/home-manager/programs/rofi.nix
# Rofi launcher (Wayland).
# Nix-native: we generate a base config inspired by Symphony, without theme system.

{ pkgs, ... }:

{
    home.packages = [ pkgs.rofi ];

  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
        modi: "drun";
        show-icons: true;
        display-drun: "";
        drun-display-format: "{name}";
        disable-history: false;
        hide-scrollbar: true;
        sidebar-mode: false;
        terminal: "kitty";
        font: "FiraCode Nerd Font 11";
    }

    * {
        background: rgba(0, 0, 0, 0);
        background-alt: rgba(0, 0, 0, 0);
        foreground: rgba(255, 255, 255, 0.97);
        selected: rgba(255, 255, 255, 0.10);
        active: rgba(255, 255, 255, 0.10);
        urgent: rgba(255, 85, 85, 0.67);
        border-colour: rgba(255, 255, 255, 0.10);
        separatorcolor: transparent;
        background-color: transparent;
        text-color: @foreground;
    }

    window {
        transparency: "real";
        location: center;
        anchor: center;
        fullscreen: false;
        width: 350px;
        border-radius: 10px;
        cursor: "default";
        background-color: rgba(20, 20, 20, 0.70);
        border: 1px solid;
        border-color: rgba(255, 255, 255, 0.10);
    }

    mainbox {
        enabled: true;
        spacing: 0px;
        margin: 0px;
        padding: 16px;
        background-color: transparent;
        children: [ "inputbar", "listview" ];
    }

    inputbar {
        enabled: true;
        spacing: 10px;
        margin: 0px 0px 12px 0px;
        padding: 10px 14px;
        border-radius: 8px;
        background-color: rgba(255, 255, 255, 0.10);
        border: 1px solid;
        border-color: rgba(255, 255, 255, 0.15);
        text-color: @foreground;
        children: [ "prompt", "entry" ];
    }

    entry {
        enabled: true;
        background-color: transparent;
        text-color: inherit;
        cursor: text;
        placeholder: "Search apps...";
        placeholder-color: rgba(255, 255, 255, 0.50);
    }

    listview {
        enabled: true;
        columns: 1;
        lines: 5;
        cycle: true;
        dynamic: true;
        scrollbar: false;
        layout: vertical;
        reverse: false;
        fixed-height: true;
        fixed-columns: true;
        spacing: 3px;
        background-color: transparent;
        text-color: @foreground;
        cursor: "default";
    }

    element {
        enabled: true;
        spacing: 10px;
        margin: 0px;
        padding: 8px 10px;
        border-radius: 6px;
        background-color: transparent;
        text-color: @foreground;
        cursor: pointer;
    }

    element selected.normal {
        background-color: rgba(255, 255, 255, 0.15);
        text-color: @foreground;
    }

    element-icon {
        background-color: transparent;
        text-color: inherit;
        size: 28px;
        cursor: inherit;
    }
  '';
}
