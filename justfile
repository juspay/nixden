nix_shell := if env('IN_NIX_SHELL', '') != '' { '' } else { 'nix develop -c' }
name := "devbox"
username := "srid"

# List available recipes
default:
    @just --list

# --- Lifecycle ---

# Create and start the NixOS VM, then apply our custom config
[group('lifecycle')]
start vm=name:
    {{nix_shell}} limactl start --name={{vm}} --cpus=6 --memory=12 --disk=100 --yes github:nixos-lima
    just provision {{vm}}

# Apply our NixOS + home-manager config inside the VM (idempotent)
[group('lifecycle')]
provision vm=name:
    # `--workdir /tmp` keeps CWD off the Users-<user>.mount 9p mount so
    # switch-to-configuration can restart that mount without a busy-target error.
    {{nix_shell}} limactl shell --workdir /tmp {{vm}} -- sudo nixos-rebuild switch --flake $(pwd)#devbox
    {{nix_shell}} limactl shell --workdir /tmp {{vm}} -- nix run $(pwd)#home-manager -- switch --flake $(pwd)#{{username}}

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
