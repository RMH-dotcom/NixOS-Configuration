{ config, lib, options, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./neovim.nix
    ./security-hardening.nix
    ./steam.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "ftdi_sio" "usbserial" ];
  boot.kernelPackages = pkgs.linuxPackages; # (this is the default) some amdgpu issues on 6.10
  boot.kernelParams = [
    "i915.enable_fbc=1"            # Frame buffer compression
    "i915.enable_psr=1"            # Panel self refresh
    "i915.fastboot=1"              # Faster boot with Intel GPU
  ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;                           # Moderate swapping
    "vm.vfs_cache_pressure" = 100;                  # Default cache pressure
  };

  # Hardware
  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableAllFirmware = true;

  # NVIDIA
  # NixOS-NVIDIA opengl configuration guide at: https://nixos.wiki/wiki/Nvidia
  # Prime offload executable script at: /home/nixoslaptopmak/.local/bin/nvidia-offload
  # GPU architecture code list at: https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Force performance mode for better gaming
    forceFullCompositionPipeline = false;  # Can cause input lag

    # Optimize power management for gaming
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Graphics - Enhanced for high-performance gaming
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Core gaming packages
      dxvk
      gamemode
      gamescope
      libstrangle

      # Video acceleration and codec support
      libva
      libva-utils
      libva-vdpau-driver
      libvdpau

      # Vulkan and graphics optimization
      spirv-tools
      vkbasalt
      vkd3d-proton
      vulkan-extension-layer
      vulkan-headers
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers

      # Critical Vulkan WSI (Window System Integration) extensions for Steam
      libGL
      libxkbcommon
      mesa
      wayland
      xorg.libX11
      xorg.libXext
      xorg.libXrandr

      # Additional gaming tools
      winetricks
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      # 32-bit support for gaming
      dxvk
      vkd3d-proton
      vulkan-loader
      vulkan-validation-layers

      # 32-bit video acceleration
      libva
      libva-vdpau-driver
      libvdpau

      # 32-bit Vulkan WSI extensions for Steam GUI compatibility
      libGL
      libxkbcommon
      mesa
      wayland
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
    ];
  };

  # Nix
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "flakes" "nix-command" ];
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Nixpkgs
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];
    cudaCapabilities = [ "7.5" ];
    cudaSupport = true;
    nvidia.acceptLicense = true;
    packageOverrides = pkgs: {
      firefox = pkgs.firefox-bin;
    };
    permittedInsecurePackages = [
      "ciscoPacketTracer8-8.2.2"
      "qtwebkit-5.212.0-alpha4"
    ];
  };

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  # Firewall - Steam gaming ports
  networking.firewall = {
    allowedTCPPorts = [ 27036 27037 ]; # Steam Remote Play
    allowedUDPPorts = [ 27031 27036 ]; # Steam Remote Play
    allowedTCPPortRanges = [
      { from = 27014; to = 27050; }     # Steam Remote Play
      { from = 27015; to = 27030; }     # Steam dedicated server
    ];
    allowedUDPPortRanges = [
      { from = 4380; to = 4380; }      # Steam Discovery
      { from = 27000; to = 27031; }    # Steam games
      { from = 27014; to = 27050; }    # Steam Remote Play
    ];
  };

  # Localization
  time.timeZone = "Europe/London";
  console.keyMap = "uk";
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
    "C.UTF-8/UTF-8"
    "en_GB.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];

  # Desktop Environment
  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm = {
    enable = true;
    package = lib.mkForce pkgs.kdePackages.sddm;
    theme = "catppuccin-mocha-mauve";
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Services
  services.fwupd.enable = true;
  services.libinput.enable = true;
  services.mullvad-vpn.enable = true;
  services.printing.enable = true;
  services.resolved.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User
  users.users.nixoslaptopmak = {
    isNormalUser = true;
    description = "Ryan Henry";
    extraGroups = [ "docker" "input" "kvm" "libvirtd" "networkmanager" "wheel" ];
    packages = with pkgs; [
      bash-language-server
      black
      #brave
      # Cisco Packet Tracer
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
      #cudaPackages.cuda_cudart
      #cudaPackages.cudnn
      #cudaPackages.cudatoolkit
      direnv
      discord
      #docker
      #docker-compose
      dolphin-emu
      #dpkg
      fd
      ffmpeg
      firejail
      firefox-bin
      fwupd
      gcc
      gdb
      git
      gopls
      # GStreamer plugins
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-vaapi
      gst_all_1.gstreamer
      heroic
      #iproute2
      #jdk23
      jetbrains-mono
      #jetbrains.clion
      #jetbrains.pycharm-professional
      kdePackages.ksshaskpass
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
      # Python packages
      python312Packages.debugpy
      python312Packages.ipykernel
      python312Packages.jupyter
      python312Packages.jupyterlab  # Optional: for JupyterLab interface
      python312Packages.notebook
      python312Packages.pytest
      python312Packages.python-lsp-server
      pyright
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
      #virtualbox
      #virtio-win
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

  # Programs
  programs.firefox.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.git.enable = true;
  programs.java = {
    enable = true;
    package = pkgs.jdk25_headless;
  };
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ ninja ];
  };
  programs.ssh = {
    startAgent = true;
    askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  };

  # Environment
  environment.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };
  environment.systemPackages = with pkgs; [
    # Xilinx FHS environment
    (buildFHSEnv {
      name = "xilinx-env";
      targetPkgs = pkgs: with pkgs; [
        fontconfig
        freetype
        libuuid
        ncurses5
        stdenv.cc.cc
        xorg.libX11
        xorg.libXext
        xorg.libXi
        xorg.libXrender
        xorg.libXtst
        zlib
      ];
      runScript = "bash";
    })
    # SDDM theme
    jetbrains-mono
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      font = "jetbrains-mono";
      fontSize = "12";
      background = "${/home/nixoslaptopmak/Pictures/bvs01.jpg}";
      loginBackground = true;
    })
  ];

  # System
  system.copySystemConfiguration = true;
  system.stateVersion = "24.11"; # Did you read the comment?
  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
  };

  # Virtualization (disabled)
  #virtualisation.docker = {
  #  enable = true;
  #  rootless = {
  #    enable = true;
  #    setSocketVariable = true;
  #  };
  #};
}
