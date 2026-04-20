# lima-nixos-demo

A minimal [`justfile`](justfile) for running a NixOS devbox VM via [Lima](https://lima-vm.io/) on macOS.

## Requirements

- [Nix](https://nixos.asia/en/install) (provides `lima` via `nix shell nixpkgs#lima`)
- [`just`](https://github.com/casey/just)

## Usage

```sh
just              # list recipes
just start        # create & start the NixOS VM (6 CPU / 12 GB / 100 GB)
just shell        # open a shell in the VM
just stop         # stop the VM
just delete       # remove the VM
just list         # list all Lima VMs
```

## SSH access

```sh
just ssh                # SSH into the VM (uses Lima's generated config, no global mutation)
just ssh uname -a       # run a command over SSH
just ssh-config         # print Lima's generated SSH config
```
