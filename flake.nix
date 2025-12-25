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
          buildInputs = with pkgs; [
            flutter
            google-chrome
            pkg-config

            mpv
            wayland.dev

            ## Idk what is needed.
            libarchive.dev
            openssl.dev
            libxml2.dev
            libepoxy.dev
            xorg.libXtst
            libsysprof-capture
            sqlite.dev
            libpsl.dev
            nghttp2.dev
            libepoxy
            pcre2
            gtk3

            util-linux
            libselinux
            libsepol
            libthai
            libdatrie
            xorg.libXdmcp
            lerc
            libxkbcommon
            cmake
            mpv
            libass
            mimalloc
            ffmpeg
            libplacebo
            libunwind
            shaderc
            vulkan-loader
            lcms
            libdovi
            libdvdnav
            libdvdread
            mujs
            libbluray
            lua
            rubberband
            SDL2
            libuchardet
            zimg
            alsa-lib
            openal
            pipewire
            pulseaudio
            libcaca
            libdrm
            mesa
            xorg.libXScrnSaver
            xorg.libXpresent
            xorg.libXv
            nv-codec-headers-12
            libva
            libvdpau
            ninja
            webkitgtk_4_1
          ];

          shellHook = ''
            echo "Flutter Web dev shell ready"
            export CHROME_EXECUTABLE="${pkgs.google-chrome}/bin/google-chrome-stable"
            export LD_LIBRARY_PATH="$(pwd)/build/linux/x64/debug/bundle/lib:$(pwd)/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
}
