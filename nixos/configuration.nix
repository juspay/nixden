{ config, lib, pkgs, modulesPath, username, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "devbox";

  services.lima.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  programs.nix-ld.enable = true;

  # Persist user systemd services (vscode-server, future `code tunnel`) across
  # logouts / reboots without requiring an active login session.
  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/${username} 0644 root root -"
  ];

  # Boot/filesystem settings must match the stock nixos-lima qcow2 image.
  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  fileSystems."/boot" = {
    device = lib.mkForce "/dev/vda1";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [ "noatime" "nodiratime" "discard" ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ vim ];

  system.stateVersion = "25.11";
}
