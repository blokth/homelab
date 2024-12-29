{ pkgs, lib, ... }:

let
  findServices = builtins.filter (path:
    builtins.pathExists (path + "/docker-compose.yaml")
  ) (builtins.attrValues (lib.filesystem.listDirectoriesRecursive ./services));

  generateNix = projectDir: ''
    cd ${projectDir}
    ${pkgs.compose2nix} --project ${builtins.baseNameOf projectDir} --runtime docker
  '';

  generatedComposeFiles = builtins.filter (path:
    builtins.pathExists (path + "/docker-compose.nix")
  ) findServices;

in {
  imports = map (path: path + "/docker-compose.nix") generatedComposeFiles;
  system.activationScripts.generateCompose = lib.mkForce (lib.concatStringsSep "\n" (map generateNix findServices));
}
