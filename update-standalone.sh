#!/usr/bin/env bash

nix --extra-experimental-features "nix-command flakes" run github:nix-community/home-manager -- switch -f home.nix -b backup
