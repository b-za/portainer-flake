{
  description = "Portainer on Nix Flakes";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: {
    nixosModules = rec {
      default = portainer;
      portainer = import ./modules/portainer.nix;
      edge-agent = import ./modules/edge-agent.nix;
    };
  };
}
