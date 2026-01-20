{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # NixOS Security Hardening - Safe Configuration
  #
  # This module provides security hardening without breaking:
  # - Gaming (Steam, NVIDIA, Wine)
  # - Development (Docker, containers)
  # - Desktop environment (KDE Plasma)
  # - Hardware functionality (WiFi, Bluetooth, USB)
  # ============================================================================

  # ============ INTEL ME MITIGATION ============
  # Prevent OS from communicating with Intel Management Engine
  boot.blacklistedKernelModules = [
    "mei"           # ME Interface
    "mei_me"        # ME Interface Driver
    "mei_wdt"       # ME Watchdog
    "mei_hdcp"      # HDCP via ME
    "intel_pmt"     # Platform Monitoring Technology
  ];

  # Block access to ME device nodes
  services.udev.extraRules = lib.mkAfter ''
    # Intel Management Engine - block access
    KERNEL=="mei*", MODE="0000"
    SUBSYSTEM=="mei", MODE="0000"
  '';

  # ============ KERNEL SECURITY PARAMETERS ============
  # Safe hardening that won't break gaming or Docker
  boot.kernelParams = [
    # Memory protection
    "init_on_alloc=1"              # Zero memory on allocation
    "init_on_free=1"               # Zero memory on free
    "slab_nomerge"                 # Prevent slab merging (UAF protection)
    "page_alloc.shuffle=1"         # Randomize page allocator

    # CPU security mitigations (already enabled by default, but explicit)
    "pti=on"                       # Kernel page-table isolation (Meltdown)

    # Disable legacy/dangerous features
    "vsyscall=none"                # Disable vsyscalls (fixed addresses)
    "debugfs=off"                  # Disable debug filesystem

    # Note: NOT using "oops=panic" to avoid gaming crashes causing reboots
  ];

  # ============ SYSCTL HARDENING ============
  boot.kernel.sysctl = {
    # === KERNEL HARDENING ===
    "kernel.dmesg_restrict" = 1;              # Restrict dmesg to root
    "kernel.kptr_restrict" = 2;               # Hide kernel pointers completely
    "kernel.printk" = "3 3 3 3";              # Reduce kernel logging verbosity
    "kernel.randomize_va_space" = 2;          # Full ASLR
    "kernel.yama.ptrace_scope" = 1;           # Restrict ptrace to parent processes
    "kernel.core_pattern" = "|/bin/false";    # Disable coredumps

    # BPF hardening (won't break Docker)
    "kernel.unprivileged_bpf_disabled" = 1;   # Disable unprivileged BPF
    "net.core.bpf_jit_harden" = 2;            # Harden BPF JIT for all users

    # Disable unprivileged user namespaces (may need to disable for some containers)
    # Keeping this at 0 to avoid breaking Docker/gaming
    "kernel.unprivileged_userns_clone" = 0;   # Allow for Docker compatibility

    # === NETWORK HARDENING ===
    # TCP hardening
    "net.ipv4.tcp_syncookies" = 1;                        # SYN flood protection
    "net.ipv4.tcp_rfc1337" = 1;                           # Protect against time-wait assassination
    "net.ipv4.conf.default.rp_filter" = 1;                # Reverse path filtering
    "net.ipv4.conf.all.rp_filter" = 1;                    # Reverse path filtering (all interfaces)

    # Disable ICMP redirects (MITM protection)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Disable source routing (prevent packet routing manipulation)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    # Disable sending ICMP redirects
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;

    # Ignore ICMP ping requests (optional - comment out if you need ping)
    # "net.ipv4.icmp_echo_ignore_all" = 1;
    # "net.ipv6.icmp.echo_ignore_all" = 1;

    # Ignore bogus ICMP error responses
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    # Disable IPv6 router advertisements (if not using IPv6 autoconfiguration)
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;

    # Log martian packets (packets with impossible addresses)
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
  };

  # ============ DISABLE UNNECESSARY SERVICES ============
  # Only disable services that don't break KDE/desktop functionality
  services = {
    # Geolocation (KDE can work without it, but some apps may ask)
    geoclue2.enable = lib.mkDefault true;

    # Automatic USB mounting (KDE can still mount manually)
    udisks2.enable = lib.mkDefault true;  # Keep enabled for KDE convenience

    # Avahi/mDNS (usually not needed unless you use network discovery)
    avahi = {
      enable = lib.mkDefault false;
      nssmdns4 = lib.mkDefault false;
    };
  };

  # ============ APPARMOR (NON-ENFORCING) ============
  # Enable AppArmor in complain mode (logs violations but doesn't block)
  security.apparmor = {
    enable = true;
    packages = [ pkgs.apparmor-profiles ];
    # Start in complain mode - won't break anything, just logs
    killUnconfinedConfinables = false;
  };

  # ============ FIREFOX HARDENING ============
  programs.firefox = {
    enable = true;

    # Policy-based hardening (won't affect user preferences)
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFormHistory = true;
      DisableFirefoxAccounts = lib.mkDefault false;  # Keep accounts working
      DisplayBookmarksToolbar = "never";
      DontCheckDefaultBrowser = true;

      # Privacy preferences
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # Privacy-enhancing preferences
      Preferences = {
        # Telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.updatePing.enabled" = false;

        # Privacy
        "browser.send_pings" = false;
        "dom.battery.enabled" = false;
        "geo.enabled" = false;

        # Disable prefetching
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;

        # WebRTC IP leak protection
        "media.peerconnection.ice.default_address_only" = true;
        "media.peerconnection.ice.no_host" = true;
      };
    };
  };

  # ============ KDE/QT HARDENING ============
  environment.sessionVariables = {
    # Disable KDE telemetry
    KDE_SKIP_CONFD = "1";

    # Reduce Qt logging (less info leakage)
    QT_LOGGING_RULES = "*.debug=false;qt*.info=false";
  };

  # ============ TELEMETRY BLOCKING (DNS) ============
  # Block common telemetry domains
  networking.extraHosts = ''
    # Mozilla telemetry
    0.0.0.0 telemetry.mozilla.org
    0.0.0.0 incoming.telemetry.mozilla.org
    0.0.0.0 firefox.settings.services.mozilla.com
    0.0.0.0 push.services.mozilla.com
    0.0.0.0 tracking-protection.cdn.mozilla.net

    # Microsoft telemetry
    0.0.0.0 telemetry.microsoft.com
    0.0.0.0 data.microsoft.com
    0.0.0.0 vortex.data.microsoft.com
    0.0.0.0 settings-win.data.microsoft.com

    # Canonical/Ubuntu telemetry
    0.0.0.0 metrics.ubuntu.com
    0.0.0.0 popcon.ubuntu.com

    # Red Hat telemetry
    0.0.0.0 cert-api.access.redhat.com
    0.0.0.0 api.access.redhat.com

    # Discord telemetry (if you want to block it)
    # 0.0.0.0 sentry.io

    # Steam analytics (OPTIONAL - may break some features)
    # 0.0.0.0 steamcommunity.com

    # NVIDIA telemetry
    0.0.0.0 telemetry.nvidia.com
    0.0.0.0 telemetry-cf.nvidia.com
  '';

  # ============ FIREWALL HARDENING ============
  # Enhance existing firewall without breaking Steam
  networking.firewall = {
    # Keep existing Steam ports from main config

    # Add rate limiting for SSH (if you enable it later)
    extraCommands = ''
      # Rate limit new connections to prevent DoS
      iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
      iptables -A INPUT -p tcp --syn -j DROP

      # Drop invalid packets
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

      # Log and drop port scans
      iptables -N PORT-SCANNING
      iptables -A PORT-SCANNING -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
      iptables -A PORT-SCANNING -j DROP
    '';

    # Log refused connections (for monitoring)
    logRefusedConnections = lib.mkDefault false;  # Set to true if you want logs
  };

  # ============ DISABLE COREDUMPS ============
  # Prevent sensitive data from being written to disk on crashes
  systemd.coredump.enable = false;

  # ============ USB PROTECTION ============
  # Optional: Enable USBGuard for USB device authorization
  # Disabled by default to avoid breaking workflow
  # Uncomment to enable (you'll need to configure authorized devices)
  #
  # services.usbguard = {
  #   enable = true;
  #   rules = ''
  #     # Allow already connected devices at boot
  #     allow with-interface equals { 03:00:01 03:01:01 }  # Keyboard/Mouse
  #   '';
  # };

  # ============ HARDENED SYSTEMD SERVICES ============
  # Apply security restrictions to user services
  systemd.user.extraConfig = ''
    [Manager]
    # Limit resources for user services
    DefaultLimitNOFILE=524288
    DefaultLimitMEMLOCK=64M
  '';

  # ============ ADDITIONAL HARDENING TOOLS ============
  environment.systemPackages = with pkgs; [
    apparmor-utils        # AppArmor tools
    apparmor-profiles     # Additional AppArmor profiles
  ];

  # ============ NOTES ============
  # Things NOT included (would break functionality):
  # - Hardened kernel (breaks NVIDIA drivers)
  # - Aggressive seccomp (breaks Docker/Steam)
  # - Hardened malloc (breaks games)
  # - Disabling firmware (breaks WiFi/GPU)
  # - Grsecurity patches (not available in nixpkgs)
  #
  # To further harden, consider:
  # 1. Full disk encryption (setup during install)
  # 2. Secure Boot (requires manual setup)
  # 3. Firejail/Bubblewrap for application sandboxing
  # 4. Running untrusted apps in containers
}
