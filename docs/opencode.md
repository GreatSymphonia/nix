# OpenCode

OpenCode est installé en deux parties :

- **CLI/TUI** : module Home Manager `programs.opencode` dans `home/opencode.nix` ;
- **client desktop** : paquet `opencode-desktop`, ajouté à `home.packages`.

Les deux proviennent de `nixpkgs-unstable` (version 2.x). Le handler `x-scheme-handler/opencode` est enregistré pour que les liens `opencode://` ouvrent le client desktop.

## Configuration actuelle

```nix
programs.opencode = {
  enable = true;
  package = unstable.opencode;
  settings.autoupdate = false;
  tui.theme = "system";
  extraPackages = with pkgs; [ git ripgrep fd ];
};

home.packages = [ unstable.opencode-desktop ];
```

`autoupdate = false` est important : sans cela, OpenCode tenterait de se mettre à jour hors de Nix et le binaire deviendrait incohérent avec le flake.

## Mise à jour

La version suit `nixpkgs-unstable` :

```bash
sudo nix flake update --flake /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## Repli 1 — revenir aux paquets stables

Si une régression unstable bloque l'usage, remplacer dans `home/opencode.nix` :

```nix
package = pkgs.opencode;                 # au lieu de unstable.opencode
home.packages = [ pkgs.opencode-desktop ]; # au lieu de unstable.opencode-desktop
```

La version stable de nixpkgs 26.05 est 1.15.10. Le reste de la configuration (settings, thème, handler MIME) reste identique.

## Repli 2 — utiliser un modèle non intégré

Si le modèle intégré par défaut pose problème (indisponibilité, quota, comportement), définir un modèle explicite dans les réglages Home Manager :

```nix
programs.opencode.settings = {
  autoupdate = false;
  model = "provider/model-id";
};
```

Le modèle doit correspondre à un fournisseur configuré dans OpenCode. La valeur exacte dépend du fournisseur utilisé ; la documenter ici après l'avoir validée.

## Vérification

```bash
opencode --version
command -v opencode-desktop
xdg-mime query default x-scheme-handler/opencode
```

La dernière commande doit renvoyer `ai.opencode.desktop.desktop`.
