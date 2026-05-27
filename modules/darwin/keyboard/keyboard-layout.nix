{ inputs, ... }:

{
  homebrew.casks = [ "ukelele" ];

  # Function form so the inner `lib` is home-manager's module lib, which carries
  # `lib.hm`.
  home-manager.sharedModules = [
    (
      { lib, ... }:
      {
        home.activation.installKeylayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Library/Keyboard Layouts"
          cp -f ${inputs.tangent}/mac/Tangent-Gallium.keylayout "$HOME/Library/Keyboard Layouts/Tangent Gallium.keylayout"
          cp -f ${inputs.tangent}/mac/Kuntem-JQ.keylayout "$HOME/Library/Keyboard Layouts/Kuntem-JQ.keylayout"
        '';
      }
    )
  ];
}
