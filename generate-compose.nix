{ pkgs, lib, ... }:

let 
  listDirectories = folder: 
    let
      contents = builtins.readDir folder;

      directories = lib.filter (entry: builtins.isAttrs (builtins.readDir (folder + "/" + entry))) (lib.attrValues contents);
    in
      directories;

  findServices = builtins.filter (path:
    builtins.pathExists (path + "/docker-compose.yaml")
  ) (builtins.attrValues (listDirectories ./services));

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
