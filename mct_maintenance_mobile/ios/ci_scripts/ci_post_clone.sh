#!/bin/sh

# Fail this script if any subcommand fails.
set -e

echo "=== Démarrage du script ci_post_clone.sh ==="
echo "Current directory: $(pwd)"
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

# ── 1. Localiser le dossier Flutter ──────────────────────────────────────────
if [ -f "$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile/pubspec.yaml" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile"
elif [ -f "$CI_PRIMARY_REPOSITORY_PATH/pubspec.yaml" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
else
    FLUTTER_ROOT=$(dirname $(find "$CI_PRIMARY_REPOSITORY_PATH" -name "pubspec.yaml" | head -n 1))
fi

echo "=== Flutter project root: $FLUTTER_ROOT ==="
cd "$FLUTTER_ROOT"

# ── 2. Installer Flutter ──────────────────────────────────────────────────────
echo "=== Installation de Flutter ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "=== Version de Flutter ==="
flutter --version

# ── 3. Précacher les artefacts iOS ───────────────────────────────────────────
echo "=== Precache Flutter iOS ==="
flutter precache --ios

# ── 4. Installer les dépendances Dart (génère les .symlinks iOS) ─────────────
echo "=== Installation des dépendances Flutter ==="
flutter pub get

# ── 5. Installer CocoaPods ────────────────────────────────────────────────────
# Essayer la version déjà installée en premier, puis fallback sur gem
echo "=== Vérification de CocoaPods ==="
if command -v pod &>/dev/null; then
    echo "CocoaPods déjà disponible: $(pod --version)"
else
    echo "=== Installation de CocoaPods via sudo gem ==="
    sudo gem install cocoapods --no-document
    echo "CocoaPods installé: $(pod --version)"
fi

# ── 6. Installer les pods iOS ─────────────────────────────────────────────────
echo "=== Installation des pods iOS ==="
cd "$FLUTTER_ROOT/ios"
echo "Contenu du dossier ios:"
ls -la
pod install --repo-update

echo "=== Script terminé avec succès ==="
