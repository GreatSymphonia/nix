# NixOS Config - Quickstart

Configuration NixOS modulaire avec Flakes, Home Manager et Plasma Manager.

## Layout des fichiers

- `flake.nix` : point d'entree principal (inputs + outputs)
- `flake.lock` : versions verrouillees des dependances
- `configuration.nix` : assemblage principal NixOS
- `hardware-configuration.nix` : config materielle auto-generee
- `.gitignore` : ignore les artefacts temporaires (ex: result)

### Home Manager

- `home/default.nix` : imports Home Manager
- `home/shell.nix` : aliases, enixcfg, completion bash
- `home/git.nix` : config Git + delta
- `home/editors.nix` : VS Code + extensions/settings
- `home/apps.nix` : applications user
- `home/theme.nix` : theme GTK/Qt + fonts
- `home/plasma.nix` : reglages Plasma

### Modules NixOS

- `modules/nixos/boot.nix`
- `modules/nixos/system-locale.nix`
- `modules/nixos/desktop.nix`
- `modules/nixos/audio.nix`
- `modules/nixos/bluetooth.nix`
- `modules/nixos/user.nix`
- `modules/nixos/packages.nix`
- `modules/nixos/nix-core.nix`
- `modules/nixos/virtualisation.nix`

## Prerequis

- NixOS avec flakes actifs
- Ce repo present dans `/etc/nixos`
- Fichiers flake suivis par Git (important pour evaluation flake)

## Demarrage rapide

Depuis `/etc/nixos`:

1. Verifier les changements
   - `git status`

2. Ajouter les fichiers utiles au suivi Git
   - `git add flake.nix flake.lock configuration.nix modules home .gitignore README.md`

3. Build NixOS (sans switch)
   - `sudo nixos-rebuild build --flake /etc/nixos#nixos`

4. Appliquer la config NixOS
   - `sudo nixos-rebuild switch --flake /etc/nixos#nixos`

5. Verifier/appliquer Home Manager
   - `nix run path:/etc/nixos#home-manager -- build --flake path:/etc/nixos#louis@nixos --no-out-link`
   - `nix run path:/etc/nixos#home-manager -- switch --flake path:/etc/nixos#louis@nixos`

## Aliases utiles

Definis dans `home/shell.nix`:

- `nixcheck` : build NixOS avec traces
- `nixtest` : test NixOS
- `nixrebuild` : switch NixOS
- `nixboot` : generation boot NixOS
- `nixupdate` : update flake + switch NixOS
- `hmcheck` : build Home Manager sans `result`
- `hmrebuild` : switch Home Manager
- `codenix` : ouvre `/etc/nixos` dans VS Code en sudo

## enixcfg (navigation rapide)

Commande helper pour ouvrir les fichiers de config:

- principaux: `main home shell flake lock git editors apps theme`
- modules: utiliser uniquement le prefixe `mod/`

Exemples:

- `enixcfg main`
- `enixcfg flake`
- `enixcfg mod/audio`
- `enixcfg mod/desktop`

## Notes

- Si une commande flake echoue avec un souci Git, verifier que les fichiers necessaires sont suivis.
- Si un alias n'est pas pris en compte, ouvrir un nouveau shell ou reappliquer la config.
