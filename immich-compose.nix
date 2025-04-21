# Auto-generated using compose2nix v0.3.2-pre.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."immich_machine_learning" = {
    image = "ghcr.io/immich-app/immich-machine-learning:release";
    environment = {
      "DB_DATABASE_NAME" = "immich";
      "DB_HOSTNAME" = "immich_postgres";
      "DB_PASSWORD" = "changeme_immich_db_password";
      "DB_USERNAME" = "immich";
      "IMMICH_MACHINE_LEARNING_URL" = "http://immich_machine_learning:3003";
      "REDIS_HOSTNAME" = "immich_redis";
      "TZ" = "Europe/Berlin";
    };
    volumes = [
      "immich_immich_model_cache:/cache:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=immich-machine-learning"
      "--network=immich_immich_internal"
    ];
  };
  systemd.services."docker-immich_machine_learning" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_model_cache.service"
    ];
    requires = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_model_cache.service"
    ];
    partOf = [
      "docker-compose-immich-root.target"
    ];
    wantedBy = [
      "docker-compose-immich-root.target"
    ];
  };
  virtualisation.oci-containers.containers."immich_postgres" = {
    image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:739cdd626151ff1f796dc95a6591b55a714f341c737e27f045019ceabf8e8c52";
    environment = {
      "POSTGRES_DB" = "immich";
      "POSTGRES_INITDB_ARGS" = "--data-checksums";
      "POSTGRES_PASSWORD" = "changeme_immich_db_password";
      "POSTGRES_USER" = "immich";
    };
    volumes = [
      "immich_immich_pgdata:/var/lib/postgresql/data:rw"
    ];
    cmd = [ "postgres" "-c" "shared_preload_libraries=vectors.so" "-c" "search_path=\"$user\", public, vectors" "-c" "logging_collector=on" "-c" "max_wal_size=2GB" "-c" "shared_buffers=512MB" "-c" "wal_compression=on" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=database"
      "--network=immich_immich_internal"
    ];
  };
  systemd.services."docker-immich_postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_pgdata.service"
    ];
    requires = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_pgdata.service"
    ];
    partOf = [
      "docker-compose-immich-root.target"
    ];
    wantedBy = [
      "docker-compose-immich-root.target"
    ];
  };
  virtualisation.oci-containers.containers."immich_redis" = {
    image = "docker.io/redis:6.2-alpine@sha256:148bb5411c184abd288d9aaed139c98123eeb8824c5d3fce03cf721db58066d8";
    volumes = [
      "immich_immich_redis_data:/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=redis"
      "--network=immich_immich_internal"
    ];
  };
  systemd.services."docker-immich_redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_redis_data.service"
    ];
    requires = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_redis_data.service"
    ];
    partOf = [
      "docker-compose-immich-root.target"
    ];
    wantedBy = [
      "docker-compose-immich-root.target"
    ];
  };
  virtualisation.oci-containers.containers."immich_server" = {
    image = "ghcr.io/immich-app/immich-server:release";
    environment = {
      "DB_DATABASE_NAME" = "immich";
      "DB_HOSTNAME" = "immich_postgres";
      "DB_PASSWORD" = "changeme_immich_db_password";
      "DB_USERNAME" = "immich";
      "IMMICH_MACHINE_LEARNING_URL" = "http://immich_machine_learning:3003";
      "JWT_SECRET" = "changeme_immich_jwt_secret";
      "REDIS_HOSTNAME" = "immich_redis";
      "TZ" = "Europe/Berlin";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "immich_immich_upload:/usr/src/app/upload:rw"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.immich-secure.entrypoints" = "websecure";
      "traefik.http.routers.immich-secure.rule" = "Host(`photos.blokth.com`)";
      "traefik.http.routers.immich-secure.service" = "immich-service";
      "traefik.http.routers.immich-secure.tls" = "true";
      "traefik.http.services.immich-service.loadbalancer.server.port" = "3001";
    };
    dependsOn = [
      "immich_postgres"
      "immich_redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=immich-server"
      "--network=immich_immich_internal"
      "--network=proxy"
    ];
  };
  systemd.services."docker-immich_server" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_upload.service"
    ];
    requires = [
      "docker-network-immich_immich_internal.service"
      "docker-volume-immich_immich_upload.service"
    ];
    partOf = [
      "docker-compose-immich-root.target"
    ];
    wantedBy = [
      "docker-compose-immich-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-immich_immich_internal" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f immich_immich_internal";
    };
    script = ''
      docker network inspect immich_immich_internal || docker network create immich_immich_internal --driver=bridge
    '';
    partOf = [ "docker-compose-immich-root.target" ];
    wantedBy = [ "docker-compose-immich-root.target" ];
  };

  # Volumes
  systemd.services."docker-volume-immich_immich_model_cache" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect immich_immich_model_cache || docker volume create immich_immich_model_cache
    '';
    partOf = [ "docker-compose-immich-root.target" ];
    wantedBy = [ "docker-compose-immich-root.target" ];
  };
  systemd.services."docker-volume-immich_immich_pgdata" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect immich_immich_pgdata || docker volume create immich_immich_pgdata
    '';
    partOf = [ "docker-compose-immich-root.target" ];
    wantedBy = [ "docker-compose-immich-root.target" ];
  };
  systemd.services."docker-volume-immich_immich_redis_data" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect immich_immich_redis_data || docker volume create immich_immich_redis_data
    '';
    partOf = [ "docker-compose-immich-root.target" ];
    wantedBy = [ "docker-compose-immich-root.target" ];
  };
  systemd.services."docker-volume-immich_immich_upload" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect immich_immich_upload || docker volume create immich_immich_upload
    '';
    partOf = [ "docker-compose-immich-root.target" ];
    wantedBy = [ "docker-compose-immich-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-immich-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
