{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.portainer;
in {
  options.services.portainer = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, run Portainer CE.
      '';
    };
    version = mkOption {
      type = types.str;
      default = "latest";
      description = ''
        Sets the Portainer-ce container version. Defaults to latest tag on docker hub. If you want another version, you can look here: https://hub.docker.com/r/portainer/portainer-ce/tags If you're also using the Edge Agent Module, you should, ideally, make sure these values match.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        By default, the portainer-ce instance is not network accessable, only via localhost:port. Set this to true if you plan on accessing it over the network.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 9443;
      description = ''
        Remaps the open firewall port to another port. Shouldn't be a reason to change this unless there is a port conflict.
      '';
    };
  };

  config = {
    virtualisation = {
      oci-containers = {
        containers.portainer-ce = mkIf cfg.enable {
          # Pulls from docker hub.
          image = "portainer/portainer-ce:${cfg.version}";
          # Drive mappings to system folders.
          volumes = [
            # This is where portainer-ce stores it's internal data and
            # databases
            "portainer_data:/data"
            #  # This is so portainer can access and control the systems
            # docker version.
            "/var/run/docker.sock:/var/run/docker.sock"
            # So logging matches local time. Unless you *like* doing
            # that sort of math?!
            "/etc/localtime:/etc/localtime"
          ];
          # Since this is a service you need to access, you must also
          # open the ports on the container itself.
          ports = let
            port = "${builtins.toString cfg.port}:9443";
          in [
            port # Portainer UI
          ];
          autoStart = true;
          extraOptions = [
            "--pull=always"
            "--restart=unless-stopped"
            "--rm=false"
          ];
        };
        # I assume, as I have not tested, that we need to use the real
        # deal. It might work with podman?
        backend = "docker";
      };
      docker = {
        enable = true;
      };
    };
    networking = {
      # Docker uses iptables...
      # https://search.nixos.org/options?channel=unstable&show=networking.nftables.enable&from=0&size=50&sort=relevance&type=packages&query=iptables
      # From the documentation:
      # > Note that if you have Docker enabled you will not be able to
      # use nftables without intervention. Docker uses iptables
      # internally to setup NAT for containers. This module disables
      # the ip_tables kernel module, however Docker automatically loads
      # the module. Please see
      # https://github.com/NixOS/nixpkgs/issues/24318#issuecomment-289216273
      # for more information.
      # Sorry. You'll live. I know. It's a whole thing.
      nftables.enable = false;
      firewall = {
        allowedTCPPorts = mkIf cfg.openFirewall [
          cfg.port #Portainer UI
        ];
        # Allow the docker network interface as a trusted network
        # interface. This is so docker can do things like
        # creating new network interfaces.
        trustedInterfaces = ["docker0"];
      };
    };
  };
}
