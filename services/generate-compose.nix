{ pkgs, lib, ... }:

let
  composeRoot = ./services;

  # Recursively find all subdirectories containing docker-compose.yaml
  findComposeProjects = dir:
    let
      paths = builtins.readDir dir;
      isDir = name: paths.${name} == "directory";
      hasComposeFile = folder: builtins.pathExists (dir + "/${folder}/docker-compose.yaml");
    in
    map (folder: dir + "/${folder}")
      (lib.filterAttrs (n: v: isDir n && hasComposeFile n) paths);

  # Run compose2nix directly in project directory
  generateNixFromCompose = projectDir: pkgs.runCommand "compose2nix-${builtins.baseNameOf projectDir}" { } ''
    cd ${projectDir}
    ${pkgs.compose2nix} --project ${builtins.baseNameOf projectDir} --runtime docker
  '';

  # Import the docker-compose.nix files from each project directory
  services = map (projectDir:
    import (projectDir + "/docker-compose.nix")
  ) (findComposeProjects composeRoot);

in {
  imports = services;
  system.activationScripts.generateCompose = lib.mkForce (lib.concatStringsSep "\n" (map generateNixFromCompose (findComposeProjects composeRoot)));
}
