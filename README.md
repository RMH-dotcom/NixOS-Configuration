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
### Important Notice

This config is tailored to my system. If you wish to incorporate it to yours, you must review and modify:
  - **Username**: Replace `nixoslaptopmak` throughout the configuration                                
  - **File paths**:                                                                                    
    - Cisco Packet Tracer: `/home/nixoslaptopmak/Packages-Flakes/cisco-packet-tracer/`                 
    - SDDM background: `/home/nixoslaptopmak/Pictures/bvs01.jpg`                                       
    - Xilinx environment paths                                                                         
  - **Hardware**: Generate your own `hardware-configuration.nix` with `nixos-generate-config`          
  - **Locale/Timezone**: Currently set to UK (en_GB.UTF-8, Europe/London)                              
  - **NVIDIA settings**: Intel/NVIDIA hybrid graphics with specific bus IDs
