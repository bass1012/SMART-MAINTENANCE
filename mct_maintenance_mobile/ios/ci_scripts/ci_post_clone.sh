#!/bin/sh

# Fail this script if any subcommand fails.
set -e

echo "=== Démarrage du script ci_post_clone.sh ==="
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

# ── 1. Localiser le dossier Flutter ──────────────────────────────────────────
if [ -f "$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile/pubspec.yaml" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile"
elif [ -f "$CI_PRIMARY_REPOSITORY_PATH/pubspec.yaml" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
else
    FLUTTER_ROOT=$(dirname $(find "$CI_PRIMARY_REPOSITORY_PATH" -name "pubspec.yaml" | head -n 1))
fi

echo "=== FLUTTER_ROOT: $FLUTTER_ROOT ==="

# ── 2. Installer Flutter ──────────────────────────────────────────────────────
echo "=== Installation de Flutter ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"
flutter --version

# ── 3. Précacher les artefacts iOS ───────────────────────────────────────────
echo "=== Precache Flutter iOS ==="
flutter precache --ios

# ── 4. flutter pub get (génère pubspec.lock, .dart_tool) ─────────────────────
echo "=== flutter pub get ==="
cd "$FLUTTER_ROOT"
flutter pub get

# ── 5. Générer les fichiers natifs iOS (GeneratedPluginRegistrant, xcconfig) ─
# Cette commande génère:
#   - ios/Runner/GeneratedPluginRegistrant.m (liste tous les plugins)
#   - ios/Flutter/Generated.xcconfig (FLUTTER_ROOT, chemins)
#   - ios/.symlinks/ (liens symboliques vers les plugins)
echo "=== Génération des fichiers iOS natifs ==="
flutter build ios --config-only --no-codesign || true

echo "=== Vérification de GeneratedPluginRegistrant.m ==="
ls -la "$FLUTTER_ROOT/ios/Runner/GeneratedPluginRegistrant.m" || echo "ATTENTION: GeneratedPluginRegistrant.m absent!"

# ── 6. CocoaPods (1.17.0 pré-installé sur les agents Xcode Cloud) ────────────
echo "=== CocoaPods version: $(pod --version) ==="

# ── 7. pod install ────────────────────────────────────────────────────────────
echo "=== pod install dans $FLUTTER_ROOT/ios ==="
cd "$FLUTTER_ROOT/ios"
pod install --repo-update

echo "=== Script terminé avec succès ==="
