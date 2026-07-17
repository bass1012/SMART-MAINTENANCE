#!/bin/sh

# Fail this script if any subcommand fails.
set -e

echo "=== Démarrage du script ci_post_clone.sh ==="
echo "Current directory: $(pwd)"
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

# Go to the Flutter project root
if [ -f "$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile/pubspec.yaml" ]; then
    cd "$CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile"
elif [ -f "$CI_PRIMARY_REPOSITORY_PATH/pubspec.yaml" ]; then
    cd "$CI_PRIMARY_REPOSITORY_PATH"
else
    # Fallback to finding it
    PROJECT_DIR=$(dirname $(find "$CI_PRIMARY_REPOSITORY_PATH" -name "pubspec.yaml" | head -n 1))
    cd "$PROJECT_DIR"
fi

echo "=== Working directory is now: $(pwd) ==="

# Install Flutter using git.
echo "=== Installation de Flutter ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS
echo "=== Precache Flutter iOS ==="
flutter precache --ios

# Install Flutter dependencies.
echo "=== Installation des dépendances Flutter ==="
flutter pub get

# Install CocoaPods dependencies.
echo "=== Installation des pods iOS ==="
cd ios
export HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods
pod install --repo-update

echo "=== Script terminé avec succès ==="
