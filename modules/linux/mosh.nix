{ lib, ... }:

let
  inherit (lib.lists) singleton;
in
{
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  # Reachable over the tailnet only.
  networking.firewall.interfaces.tailscale0.allowedUDPPortRanges = singleton {
    # Mosh's default range.
    from = 60000;
    to = 61000;
  };
}
