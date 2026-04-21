{ nixpkgs, nixos-lima, home-manager, nixos-vscode-server, ... }:

let
  system = "aarch64-linux";
  username = "srid";
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      nixos-lima.nixosModules.lima
      ./nixos/configuration.nix
      { _module.args = { inherit username; }; }
    ];
  };

  homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit username; };
    modules = [
      nixos-vscode-server.homeModules.default
      ./home/home.nix
    ];
  };

  packages.${system}.home-manager = home-manager.packages.${system}.default;
}
