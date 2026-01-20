# hosts/desktop/leyton.nix
# User configuration for leyton on desktop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
  ];

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
