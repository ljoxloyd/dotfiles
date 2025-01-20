# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
let
  user = "odmin";

  configuration =
    {
      config,
      pkgs,
      lib,
      system,
      inputs,
      ...
    }:
    {
      imports = [
        ./hardware-configuration.nix

        module-essentials
        module-user
        module-audio
        # module_desktop-Plasma
        module-desktop-Niri
        module-keyboard
        module-browser-Firefox
        module-locale
        module-containers
      ];

      environment.systemPackages = with pkgs; [
        #
        nh
        dig.dnsutils
        wget
      ];

      fonts.packages = [
        (pkgs.nerdfonts.override {
          fonts = [
            "Noto"
            "GeistMono"
            "JetBrainsMono"
            "Hack"
          ];
        })
      ];

      home-manager.extraSpecialArgs = { inherit system inputs; };
      home-manager.useGlobalPkgs = true;
      home-manager.users.${user} =
        { pkgs, ... }:
        {
          home.stateVersion = "23.05";
          programs.home-manager.enable = true;
          imports = [ ./home.nix ];
        };

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "23.05"; # Did you read the comment?
    };

  module-essentials =
    { ... }:
    {

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking.hostName = "zenbook"; # Define your hostname.
      networking.networkmanager.enable = true; # Enable networking
      programs.openvpn3.enable = true;
      services.printing.enable = true; # Enable CUPS to print documents.
      hardware.bluetooth.enable = true; # enables support for Bluetooth

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      documentation.dev.enable = true;
    };

  module-keyboard = inputs: {
    services.xremap.watch = true;
    services.xremap.config.modmap = [
      {
        name = "Global";
        remap = {
          "CapsLock" = {
            held = "Ctrl_R";
            alone = "Esc";
            alone_timeout = 200;
          };
        };
      }
    ];
  };

  module-user =
    { pkgs, ... }:
    {
      environment.sessionVariables = {
        FLAKE = "/home/${user}/Machine";
        # home dir cleanup
        XCOMPOSECACHE = "$HOME/.cache/compose-cache";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_CACHE_HOME = "$HOME/.cache";
        GTK2_RC_FILES = "$HOME/.config/gtk-2.0/gtkrc-2.0";
      };

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users.odmin = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
        ];
      };

      # settings ZSH as default
      users.users.odmin.shell = pkgs.zsh;
      environment.shells = [ pkgs.zsh ];
      # Many programs look at /etc/shells to determine if a user is a "normal" user and not a "system" user.
      programs.zsh.enable = true;
    };

  # module_desktop-Plasma =
  #   { pkgs, ... }:
  #   {

  #     # Disable drag release delay
  #     services.libinput.touchpad.tappingDragLock = false;

  #     services.displayManager.sddm.enable = true;
  #     services.displayManager.sddm.wayland.enable = true;
  #     services.desktopManager.plasma6.enable = true;
  #   };

  module-desktop-Niri =
    {
      inputs,
      pkgs,
      system,
      ...
    }:
    {
      imports = [
        (import ./rofi.nix { inherit user; })
      ];
      services.displayManager.ly.enable = true;
      home-manager.users.${user} = {
        imports = [
          ./waybar.nix
        ];

        programs.wpaperd = {
          enable = true;
          settings = {
            eDP-1 = {
              path = "~/Pictures/Wallpapers";
              sorting = "ascending";
            };
          };
        };
      };

      environment.systemPackages = [
        pkgs.xwayland-satellite
      ];
      # TODO:
      # - Applets: wifi, vpn, bluetooth, clipboard (cliphist), power profiles
      # - Rofi combi mode apps + useful commands like "wpaperd next-wallpaper"
      # - Brightness change
      # - Notifications popups
      # - gotmpl alacritty theme, rofi theme etc
      # - Apps: viewers for images
      # - Alacritty clipboard shortcuts
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${system}.niri;
      };
    };

  module-browser-Firefox =
    { ... }:
    {
      programs.firefox.enable = true;
      environment.sessionVariables = {
        MOZ_USE_XINPUT2 = "1";
      };
    };

  module-locale =
    { ... }:
    {
      # Set your time zone.
      time.timeZone = "Asia/Almaty";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "ru_RU.UTF-8";
        LC_IDENTIFICATION = "ru_RU.UTF-8";
        LC_MEASUREMENT = "ru_RU.UTF-8";
        LC_MONETARY = "ru_RU.UTF-8";
        LC_NAME = "ru_RU.UTF-8";
        LC_NUMERIC = "ru_RU.UTF-8";
        LC_PAPER = "ru_RU.UTF-8";
        LC_TELEPHONE = "ru_RU.UTF-8";
        LC_TIME = "ru_RU.UTF-8";
      };
    };

  module-audio =
    { ... }:
    {
      hardware.pulseaudio.enable = false;

      # Enable the RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand.
      # The PulseAudio server uses this to acquire realtime priority.
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };

  module-containers =
    { pkgs, ... }:
    {

      virtualisation.containers.enable = true;
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      environment.systemPackages = with pkgs; [
        lazydocker
        docker-compose
      ];
    };
in
configuration
