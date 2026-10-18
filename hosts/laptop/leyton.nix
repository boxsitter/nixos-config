# hosts/laptop/leyton.nix
# User configuration for leyton on laptop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/hyprland
  ];

  home.sessionVariables = {
    XCURSOR_SIZE = "14";
  };

  # Laptop-specific overrides
  programs.kitty.font.size = 11;  # Slightly smaller for laptop screen

  # Laptop Hyprland: Dell XPS 15 9530, Intel iGPU + NVIDIA RTX 3050 (PRIME
  # offload, RTD3). Loaded last, after the shared modules (see hyprland.nix).
  #
  # GPU: by default aquamarine picks the GPU that drives the built-in panel
  # (the Intel iGPU) as primary and keeps the NVIDIA one available for offload,
  # which also leaves every output usable. That means the NVIDIA card is opened
  # and may not reach RTD3 sleep while Hyprland runs. For best battery, flip
  # iGpuOnly: Hyprland then touches only the iGPU (via the /dev/dri/igpu udev
  # symlink from hosts/laptop/configuration.nix; if that link is missing it
  # silently falls back to auto-detect, never to a dead session). The catch:
  # displays wired to the NVIDIA GPU stop working in that mode. Measure with
  #   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
  # inside a Hyprland session ("suspended" is the goal at idle).
  wayland.windowManager.hyprland.extraLuaFiles."90-host" =
    let
      iGpuOnly = false;
    in
    ''
      -- Internal panel. Confirm mode/scale with `hyprctl monitors`.
      local internal = { output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.5 }
      hl.monitor(internal)
      -- Anything else plugged in: native scale, placed to the right.
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

      ${if iGpuOnly then ''
      local igpu = "/dev/dri/igpu"
      local f = io.open(igpu, "r")
      if f then
        f:close()
        hl.env("AQ_DRM_DEVICES", igpu)
      end
      '' else ""}
      -- Bottom-zone clicks, matching services.libinput.touchpad.clickMethod.
      hl.config({ input = { touchpad = { clickfinger_behavior = false } } })

      -- Lid: with an external display attached, logind treats the machine as
      -- docked and ignores the lid, so turn the internal panel off ourselves
      -- (and back on when it opens). With no external display, logind suspends
      -- as usual and we do nothing.
      hl.bind("switch:on:Lid Switch", function()
        for _, m in ipairs(hl.get_monitors()) do
          if m.name ~= internal.output then
            hl.monitor({ output = internal.output, disabled = true })
            return
          end
        end
      end, { locked = true })
      hl.bind("switch:off:Lid Switch", function()
        hl.monitor(internal)
      end, { locked = true })
    '';

  # Suspend after 20 minutes idle (the desktop never suspends). Merges with the
  # shared dim/lock/screen-off listeners from modules/home-manager/hyprland/lock.nix.
  services.hypridle.settings.listener = [
    {
      timeout = 1200; # 20 min → suspend
      on-timeout = "systemctl suspend";
    }
  ];
}
