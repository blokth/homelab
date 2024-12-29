{ pkgs, lib, ... }:

let
  findServices =
    let
      paths = builtins.readDir ./services;
      isDir = name: paths.${name} == "directory";
      hasComposeFile = folder: builtins.pathExists ("./services/${folder}/docker-compose.yaml");
    in
    map (folder: "./services/${folder}")
      (lib.filterAttrs (n: isDir n && hasComposeFile n) paths);

  generateNix = projectDir: ''
    cd ${projectDir}
    ${pkgs.compose2nix} --project ${builtins.baseNameOf projectDir} --runtime docker
  '';

  generatedComposeFiles = builtins.filter (path:
    builtins.pathExists (path + "/docker-compose.nix")
  ) findServices;

in {
  imports = generatedComposeFiles;
  system.activationScripts.generateCompose = lib.mkForce (lib.concatStringsSep "\n" (map generateNix findServices));
}
