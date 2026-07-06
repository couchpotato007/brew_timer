{
  description = "Eine einfache Nix dev shell für c/c++";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          glibc
          cmake
          gcc
          odin
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

        shellHook = ''
          alias g++="g++ -std=c++14 -Wall --pedantic-errors"
          alias gcc="gcc -std=c99 –-Wall --pedantic-errors"
        '';
      };
    };
}
