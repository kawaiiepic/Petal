{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dart.url = "github:roman-vanesyan/dart-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      dart
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(final: prev: {
            dart = dart.packages."x86_64-linux".beta;
          }) ];
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            flutter347
            google-chrome
            gradle_9

            # build tools
            clang
            cmake
            ninja
            pkg-config

            # flutter linux deps
            gtk3
            libepoxy
            mpv
            libass

            # runtime
            wayland
            libxkbcommon

            ninja

            # dart.packages."x86_64-linux".dev
          ];

          shellHook = ''
            echo "Flutter dev shell ready"

            export CHROME_EXECUTABLE=zen-beta
            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath [
                pkgs.mpv
                pkgs.gtk3
                pkgs.libepoxy
              ]
            }:$LD_LIBRARY_PATH
          '';
        };
      }
    );
}
