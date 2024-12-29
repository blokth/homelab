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

  # Collect paths to docker-compose.nix files
  generatedComposeFiles = map (projectDir:
    let
      composeFile = projectDir + "/docker-compose.nix";
    in
    if builtins.pathExists composeFile then
      composeFile
    else
      null
  ) (findComposeProjects composeRoot);

  # Remove nulls from the list (if a service hasn't generated a nix file yet)
  validImports = lib.filter (x: x != null) generatedComposeFiles;

in {
  imports = validImports;
  system.activationScripts.generateCompose = lib.mkForce (lib.concatStringsSep "\n" (map generateNixFromCompose (findComposeProjects composeRoot)));
}
