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

# Vérifications non-bloquantes (|| true = n'arrête pas le script si ça rate)
ls "$FLUTTER_ROOT" || true

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

# Diagnostic non-bloquant
echo "=== Contenu ios/.symlinks (diagnostic) ==="
ls "$FLUTTER_ROOT/ios/.symlinks/plugins/" || echo "ATTENTION: .symlinks non trouvé"

# ── 5. CocoaPods ─────────────────────────────────────────────────────────────
echo "=== Recherche de CocoaPods ==="
POD_PATH=$(which pod 2>/dev/null || echo "")
if [ -n "$POD_PATH" ]; then
    echo "CocoaPods déjà disponible: $POD_PATH - $(pod --version)"
else
    echo "=== CocoaPods non trouvé, installation via sudo gem ==="
    sudo gem install cocoapods --no-document
    echo "CocoaPods installé: $(pod --version)"
fi

# ── 6. Pod install ────────────────────────────────────────────────────────────
IOS_DIR="$FLUTTER_ROOT/ios"
echo "=== pod install dans: $IOS_DIR ==="
cd "$IOS_DIR"
ls -la || true

pod install --repo-update

# Vérification non-bloquante
echo "=== Vérification Pods installés ==="
ls "$IOS_DIR/Pods/" | head -10 || echo "ATTENTION: Pods non créés!"

echo "=== Script terminé avec succès ==="
