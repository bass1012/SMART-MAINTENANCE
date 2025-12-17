#!/bin/bash

# Script simple pour tester les tests E2E
cd "$(dirname "$0")"

# Ajouter patrol au PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

echo "🧪 Lancement des tests simples..."
echo ""

patrol test \
  --target integration_test/simple_test.dart \
  --device emulator-5554 \
  --verbose

echo ""
echo "✅ Test terminé !"
