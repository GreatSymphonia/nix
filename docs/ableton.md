# Ableton Live sous Wine

Module Home Manager pour exécuter Ableton Live sous Wine sur NixOS.
Inspiré de <https://github.com/korewaChino/live-on-linux>.

## Portée

Ce module **n'installe pas Ableton**. Nix ne peut pas packager de façon
reproductible un installateur Windows propriétaire : l'installation reste une
étape manuelle unique dans un préfixe Wine dédié.

Le module fournit tout ce qui l'entoure de façon déclarative :

- Wine et Winetricks ;
- un lanceur `abletonlive` équivalent au script amont ;
- l'entrée de bureau et les handlers MIME/URI, pour que les fichiers `.als` et
  les liens d'activation `ableton://` fonctionnent.

## Installation manuelle

Après `nixos-rebuild switch` :

1. Initialiser le préfixe dédié :

   ```bash
   WINEPREFIX=~/.wineableton wineboot
   ```

2. Installer les runtimes VC++ requis :

   ```bash
   WINEPREFIX=~/.wineableton winetricks vcrun2015 vcrun2017
   ```

3. Décompresser l'installateur et le lancer dans le même préfixe :

   ```bash
   cd ~/Downloads && unzip ableton/_live_standard_12.4.6_64.zip -d ableton-installer
   WINEPREFIX=~/.wineableton wine ableton-installer/*.exe
   ```

   Vérifier le chemin réellement écrit par l'installateur (gestionnaire de
   fichiers Wine ou `find ~/.wineableton -iname '*.exe'`). S'il ne correspond
   pas à `abletonExe` dans `home/ableton.nix`, ajuster `edition`/`liveVersion`
   ou définir le chemin directement.

4. Lancer depuis le menu d'applications, via `abletonlive` dans un terminal, ou
   en ouvrant un fichier `.als`.

## Notes

- **Max for Live** : en cas de crash au premier lancement, supprimer
  `~/.wineableton/drive_c/users/$USER/AppData/Roaming/Cycling '74/Max 8/Settings/maxpreferences.maxpref`
  puis relancer.
- **WineASIO** (audio faible latence via JACK/PipeWire) n'est pas dans nixpkgs.
  Il faudrait construire <https://github.com/wineasio/wineasio> soi-même (ou
  utiliser un overlay communautaire) et l'enregistrer dans le préfixe avec
  `wineasio-register`.
- **Attributs nixpkgs** : le module utilise `wineWow64Packages`, nom actuel de
  l'ensemble Wine multi-arch. Les anciens canaux utilisent `wineWowPackages`.
- **Binaire Wine** : depuis wine-staging 10.2, `wine64` a été fusionné dans
  `wine`, qui détecte l'architecture depuis le `.exe` ou le préfixe. Le lanceur
  appelle donc `wine`.
