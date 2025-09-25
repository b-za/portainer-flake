{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.portainer-edge-agent;
in {
  options.services.portainer-edge-agent = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, run container edge agent.
      '';
    };
    version = mkOption {
      type = types.str;
      default = "latest";
      description = ''
        Sets the Edge Agent Container version. Defaults to latest. Should match your Portainer CE version.
      '';
    };
    id = mkOption {
      type = types.str;
      description = ''
        Sets the Edge Agent Edge ID. You should be getting this from the edge agent setup wizard.
      '';
    };
    key = mkOption {
      type = types.str;
      description = ''
        Sets the Edge Agent Edge Key. You should be getting this from the edge agent setup wizard. N
      '';
    };
    port = mkOption {
      type = types.port;
      default = 9443;
      description = ''
        Remaps the open firewall port to another port. Shouldn't be a reason to change this unless there is a port conflict.
      '';
    };
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = ''
        By default, we open it up; this is going to be user on other computers across a network. Set to false, if you have some other internal routing method.
      '';
    };
  };

  config = {
    virtualisation = {
      # Use actual docker, not podman.
      docker = {
        enable = true;
      };
      oci-containers = {
        containers.portainer-edge-agent = mkIf cfg.enable {
          image = "portainer/agent:${cfg.version}";
          volumes = [
            "/:/host"
            "/var/lib/docker/volumes:/var/lib/docker/volumes"
            "/var/run/docker.sock:/var/run/docker.sock"
            "portainer_agent_data:/data"
          ];
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
          environment = {
            EDGE = "1";
            EDGE_ID = cfg.id;
            EDGE_INSECURE_POLL = "1";
            EDGE_KEY = cfg.key;
          };
        };
        backend = "docker";
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
        # Allow the docker network interface as a trusted network interface.
        trustedInterfaces = ["docker0"];
      };
    };
  };
}
