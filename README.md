# devbox

NixOS based devbox on macOS via [Lima](https://lima-vm.io/).

The host only needs `limactl` and `just`. Nix runs inside the VM:

- A temporary builder VM builds a local qcow2 image from this flake.
- The working VM boots directly from that local image.
- Devbox tools and services are baked into the NixOS image.
- Users can add personal packages later with `nix profile install nixpkgs#...`.

## Requirements

- [`limactl`](https://lima-vm.io/)
- [`just`](https://github.com/casey/just)

No host-side Nix install is required for normal use.
Linux CI can set `DEVBOX_HOST_BUILD_IMAGE=1` to build the qcow2 with host Nix before boot-testing it with Lima.

The recipes support both newer Lima versions with `--mount-only` and older versions that only have `--mount`.
On slow QEMU hosts, set `DEVBOX_LIMA_START_TIMEOUT` to extend Lima's VM readiness wait.

## Usage

```sh
just              # list recipes
just build-image  # build/update the local qcow2 via a temporary builder VM
just start        # boot the working VM from the local qcow2
just shell        # open a shell in the VM
just stop         # stop the VM
just delete       # remove the VM
just recreate     # delete and recreate the VM from the current local qcow2
just list         # list all Lima VMs
```

`just start` will automatically run `just build-image` first if the local qcow2 is missing.

Image artifacts live outside `~/.lima` by default, under `~/Library/Caches/devbox`. This matters because Lima treats directories under `~/.lima` as instance state.

## What Lives Where

Base image config:

- Defined by [`nixos/configuration.nix`](nixos/configuration.nix)
- Contains Lima/NixOS plumbing such as guest integration, SSH, sudo, boot, and filesystem settings

Devbox config:

- Defined by [`nixos/devbox.nix`](nixos/devbox.nix)
- Includes `btop`, `gh`, `git`, `just`, `vim`, `direnv`, `nix-direnv`, `starship`, `nix-ld`, and VS Code server support

User tools:

- Not managed by this repo
- Install ad hoc tools inside the guest with commands like `nix profile install nixpkgs#ripgrep`
- For declarative packages and dotfiles, use Home Manager from your own config repo; [`juspay/nixos-unified-template`](https://github.com/juspay/nixos-unified-template) is the recommended starting point

## Working on Projects

The working VM mounts only:

- This repo, read-only
- `~/Shared/devbox-exchange`, writable

It does not mount your full macOS home by default.

That means:

- Keep active repos inside the guest filesystem, for example `~/code`
- Use `~/Shared/devbox-exchange` only for intentional file transfer
- Use `nix profile install nixpkgs#...` for personal tools that do not belong in the base image
- Use a separate Home Manager config for declarative packages, shell config, Git config, and dotfiles

Example:

```sh
just start
just ssh mkdir -p ~/code
just ssh 'cd ~/code && git clone ...'
just ssh nix profile install nixpkgs#ripgrep
```

## Opt-In Home Mount

The default VM does not mount your full macOS home. This avoids exposing host
secrets such as `~/.aws`, `~/.ssh`, and application dotfiles to the guest.

If you deliberately want broader sharing, pass extra Lima mounts when creating
or recreating the VM:

```sh
DEVBOX_EXTRA_MOUNTS="$HOME" just recreate    # read-only host home
DEVBOX_EXTRA_MOUNTS="$HOME:w" just recreate  # writable host home
```

Prefer mounting a narrower directory when possible:

```sh
DEVBOX_EXTRA_MOUNTS="$HOME/.config/home-manager:w" just recreate
```

## Refreshing Changes

After editing [`nixos/configuration.nix`](nixos/configuration.nix) or [`nixos/devbox.nix`](nixos/devbox.nix):

```sh
just build-image
just recreate
```

If you already have an older VM from the previous workflow, run `just recreate` once to pick up the new mount defaults and local-image boot flow.

If you tested an earlier revision of this repo and see Lima errors mentioning `devbox-artifacts/lima.yaml`, remove the stale directory once:

```sh
rm -rf ~/.lima/devbox-artifacts
```

## SSH Access

```sh
just ssh
just ssh uname -a
just ssh-config
```

## VS Code Remote-SSH

Point VS Code at Lima's generated SSH config:

1. `Cmd-Shift-P` -> **Remote-SSH: Settings** -> set **Config File** to `~/.lima/devbox/ssh.config`
2. `Cmd-Shift-P` -> **Remote-SSH: Connect to Host...** -> pick `lima-devbox`

## Security Posture

The default workflow is designed to avoid ambient host-secret exposure:

- no full-`HOME` mount
- no host-side Nix requirement
- only a narrow repo mount plus a single exchange directory

So credentials in host paths like `~/.aws`, `~/.ssh`, and `~/.config` are not exposed to the working VM unless you deliberately broaden the mount set.
