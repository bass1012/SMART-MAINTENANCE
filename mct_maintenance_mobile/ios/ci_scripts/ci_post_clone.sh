#!/bin/sh

# Ce script est exécuté par Xcode Cloud juste après avoir cloné le dépôt.

set -e

echo "=== Démarrage du script ci_post_clone.sh ==="

# On se place dans le dossier Flutter car Xcode Cloud se place par défaut à la racine du dépôt iOS.
# CI_PRIMARY_REPOSITORY_PATH pointe vers le dossier racine du dépôt Git (MAINTENANCE)
cd $CI_PRIMARY_REPOSITORY_PATH/mct_maintenance_mobile

echo "=== Installation de Flutter ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "=== Vérification de la version de Flutter ==="
flutter --version

echo "=== Installation des dépendances Flutter ==="
flutter pub get

echo "=== Installation des pods iOS ==="
cd ios
pod install --repo-update

echo "=== Script terminé avec succès ==="
