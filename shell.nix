{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    curl
    gh
    jq
    lima
    just
  ];
}
