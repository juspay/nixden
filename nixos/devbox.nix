{ pkgs, ... }:

{
  # Run random prebuilt Linux binaries that expect an FHS-ish dynamic linker.
  programs.nix-ld.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.starship.enable = true;

  services.vscode-server.enable = true;

  environment.systemPackages = with pkgs; [
    btop
    gh
    git
    just
    vim
  ];
}
