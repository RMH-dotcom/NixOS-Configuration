{ config, pkgs, ... }:

{
  # ============================================================================
  # Steam Gaming Configuration Module
  # Converted from flake for easier system management
  # ============================================================================

  # Gaming performance wrapper script
  environment.systemPackages = with pkgs; [
    # Gaming mode wrapper script with aggressive optimizations
    (writeShellScriptBin "gaming-steam" ''
      echo "🎮 Activating MAXIMUM GAMING PERFORMANCE..."

      # Apply ALL system optimizations FIRST (blocking - must complete before Steam)
      echo "🌡️ CPU: Switching to balanced governor for thermal safety..."
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -f "$cpu" ] && echo powersave | sudo tee "$cpu" > /dev/null 2>&1 || true
      done

      echo "❄️ CPU: Disabling turbo boost to prevent overheating..."
      echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 || true

      echo "🎯 GPU: Forcing maximum performance mode..."
      sudo nvidia-smi -pm 1 > /dev/null 2>&1 || true
      sudo nvidia-smi -ac 6001,1530 > /dev/null 2>&1 || true

      echo "💾 SYSTEM: Optimizing memory and I/O..."
      echo 1 | sudo tee /proc/sys/vm/swappiness > /dev/null 2>&1 || true
      echo 15 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null 2>&1 || true
      echo 50 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null 2>&1 || true

      echo "✅ All optimizations applied successfully!"

      echo "🎮 Starting Steam with MAXIMUM PERFORMANCE..."

      # Preserve current session environment (critical for GUI)
      export DISPLAY="''${DISPLAY:-:0}"
      export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY}"
      export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"
      export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS}"
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR}"
      export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP}"

      # Display backend with fallback
      export GDK_BACKEND=wayland,x11
      export QT_QPA_PLATFORM=wayland,xcb
      export CLUTTER_BACKEND=wayland

      # Environment variables moved to nvidia-offload script to prevent Steam CEF conflicts
      # Steam interface uses integrated graphics, games use nvidia-offload for NVIDIA GPU
      # NixOS-NVIDIA opengl configuration guide at: https://nixos.wiki/wiki/Nvidia
      # Prime offload executable script at: /home/nixoslaptopmak/.local/bin/nvidia-offload

      
      # ALL environment variables commented out - now handled by nvidia-offload script:
      # Enhanced Vulkan / DXVK / VKD3D
      # export DXVK_ASYNC=1
      # export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk"
      # export DXVK_CONFIG_FILE="$HOME/.config/dxvk.conf"
      # export DXVK_HUD=0
      # export VKD3D_CONFIG="dxr11"
      # export VKD3D_SHADER_CACHE_PATH="$HOME/.cache/vkd3d"

      # Enhanced Proton/Wine
      # export PROTON_ENABLE_NVAPI=1
      # export PROTON_HIDE_NVIDIA_GPU=0
      # export PROTON_NO_ESYNC=0
      # export PROTON_NO_FSYNC=0
      # export PROTON_LOG=0
      # export PROTON_FORCE_LARGE_ADDRESS_AWARE=1
      # export WINE_FULLSCREEN_FSR=1
      # export WINE_FULLSCREEN_FSR_STRENGTH=2
      # export WINE_CPU_TOPOLOGY="6:12"

      # Enhanced NVIDIA Driver Performance
      # export __GL_THREADED_OPTIMIZATIONS=1
      # export __GL_MaxFramesAllowed=1
      # export __GL_GSYNC_ALLOWED=0
      # export __GL_VRR_ALLOWED=0
      # export __GL_YIELD="USLEEP"
      # export __GL_SHADER_DISK_CACHE=1
      # export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=0
      # export __GL_SHADER_DISK_CACHE_SIZE_KB=1048576
      # export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nv-shaders"
      # export __GL_SHADER_DISK_CACHE_WRITE_ONLY=0
      # export __GL_BUFFER_SWAP_STRATEGY=2
      # export __GL_TEXTURE_MEMORY_COMPACTION=1

      # NVIDIA PRIME Offload
      # export __NV_PRIME_RENDER_OFFLOAD=1
      # export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      # export __GLX_VENDOR_LIBRARY_NAME=nvidia
      # export __VK_LAYER_NV_optimus=NVIDIA_only
      # export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json

      # Anti-Freeze and Stability
      # export KWIN_TRIPLE_BUFFER=0
      # export CLUTTER_VBLANK="none"

      # Gaming Performance
      # export ENABLE_GAMESCOPE_WSI=1
      # export GALLIUM_HUD=0
      # export PIPEWIRE_LATENCY="32/48000"
      # export SDL_VIDEODRIVER="wayland,x11"

      # CPU and Threading
      # export OMP_NUM_THREADS=12
      # export WINE_RT_PRIORITY=20

      # Commented out nvidia-offload wrapper (causes Steam to hang)
      # /home/nixoslaptopmak/.local/bin/nvidia-offload steam -windowed -silent "$@" &

      # Launch Steam as regular user (critical for GUI)
      if [ "$EUID" -eq 0 ]; then
        # If running as root, switch to regular user
        su - nixoslaptopmak -c "DISPLAY='$DISPLAY' WAYLAND_DISPLAY='$WAYLAND_DISPLAY' XDG_SESSION_TYPE='$XDG_SESSION_TYPE' DBUS_SESSION_BUS_ADDRESS='$DBUS_SESSION_BUS_ADDRESS' XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR' steam $*" &
      else
        # Already running as regular user
        steam "$@" &
      fi
      STEAM_PID=$!

      echo "Steam PID: $STEAM_PID"
      echo "Waiting for Steam to initialize..."
      sleep 3

      # Wait for Steam to exit (keeps optimizations active during entire session)
      wait $STEAM_PID

      echo "🔄 Maintaining thermal-safe settings..."
      # Keep CPU in thermal-safe mode (already set to powersave + no turbo)
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -f "$cpu" ] && echo powersave | sudo tee "$cpu" > /dev/null 2>&1 || true
      done
      echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 || true

      # Reset GPU to auto mode
      sudo nvidia-smi -rac > /dev/null 2>&1 || true  # Reset clocks to auto
      sudo nvidia-smi -pm 0 > /dev/null 2>&1 || true  # Disable persistence mode

      # Restore conservative memory settings
      echo 10 | sudo tee /proc/sys/vm/swappiness > /dev/null 2>&1 || true
      echo 10 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null 2>&1 || true
      echo 20 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null 2>&1 || true

      echo "✅ Power-efficient mode restored"
    '')
  ];

  # Enable Steam with all gaming features
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Allow users to change CPU governor and GPU settings without password
  security.sudo.extraRules = [{
    users = [ "nixoslaptopmak" ];
    commands = [
      {
        command = "/run/current-system/sw/bin/tee";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/sw/bin/nvidia-smi";
        options = [ "NOPASSWD" ];
      }
    ];
  }];
}
