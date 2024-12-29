#!/bin/bash

for dir in */; do
  if [ -d "$dir" ]; then
    echo "Generating docker-compose.nix in $dir"
    nix run github:aksiksi/compose2nix -- --project "$dir" --runtime docker
  fi
done
