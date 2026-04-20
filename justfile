default:
    @just --list

lima := "nix shell nixpkgs#lima -c"
name := "devbox"

# --- Lifecycle ---

# Create and start the NixOS VM
[group('lifecycle')]
start vm=name:
    {{lima}} limactl start --name={{vm}} --cpus=6 --memory=12 --disk=100 github:nixos-lima

# Stop the VM
[group('lifecycle')]
stop vm=name:
    {{lima}} limactl stop {{vm}}

# Remove the VM (destructive)
[group('lifecycle')]
delete vm=name:
    {{lima}} limactl delete {{vm}}

# List all Lima VMs
[group('lifecycle')]
list:
    {{lima}} limactl list

# --- Access ---

# Open a shell in the VM
[group('access')]
shell vm=name:
    {{lima}} limactl shell {{vm}}

# Print Lima's generated SSH config for the VM
[group('access')]
ssh-config vm=name:
    {{lima}} limactl show-ssh --format=config {{vm}}

# SSH into the VM using Lima's generated config (no global config mutation)
[group('access')]
ssh *args='':
    ssh -F ~/.lima/{{name}}/ssh.config lima-{{name}} {{args}}
