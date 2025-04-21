# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{  pkgs, meta, ... }:

let
  dockerBin = "${pkgs.docker}/bin/docker";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./pihole-compose.nix
    ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.hostname; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none";
  networking.networkmanager.unmanaged = [ "interface-name:docker*" "interface-name:br-*" ];

  networking.useDHCP = false;
  networking.dhcpcd.enable = false;

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
    "8.8.4.4"
  ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  virtualisation.docker = {
    enable = true;
    extraOptions = "--iptables=false";
  };

  systemd.services.docker-create-network-proxy = {
    description = "Create Docker proxy network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''/etc/docker/create-proxy-network.sh'';
      User = "perun";
      Group = "docker";
    };
  };

  environment.etc."docker/create-proxy-network.sh" = {
    text = ''
    #!/bin/sh
    set -e

    if ! ${dockerBin} network inspect proxy >/dev/null 2>&1; then
      ${dockerBin} network create \
        --driver bridge \
        --subnet 172.20.0.0/16 \
        --gateway 172.20.0.1 \
        proxy
    fi
  '';
    mode = "0555";
  };

  services.traefik = {
    enable = true;


  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.perun = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel"
      "docker"
      "dialout"
      "tty"
      "uucp"
    ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    # Created using mkpasswd
    hashedPassword = "$6$CaCEWrNfJLit0lxA$ZUyRUZH9Vy6hlCseXfyRuz2KxYTtrAieGUqWRnpEnnJA3PdbJE8M.kmn6JKyMlYHRu7yNfvlM1F7oT7efwp7l.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFh6m4qX4U4sYAI+ngMuLACi4pqSz2pNjdPcB8aEzD6k"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     vim
     dig
     git
  ];

  # List services that you want to enable:

  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 
    80
    443
    53
    22
  ];
  networking.firewall.allowedUDPPorts = [ 
    53
  ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
