#!/bin/bash

for dir in */; do
  if [ -d "$dir" ]; then
    base_dir = $(basename "$dir")
    echo "Generating docker-compose.nix in $base_dir"
    cd "$base_dir"
    nix run github:aksiksi/compose2nix -- --project "$base_dir" --runtime docker
  fi
done
