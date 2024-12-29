#!/usr/bin/env bash

for dir in */; do
  if [ -d "$dir" ]; then
    base_dir=$(basename "$dir")
    echo "Generating docker-compose.nix in $base_dir"
    cd "$dir"
    nix run github:aksiksi/compose2nix -- --inputs docker-compose.yaml --project "$base_dir" --runtime docker
    cd ..
  fi
done
