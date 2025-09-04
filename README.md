# mkuritsu's dotfiles

This repository holds my dotfiles, I decided to separate this from my nixconfig repository to be more "distro agnostic" 
making it easier to share between non nixos systems.

## Requirements

To install the dotfiles nix and home-manager are used:
```bash
home-manager switch -f home.nix
```

If the system is a NixOS system you can pass NIXOS=1 as environment variable to the above command to add extra modules:
- browser extensions for chromium and firefox (this also installs both browsers through nixpkgs)
- nix managed neovim plugins
