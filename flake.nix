{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            flutter
            google-chrome

            # build tools
            clang
            cmake
            ninja
            pkg-config

            # flutter linux deps
            gtk3
            libepoxy
            libmpv

            # runtime
            wayland
            libxkbcommon
          ];

          shellHook = ''
            echo "Flutter dev shell ready"

            export CHROME_EXECUTABLE=zen-beta
            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath [
                pkgs.libmpv
                pkgs.gtk3
                pkgs.libepoxy
              ]
            }:$LD_LIBRARY_PATH
          '';
        };
      }
    );
}
