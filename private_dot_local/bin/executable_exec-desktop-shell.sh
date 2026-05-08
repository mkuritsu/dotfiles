#!/usr/bin/env bash

# Need this so it works across nixos/other distros (e.g arch)
# - in NixOS noctalia-shell package exposes the noctalia-shell binary to executed it
# - in Arch noctalia-shell package install qs and it should run with qs -c noctalia-shell
if command -v noctalia-shell >/dev/null 2>&1; then
    exec noctalia-shell "$@"
else
    exec qs -c noctalia-shell "$@"
fi
