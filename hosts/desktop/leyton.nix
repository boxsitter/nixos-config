# hosts/desktop/leyton.nix
# User configuration for leyton on desktop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/hyprland
  ];

  # Desktop Hyprland: RTX 5080, single all-NVIDIA render path (no iGPU). Loaded
  # last, after the shared modules (see hyprland.nix).
  wayland.windowManager.hyprland.extraLuaFiles."90-host" = ''
    -- Samsung Odyssey G9 Neo (G95NC), 7680x2160 @ 240 Hz. "preferred" would pick
    -- the EDID's 3840x1080@60 fallback, so the mode is spelled out. Scale 1.25
    -- gives an exact 6144x1728 logical desktop.
    hl.monitor({ output = "DP-4", mode = "7680x2160@240", position = "0x0", scale = 1.25 })
    -- Anything else that gets plugged in.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    -- Tiling for the 32:9 screen: the first window is the "master". One window
    -- fills the screen and two split it 50/50, as in dwindle. From three windows
    -- on, the master sits in the middle at half the screen width (16:9 here) and
    -- the others stack on either side. (Dwindle stays the default elsewhere.)
    hl.config({
      general = { layout = "master" },
      master = {
        orientation = "center",
        center_master_fallback = "left", -- with one or two windows
        slave_count_for_center_master = 2,
        mfact = 0.5,
        new_status = "slave",
      },
    })
    -- Dwindle's split toggle means nothing here; promote to the center instead.
    hl.unbind("SUPER + backslash")
    hl.bind("SUPER + backslash", hl.dsp.layout("swapwithmaster"),
      { description = "Swap with master (center)" })

    -- Claude Desktop is only installed here (programs.claude-desktop).
    hl.bind("SUPER + A", hl.dsp.exec_cmd("claude-desktop"), { description = "Claude" })

    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")

    hl.config({
      -- Software cursor sidesteps the NVIDIA cursor glitches; try removing this
      -- once the session has proven stable.
      cursor = { no_hardware_cursors = true },
      -- Same flat pointer acceleration the GNOME session uses on this machine.
      input = { accel_profile = "flat", sensitivity = 0 },
    })
  '';

  dconf.settings = {
    # "org/gnome/desktop/interface" = {
    #   text-scaling-factor = 1.5;
    # };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      speed = 0.0;
    };
  };

  home.sessionVariables = {
    XCURSOR_SIZE = "24";
  };
}
