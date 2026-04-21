nix_shell := if env('IN_NIX_SHELL', '') != '' { '' } else { 'nix develop -c' }
name := "devbox"

# List available recipes
default:
    @just --list

# --- Lifecycle ---

# `github:nixos-lima` below is a Lima TEMPLATE reference (the stock qcow2
# release), not a Nix flake input. Our locked nixos-lima in flake.lock
# takes over only after `provision` runs nixos-rebuild with our own config.

# Create and start the NixOS VM, then apply our custom config
[group('lifecycle')]
start vm=name:
    {{nix_shell}} limactl start --name={{vm}} --cpus=6 --memory=12 --disk=100 --yes github:nixos-lima
    just provision {{vm}}

# `--workdir /tmp` keeps CWD off Lima's Users-<user> 9p mount so that
# switch-to-configuration can restart that mount unit cleanly.
# `--impure` + `env USER=...` lets default.nix read $USER across the sudo
# boundary, so the flake provisions for the invoking user.

# Apply our NixOS + home-manager config inside the VM (idempotent)
[group('lifecycle')]
provision vm=name:
    {{nix_shell}} limactl shell --workdir /tmp {{vm}} -- sudo env USER=$USER nixos-rebuild switch --impure --flake $(pwd)#devbox

# Stop the VM
[group('lifecycle')]
stop vm=name:
    {{nix_shell}} limactl stop {{vm}}

# Remove the VM (destructive)
[group('lifecycle')]
delete vm=name:
    {{nix_shell}} limactl delete {{vm}}

# List all Lima VMs
[group('lifecycle')]
list:
    {{nix_shell}} limactl list

# --- Access ---

# Open a shell in the VM
[group('access')]
shell vm=name:
    {{nix_shell}} limactl shell {{vm}}

# Print Lima's generated SSH config for the VM
[group('access')]
ssh-config vm=name:
    {{nix_shell}} limactl show-ssh --format=config {{vm}}

# SSH into the VM using Lima's generated config (no global config mutation)
[group('access')]
ssh *args='':
    ssh -F ~/.lima/{{name}}/ssh.config lima-{{name}} {{args}}
