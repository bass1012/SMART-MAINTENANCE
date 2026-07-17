#!/bin/sh

# Fail this script if any subcommand fails.
set -e

echo "=== Démarrage du script ci_post_clone.sh ==="
echo "Current directory: $(pwd)"
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"
echo "HOME: $HOME"

# ── 1. Localiser le dossier Flutter ──────────────────────────────────────────
if [ -f "$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile/pubspec.yaml" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile"
elif [ -f "$CI_PRIMARY_REPOSITORY_PATH/pubspec.yaml" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
else
    FLUTTER_ROOT=$(dirname $(find "$CI_PRIMARY_REPOSITORY_PATH" -name "pubspec.yaml" | head -n 1))
fi

echo "=== FLUTTER_ROOT résolu: $FLUTTER_ROOT ==="
ls "$FLUTTER_ROOT"

# ── 2. Installer Flutter ──────────────────────────────────────────────────────
echo "=== Installation de Flutter ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"
flutter --version

# ── 3. Précacher les artefacts iOS ───────────────────────────────────────────
echo "=== Precache Flutter iOS ==="
flutter precache --ios

# ── 4. Installer les dépendances Dart ─────────────────────────────────────────
echo "=== flutter pub get dans: $FLUTTER_ROOT ==="
cd "$FLUTTER_ROOT"
flutter pub get

# Vérifier que les symlinks sont créés
echo "=== Vérification des symlinks Flutter ==="
ls "$FLUTTER_ROOT/ios/.symlinks/plugins/" | head -20

# ── 5. CocoaPods ─────────────────────────────────────────────────────────────
echo "=== Pod version disponible ==="
pod --version || echo "pod non disponible"

echo "=== Chemin du pod ==="
which pod || echo "pod non trouvé dans PATH"

echo "=== Installation/mise à jour de CocoaPods via sudo gem ==="
sudo gem install cocoapods --no-document
which pod
pod --version

# ── 6. Pod install ────────────────────────────────────────────────────────────
IOS_DIR="$FLUTTER_ROOT/ios"
echo "=== pod install dans: $IOS_DIR ==="
cd "$IOS_DIR"
ls -la

pod install --repo-update

# Vérifier que Pods est bien créé
echo "=== Vérification que les Pods sont installés ==="
ls -la "$IOS_DIR/Pods/" | head -20

echo "=== Script terminé avec succès ==="
