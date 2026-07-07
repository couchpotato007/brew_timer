{
  description = "Eine einfache Nix dev shell für c/c++";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    odin-overlay = {
      url = "github:couchpotato007/odin-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      odin-overlay,
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ odin-overlay.overlays.default ];
      };

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          glibc
          cmake
          gcc
          odin-bin.stable
          ols
          raylib
          gdb
          emscripten
          pkg-config
          clang
          clang-tools
          cmake
          ninja
          gradle
          android-tools
        ];

        nativeBuildInputs = with pkgs; [
          ols
          wayland
          glfw
          glew
          emscripten
          libc
        ];

        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.raylib
          pkgs.glfw
          pkgs.glew
          pkgs.libxinerama
          pkgs.gl3w
          pkgs.wayland
          pkgs.emscripten
          pkgs.libc
        ];

        EMSCRIPTEN_SDK_DIR = "${pkgs.emscripten}";
      };
    };
}
