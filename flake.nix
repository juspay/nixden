{
  description = "devbox: NixOS based devbox on macOS (custom NixOS on Lima)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-lima = {
      url = "github:nixos-lima/nixos-lima/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nixos-lima, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forEach = nixpkgs.lib.genAttrs;
      base = import ./default.nix inputs;
    in
    base // {
      devShells = forEach systems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = import ./shell.nix { inherit pkgs; };
          ci = pkgs.mkShell {
            packages = with pkgs; [
              coreutils
              gh
              jq
              qemu
              yq-go
            ];
          };
        });

      # Lima template YAML, pinned to our locked nixos-lima input. Keep the
      # nixos-lima guest integration defaults, but replace broad host mounts
      # with a narrow scratch directory for explicit file transfer.
      packages = forEach systems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          lima-template = pkgs.runCommand "devbox-lima-template" {
            nativeBuildInputs = [ pkgs.yq-go ];
          } ''
            yq -P '
              .mounts = [
                {
                  "location": "/tmp/lima-devbox",
                  "mountPoint": "/tmp/lima-devbox",
                  "writable": true,
                  "9p": {
                    "cache": "mmap"
                  }
                }
              ]
            ' ${nixos-lima}/.lima.yaml > $out
          '';
        });
    };
}
