{ nixpkgs, nixos-lima, nixos-vscode-server, ... }:

let
  mkNixden = system:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixos-lima.nixosModules.lima
        nixos-vscode-server.nixosModules.default
        ./nixos/configuration.nix
      ];
    };

  nixdenAarch64 = mkNixden "aarch64-linux";
  nixdenX86_64 = mkNixden "x86_64-linux";
in
{
  nixosConfigurations = {
    nixden = nixdenAarch64;
    nixden-aarch64 = nixdenAarch64;
    nixden-x86_64 = nixdenX86_64;
  };
}
