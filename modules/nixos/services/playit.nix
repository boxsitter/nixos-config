# modules/nixos/services/playit.nix
# Playit.gg tunnel for exposing Minecraft server to custom domain

{ ... }:

{
  services.playit = {
    enable = true;
    user = "playit";
    group = "playit";
    # Path to the secret file (needs to be set up imperatively first)
    secretPath = "/var/lib/playit/playit.toml";
  };

  # Create the secret directory
  systemd.tmpfiles.rules = [
    "d /var/lib/playit 0755 playit playit -"
  ];
}
