# Configuration NixOS

Configuration NixOS de Louis : flake unique, Home Manager intégré à NixOS, Plasma et Sway/SwayFX, pilotée depuis `/etc/nixos`.

## Structure

```text
.
├── flake.nix                       # inputs, overlay, configuration de l'hôte
├── flake.lock                      # versions verrouillées des dépendances
├── hosts/nixos/
│   ├── default.nix                 # assemblage de l'hôte nixos
│   └── hardware-configuration.nix  # configuration matérielle générée
├── home/                           # modules Home Manager de l'utilisateur louis
├── modules/nixos/
│   ├── core/                       # nix, locale, réseau, utilisateurs
│   ├── hardware/                   # audio, Bluetooth, boot, imprimante
│   ├── desktop/                    # Plasma, Sway, SwayFX
│   └── services/                   # flatpak, virtualisation, Android
├── pkgs/                           # overlay et dérivations de paquets
└── docs/                           # documentation longue (Ableton, OpenCode, Secure Boot)
```

Home Manager n'a qu'un seul point d'entrée : `home-manager.users.louis`, défini dans `hosts/nixos/default.nix` et appliqué à chaque rebuild NixOS. Il n'y a plus de `homeConfigurations` autonome.

## Prérequis

- NixOS avec les flakes activés.
- Le dépôt est utilisé depuis `/etc/nixos`.
- Les fichiers du flake doivent être suivis par Git : un flake local ne voit que les fichiers suivis.

## Commandes

Depuis `/etc/nixos` :

```bash
# Vérifier l'évaluation sans construire
nix flake check --no-build --show-trace

# Construire sans activer
sudo nixos-rebuild build --flake /etc/nixos#nixos

# Activer la configuration
sudo nixos-rebuild switch --flake /etc/nixos#nixos

# Mettre à jour les inputs puis activer
sudo nix flake update --flake /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## Alias utiles

Définis dans `home/shell.nix` :

| Alias | Action |
|---|---|
| `nixcheck` | `nixos-rebuild build` avec traces |
| `nixtest` | `nixos-rebuild test` |
| `nixrebuild` | `nixos-rebuild switch` + vérification Secure Boot |
| `nixboot` | `nixos-rebuild boot` + vérification Secure Boot |
| `nixupdate` | mise à jour du flake puis `nixos-rebuild switch` |
| `nixcleanup` | nettoyage du store Nix |
| `nixgit` | `git add -A` puis commit `wip` |
| `nixpush` | `git push` |
| `hmcheck` | build complet via `nixos-rebuild build` |
| `hmrebuild` | switch complet via `nixos-rebuild switch` |
| `codenix` | ouvre `/etc/nixos` dans VS Code en root |

`hmcheck` et `hmrebuild` restent des raccourcis, mais passent désormais par `nixos-rebuild` : Home Manager est appliqué par NixOS.

## enixcfg

`enixcfg` ouvre rapidement un fichier de configuration :

- principaux : `main home shell flake lock git editors apps theme`
- modules : préfixe `mod/`, par exemple `enixcfg mod/audio` ou `enixcfg mod/desktop`

## OpenCode

OpenCode CLI et OpenCode Desktop sont installés depuis `nixpkgs-unstable` via `home/opencode.nix`. Les mises à jour automatiques sont désactivées : le paquet suit le flake.

La configuration et les procédures de repli sont documentées dans `docs/opencode.md`.

## Notes

- Si une commande flake échoue à cause de Git, vérifier que les fichiers nécessaires sont suivis (`git add`).
- Après modification d'un alias, ouvrir un nouveau shell ou relancer la configuration.
- Les chemins en dur restants sont inventoriés dans `/etc/docs/refactor-nixos.md` et seront traités dans une session dédiée.
