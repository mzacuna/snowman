{ ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    # Rename pre-existing files instead of failing activation when home-manager
    # wants to manage a path that already exists.
    backupFileExtension = "backup";
  };
}
