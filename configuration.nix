{ config, lib, options, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./security-hardening.nix
    ./steam.nix
    ./neovim.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "ftdi_sio" "usbserial" ];

  # Conservative kernel parameters for session stability
  boot.kernelParams = [
    # Intel graphics optimizations
    "i915.fastboot=1"              # Faster boot with Intel GPU
    "i915.enable_fbc=1"            # Frame buffer compression
    "i915.enable_psr=1"            # Panel self refresh
  ];

  boot.kernelPackages = pkgs.linuxPackages; # (this is the default) some amdgpu issues on 6.10
    programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  # Nix settings
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  system.copySystemConfiguration = true;
  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
  };

  # Laptop-optimized system settings
  boot.kernel.sysctl = {
    # Balanced memory management for laptop use
    "vm.swappiness" = 10;                           # Moderate swapping
    "vm.vfs_cache_pressure" = 100;                  # Default cache pressure
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ ninja ];

  # Hardware optimizations
  hardware.cpu.intel.updateMicrocode = true;  # Enable microcode updates

  # Network and hostname
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Time zone
  time.timeZone = "Europe/London";

  # Internationalisation properties
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
  i18n.supportedLocales = [
    "en_GB.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ];

  # Console keymap
  console.keyMap = "uk";

  # KDE Plasma Desktop Environment
  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm = {
    enable = true;
    package = lib.mkForce pkgs.kdePackages.sddm;
    theme = "catppuccin-mocha-mauve";
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  # X11 windowing system
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Touchpad support
  services.libinput.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

  # User account
  users.users.nixoslaptopmak = {
    isNormalUser = true;
    description = "Ryan Henry";
    extraGroups = [ "docker" "input" "kvm" "libvirtd" "networkmanager" "wheel" ];
    packages = with pkgs; [
      bash-language-server
      black
      #brave
      (ciscoPacketTracer8.override {
        packetTracerSource = /home/nixoslaptopmak/Packages-Flakes/cisco-packet-tracer/CiscoPacketTracer822_amd64_signed.deb;
      })
      (writeShellScriptBin "packettracer-offline" ''
        exec ${pkgs.firejail}/bin/firejail --noprofile --net=none ${ciscoPacketTracer8.override {
          packetTracerSource = /home/nixoslaptopmak/Packages-Flakes/cisco-packet-tracer/CiscoPacketTracer822_amd64_signed.deb;
        }}/bin/packettracer "$@"
      '')
      clang-tools
      claude-code
      cmake
      firejail
      #cudaPackages.cudatoolkit
      #cudaPackages.cudnn
      #cudaPackages.cuda_cudart
      #docker
      #docker-compose
      dolphin-emu
      direnv
      discord
      #dpkg
      fd
      ffmpeg
      firefox-bin
      fwupd
      gcc
      gdb
      git
      gopls
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-vaapi
      heroic
      #iproute2
      jetbrains-mono
      #jetbrains.clion
      #jetbrains.pycharm-professional
      #jdk23
      #(koboldcpp.override { config.cudaSupport = true; })
      #libguestfs
      #libreoffice
      linuxKernel.packages.linux_zen.cpupower
      maven
      #mono
      mullvad-browser
      mullvad-vpn
      nixd
      nodePackages.eslint
      nodePackages.prettier
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      ollama
      ollama-cuda
      #osu-lazer-bin
      #OVMFFull
      pandoc
      parabolic
      prismlauncher
      protonup-qt
      pyright
      python312Packages.debugpy
      python312Packages.jupyter
      python312Packages.jupyterlab  # Optional: for JupyterLab interface
      python312Packages.notebook
      python312Packages.ipykernel
      python312Packages.pytest
      python312Packages.python-lsp-server
      #qemu_full
      #quickemu
      ripgrep
      rust-analyzer
      shellcheck
      sillytavern
      #spice-gtk
      #spice-vdagent
      spotify
      tgpt
      #ubootQemuX86
      #virglrenderer
      #virtio-win
      #virtualbox
      #virt-manager
      #virt-viewer
      vlc
      xilinx-bootgen
      xorg.xhost
      #youtube-music
    ];
  };

  # Fonts
  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    minecraftia
  ];

  # Docker
  #virtualisation.docker = {
    #enable = true;
    #rootless = {
      #enable = true;
      #setSocketVariable = true;
    #};
  #};

  # Nixpkgs settings
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
    ];
    cudaSupport = true;
    cudaCapabilities = [ "7.5" ];
    nvidia.acceptLicense = true;
    permittedInsecurePackages = [
      "ciscoPacketTracer8-8.2.2"
      "qtwebkit-5.212.0-alpha4"
    ];
    packageOverrides = pkgs: {
      firefox = pkgs.firefox-bin;
    };
  };

  # Programs and services
  programs = {
    firefox.enable = true;
    gamemode.enable = true;
    git.enable = true;
    java = {
      enable = true;
      package = pkgs.jdk25_headless;
    };
    ssh = {
      startAgent = true;
      askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    };
  };

  # Environment variables for SSH/KWallet integration
  environment.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };
  services = {
    mullvad-vpn.enable = true;
    #qemuGuest.enable = true;
    resolved.enable = true;
    #spice-vdagentd.enable = true;
  };

  # Virtualisation
  #virtualisation = {
    #libvirtd = {
      #enable = true;
      #qemu = {
        #ovmf.enable = true;
        #package = pkgs.qemu_kvm;
      #};
    #};
    #spiceUSBRedirection.enable = true;
  #};

  # Firmware
  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  # NixOS-NVIDIA opengl configuration guide at: https://nixos.wiki/wiki/Nvidia
  # Prime offload executable script at: /home/nixoslaptopmak/.local/bin/nvidia-offload
  # GPU architecture code list at: https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/

  # Enhanced graphics for high-performance gaming
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Core gaming packages (testing if they work without Lutris)
      dxvk
      gamemode
      gamescope
      libstrangle

      # Video acceleration and codec support (keep essential ones)
      libvdpau
      libva
      libva-utils
      libva-vdpau-driver

      # Vulkan and graphics optimization with surface extensions for Steam GUI
      #protontricks  # May have FHS conflicts
      vkbasalt
      vkd3d-proton
      vulkan-extension-layer
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      vulkan-headers
      spirv-tools

      # Critical Vulkan WSI (Window System Integration) extensions for Steam
      pkgs.xorg.libX11
      pkgs.xorg.libXrandr
      pkgs.xorg.libXext
      pkgs.libxkbcommon
      pkgs.wayland
      pkgs.mesa
      pkgs.libGL

      # Additional gaming tools (commented to avoid FHS conflicts)
      winetricks
      #lutris  # Commented to avoid Steam FHS collision
      #bottles  # Commented to avoid potential FHS conflicts
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      dxvk  # Testing if this works without Lutris
      libva
      libvdpau
      vkd3d-proton  # Testing if this works without Lutris
      vulkan-loader
      vulkan-validation-layers
      libva-vdpau-driver

      # 32-bit Vulkan WSI extensions for Steam GUI compatibility
      xorg.libX11
      xorg.libXrandr
      xorg.libXext
      libxkbcommon
      wayland
      mesa
      libGL
    ];
  };

  # Nvidia drivers - optimized for gaming performance
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;

    # Optimize power management for gaming
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Disable power management during gaming for maximum performance
    # Users can enable via gaming wrapper scripts

    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Force performance mode for better gaming
    forceFullCompositionPipeline = false;  # Can cause input lag

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    (buildFHSEnv {
      name = "xilinx-env";
      targetPkgs = pkgs: with pkgs; [
        stdenv.cc.cc
        ncurses5
        zlib
        libuuid
        xorg.libXext
        xorg.libX11
        xorg.libXrender
        xorg.libXtst
        xorg.libXi
        freetype
        fontconfig
      ];
      runScript = "bash";
    })

    # SSH and KWallet integration
    ksshaskpass

    jetbrains-mono
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      font = "jetbrains-mono";
      fontSize = "12";
      background = "${/home/nixoslaptopmak/Pictures/bvs01.jpg}";
      loginBackground = true;
    })
  ];

  # Firewall - Steam gaming ports
  networking.firewall = {
    allowedTCPPorts = [ 27036 27037 ]; # Steam Remote Play
    allowedUDPPorts = [ 27031 27036 ]; # Steam Remote Play
    allowedTCPPortRanges = [
      { from = 27015; to = 27030; }     # Steam dedicated server
      { from = 27014; to = 27050; }     # Steam Remote Play
    ];
    allowedUDPPortRanges = [
      { from = 4380; to = 4380; }      # Steam Discovery
      { from = 27000; to = 27031; }    # Steam games
      { from = 27014; to = 27050; }    # Steam Remote Play
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
