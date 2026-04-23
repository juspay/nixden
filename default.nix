{ nixpkgs, nixos-lima, nixos-vscode-server, ... }:

let
  linuxSystems = [ "aarch64-linux" "x86_64-linux" ];
  configName = system: "devbox-${system}";

  mkNixosConfiguration = system:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixos-lima.nixosModules.lima
        nixos-vscode-server.nixosModules.default
        ./nixos/configuration.nix
        ./nixos/devbox.nix
      ];
    };

  nixosConfigurations = builtins.listToAttrs (map
    (system: {
      name = configName system;
      value = mkNixosConfiguration system;
    })
    linuxSystems);

  packages = builtins.listToAttrs (map
    (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        config = nixosConfigurations.${configName system}.config;
        imageDrv =
          if builtins.hasAttr "qemu-efi" config.system.build.images then
            config.system.build.images."qemu-efi"
          else
            config.system.build.images.qemu;
      in
      {
        name = system;
        value = {
          devbox-image = pkgs.runCommand "devbox-${system}.qcow2" { } ''
            src="$(find ${imageDrv} -type f -name '*.qcow2' | head -n 1)"
            if [ -z "$src" ]; then
              echo "No qcow2 image found under ${imageDrv}" >&2
              exit 1
            fi
            cp "$src" "$out"
          '';
        };
      })
    linuxSystems);
in
{
  inherit nixosConfigurations packages;
}
