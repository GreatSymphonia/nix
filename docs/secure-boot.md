# Secure Boot — état de situation (2026-08-24)

## Objectif
Activer le Secure Boot avec des clés générées localement (PK/KEK/db), en gardant
le dual-boot Windows fonctionnel (le certificat Microsoft UEFI CA reste dans le
`db` — Windows continue de valider via sa propre signature, jamais re-signé).

## Fait

- **`flake.nix`** : ajout de l'input `lanzaboote` (branche principale — le tag
  `v0.4.2` pointait vers un `rust-overlay` trop ancien pour compiler contre le
  nixpkgs actuel, réglé en suivant la branche `main`).
- **`modules/nixos/hardware/boot.nix`** :
  - `systemd-boot` désactivé (`lib.mkForce false`), remplacé par
    `boot.lanzaboote` (`pkiBundle = /etc/secureboot`).
  - `sbctl` ajouté aux paquets système.
  - `/etc/sbctl/sbctl.conf` déclaré explicitement pour que la CLI `sbctl`
    pointe vers `/etc/secureboot` (sinon elle retombe sur son défaut
    `/var/lib/sbctl`, différent du `pkiBundle` de lanzaboote — piège rencontré
    et corrigé pendant l'implémentation).
- **`home/shell.nix`** : fonction `nixsecureboot-check` (lance `sudo sbctl
  verify`) chaînée aux alias `nixrebuild`, `nixboot`, `nixupdate`.
- `sudo nixos-rebuild switch` appliqué avec succès : lanzaboote signe
  maintenant automatiquement chaque nouvelle génération NixOS
  (`/boot/EFI/Linux/nixos-generation-*.efi`, confirmé signé par `sbctl
  verify`).
- Clés Secure Boot générées : `sudo sbctl create-keys` → `/etc/secureboot`
  (PK/KEK/db). **Pas encore enrôlées dans le firmware.**
- Ménage sur l'ESP partagé (`/boot`) : une install **Arch Linux** orpheline
  (restes de boot uniquement — sa partition racine n'existe plus sur le
  disque, `root=UUID=768e4ba5-...` introuvable) a été détectée et retirée
  (`/boot/loader/entries/e00c609b...*.conf` et `/boot/e00c609b.../`
  supprimés). Sans ce nettoyage, Arch aurait cessé de démarrer sans
  avertissement une fois Secure Boot activé.
- `sbctl verify` est propre : toutes les générations NixOS actives sont
  signées. Deux items restent listés "not signed" mais sont sans impact :
  - `bootmgfw.efi` (Windows) — faux négatif attendu, `sbctl verify` ne
    reconnaît que les fichiers signés par **ses propres clés**, pas la
    signature Microsoft existante (qui elle reste valide).
  - `kernel-6.18.45-...efi` — résidu de l'ancien systemd-boot (générations
    195-199, pré-lanzaboote), plus référencé par aucune entrée de boot ; sera
    nettoyé automatiquement par le garbage collector au fil des prochains
    rebuilds (`configurationLimit = 5`).

## Post-mortem : pourquoi la db du firmware n'a pas bougé (2026-08-24)

Après le premier redémarrage et une tentative d'activation du Secure Boot
dans le firmware, `sbctl status` reportait toujours `Vendor Keys: microsoft`
et les variables EFI `SetupMode`/`SecureBoot` valaient `0` — la db du
firmware n'avait donc jamais reçu nos clés.

En rejouant l'historique (`journalctl`, boot précédent) : la séquence
réellement exécutée était `create-keys` → migration manuelle du
`pkiBundle` vers `/etc/secureboot` → `sbctl setup --migrate` →
`sbctl setup --setup`. La commande `sbctl enroll-keys` n'a été appelée
qu'avec `--help`, jamais réellement exécutée.

**Cause** : `sbctl setup` est une commande d'installation/migration
interne à sbctl (création des dossiers, génération des clés si absentes,
détection du `pkiBundle`) — elle ne touche **jamais** aux variables EFI.
Seule `sbctl enroll-keys` écrit PK/KEK/db dans le firmware. Confusion
probable avec d'autres tutoriels où `setup --setup` est parfois présenté
comme une étape suffisante.

**Conséquence** : il faut encore (1) repasser le firmware en Setup Mode
si ce n'est pas déjà fait, puis (2) lancer réellement
`sudo sbctl enroll-keys --microsoft`.

## Enrollment effectué (2026-08-24)

Le firmware était déjà en Setup Mode (constaté via `sbctl status` :
`Setup Mode: ✓ Enabled`, `Secure Boot: ✗ Disabled`, `Vendor Keys: none`).
`sudo sbctl enroll-keys --microsoft` a été exécuté avec succès :

```
Enrolling keys to EFI variables...
With vendor keys from microsoft...✓
Enrolled keys to the EFI variables!
```

Vérification post-enroll (`sbctl status`) :
```
Setup Mode:	✓ Disabled
Secure Boot:	✗ Disabled
Vendor Keys:	microsoft
```
PK/KEK/db sont donc bien écrites dans le firmware, avec le certificat
Microsoft UEFI CA conservé dans `db`. `efi-readvar` (efitools) n'est pas
installé sur ce système, donc la vérification directe de la variable `db`
n'a pas pu être faite par cette commande — mais `Vendor Keys: microsoft`
dans `sbctl status` confirme déjà que le certificat Microsoft a bien été
inclus.

## Activation confirmée (2026-08-24)

Firmware redémarré avec Secure Boot activé. Vérifications post-reboot :

```
bootctl status
  Secure Boot: enabled (user)
  Current Stub: lanzastub 1.1.0

sudo sbctl status
  Setup Mode:   ✓ Disabled
  Secure Boot:  ✓ Enabled
  Vendor Keys:  microsoft

sudo sbctl verify
  Toutes les générations NixOS présentes (197-201) : ✓ signed
  BOOTX64.EFI et systemd-bootx64.efi : ✓ signed
  Fichiers Microsoft (bootmgfw.efi, locales, memtest...) : ✗ not signed
    → attendu, signature Microsoft propre non reconnue par sbctl
  kernel-6.18.45-...efi : ✗ not signed
    → résidu pré-lanzaboote, sera nettoyé par le GC (configurationLimit = 5)
```

Secure Boot est donc bien **actif** avec nos clés, dual-boot Windows préservé.

## Pas encore fait / à faire

1. Redémarrer une fois **dans Windows** pour confirmer qu'il boote toujours
   normalement (aucune action requise de notre côté puisque `--microsoft` a
   été utilisé à l'enrollment).

## Routine ensuite

Rien à faire manuellement — `nixrebuild` / `nixboot` / `nixupdate` lancent
automatiquement `nixsecureboot-check` (= `sbctl verify`) après chaque
rebuild qui touche le bootloader.

## Fichiers concernés

- `flake.nix` : input `lanzaboote`.
- `modules/nixos/hardware/boot.nix` : `boot.lanzaboote`, `sbctl`, `/etc/sbctl/sbctl.conf`.
- `home/shell.nix` : fonction `nixsecureboot-check`, appelée par `nixrebuild`, `nixboot` et `nixupdate`.
