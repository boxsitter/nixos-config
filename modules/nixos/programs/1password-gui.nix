# modules/nixos/programs/1password-gui.nix
# 1Password GUI application

{ ... }:

{
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "leyton" ];
  };
}
