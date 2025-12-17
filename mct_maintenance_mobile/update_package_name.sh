#!/bin/bash

echo "🔄 Mise à jour du package name: example → remples"
echo "================================================"
echo ""

# Chemin de base
BASE_PATH="android/app/src/main/kotlin"
OLD_PATH="$BASE_PATH/com/example/mct_maintenance_mobile"
NEW_PATH="$BASE_PATH/com/remples/mct_maintenance_mobile"

# 1. Créer la nouvelle structure de dossiers
echo "1️⃣  Création de la nouvelle structure de dossiers..."
mkdir -p "$NEW_PATH"
echo "   ✅ Dossier créé: $NEW_PATH"

# 2. Copier MainActivity.kt
echo ""
echo "2️⃣  Copie de MainActivity.kt..."
if [ -f "$OLD_PATH/MainActivity.kt" ]; then
  cp "$OLD_PATH/MainActivity.kt" "$NEW_PATH/MainActivity.kt"
  echo "   ✅ Fichier copié"
else
  echo "   ⚠️  Fichier source non trouvé"
fi

# 3. Mettre à jour le package dans MainActivity.kt
echo ""
echo "3️⃣  Mise à jour du package dans MainActivity.kt..."
if [ -f "$NEW_PATH/MainActivity.kt" ]; then
  # Remplacer la ligne du package
  sed -i.bak 's/package com.example.mct_maintenance_mobile/package com.remples.mct_maintenance_mobile/' "$NEW_PATH/MainActivity.kt"
  rm -f "$NEW_PATH/MainActivity.kt.bak"
  echo "   ✅ Package mis à jour dans MainActivity.kt"
else
  echo "   ⚠️  Fichier MainActivity.kt non trouvé"
fi

# 4. Supprimer l'ancien dossier
echo ""
echo "4️⃣  Nettoyage de l'ancienne structure..."
if [ -d "$BASE_PATH/com/example" ]; then
  rm -rf "$BASE_PATH/com/example"
  echo "   ✅ Ancien dossier supprimé"
fi

echo ""
echo "================================================"
echo "✅ Migration terminée !"
echo ""
echo "📋 Nouveau package name: com.remples.mct_maintenance_mobile"
echo ""
echo "🔥 Utilisez ce package name dans Firebase Console !"
echo ""
