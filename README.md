# NixOS Configuration

My NixOS system configuration files.

## Files

- `configuration.nix` - Main system configuration
- `neovim.nix` - Neovim setup
- `steam.nix` - Steam and gaming configuration
- `security-hardening.nix` - Security hardening settings

## Setup

Files are symlinked to `/etc/nixos/`:

```bash
ls -l /etc/nixos/
```

## Rebuild System

```bash
sudo nixos-rebuild switch
```

## Installation on New System

```bash
git clone <your-repo-url> ~/Projects/NixOS-Config-Symlink
cd /etc/nixos
sudo rm *.nix
sudo ln -s ~/Projects/NixOS-Config-Symlink/*.nix .
sudo nixos-rebuild switch
```
