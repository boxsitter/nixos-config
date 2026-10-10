# modules/home-manager/programs/micro.nix
# Micro terminal editor configuration

{ osConfig, lib, ... }:

let
  # NixOS-WSL sets `wsl.enable = true`; absent (→ false) on every other host.
  isWSL = osConfig.wsl.enable or false;
in
{
  # The "simple" colorscheme defines no `default` color group, so micro leaves
  # the editing area at the terminal's default fg/bg. That keeps the background
  # transparent (so Windows Terminal's acrylic blur shows through) and makes all
  # syntax colors resolve to the terminal's own ANSI palette instead of micro's
  # built-in truecolor scheme, which paints a solid background over the blur.
  #
  # clipboard: on graphical hosts the default "external" backend talks directly
  # to the Wayland/X clipboard (full read+write, no size caps), so it's left
  # alone. Under WSL there is no such clipboard to reach, and micro's "external"
  # backend silently falls back to an internal buffer while still reporting
  # "Copied"; "terminal" instead copies via OSC 52 escape sequences, which
  # Windows Terminal accepts and routes to the real Windows clipboard.
  xdg.configFile."micro/settings.json".text = builtins.toJSON (
    { colorscheme = "simple"; }
    // lib.optionalAttrs isWSL { clipboard = "terminal"; }
  );
}