#!/bin/bash
# Test Correction Upload Images Produits
# Date : 16 octobre 2025

echo "🧪 Test Correction Upload Images Produits"
echo "=========================================="
echo ""

API_URL="http://localhost:3000"

# Test 1 : Vérifier le modèle Product
echo "1️⃣  Vérification du modèle Product..."
echo ""
node -e "
const { Product } = require('./src/models');
const imageField = Product.rawAttributes.images;
console.log('✅ Champ images existe');
console.log('   Type: ' + imageField.type.key);
console.log('   Default: ' + JSON.stringify(imageField.defaultValue));
console.log('   AllowNull: ' + imageField.allowNull);
"
echo ""

# Test 2 : Lister les produits existants
echo "2️⃣  Produits existants..."
PRODUCTS=$(curl -s "$API_URL/api/products" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
if (data.succes && data.donnees.produits.length > 0) {
  data.donnees.produits.forEach(p => {
    console.log('   Produit #' + p.id + ': ' + p.nom);
    console.log('   Images: ' + (p.images ? JSON.stringify(p.images) : '[]'));
  });
} else {
  console.log('   Aucun produit trouvé');
}
")
echo "$PRODUCTS"
echo ""

# Test 3 : Vérifier les fichiers uploadés
echo "3️⃣  Fichiers dans uploads/products/..."
if [ -d "uploads/products" ]; then
  FILE_COUNT=$(ls uploads/products/ 2>/dev/null | grep -v ".gitkeep" | wc -l | tr -d ' ')
  if [ "$FILE_COUNT" -gt 0 ]; then
    echo "   $FILE_COUNT fichier(s) trouvé(s) :"
    ls -lh uploads/products/ | grep -v ".gitkeep" | grep -v "^total" | awk '{print "   - "$9" ("$5")"}'
  else
    echo "   Aucun fichier uploadé"
  fi
else
  echo "   ❌ Dossier uploads/products/ manquant"
fi
echo ""

# Instructions test manuel
echo "📝 Test Manuel à Effectuer"
echo "=========================="
echo ""
echo "1. Ouvrir : http://localhost:3001"
echo "2. Aller dans : Menu → Produits"
echo ""
echo "TEST A : Nouveau produit avec image"
echo "   → Cliquer 'Nouveau produit'"
echo "   → Remplir : Nom, Référence, Prix, etc."
echo "   → Cliquer 'OK' (zone image grisée = normal)"
echo "   → Cliquer 'Modifier' sur le produit créé"
echo "   → Upload une image"
echo "   → Vérifier message 'Image uploadée avec succès'"
echo "   → Fermer le modal"
echo "   → Vérifier : Image visible dans la colonne 'Image' ✅"
echo ""
echo "TEST B : Modification image existante"
echo "   → Cliquer 'Modifier' sur un produit avec image"
echo "   → Vérifier : Image existante affichée en preview ✅"
echo "   → Changer l'image si souhaité"
echo ""
echo "TEST C : Suppression image"
echo "   → Cliquer 'Modifier' sur un produit avec image"
echo "   → Cliquer 'Supprimer l'image'"
echo "   → Fermer le modal"
echo "   → Vérifier : Image disparue de la liste ✅"
echo ""

echo "🔍 Vérification Backend Post-Upload"
echo "===================================="
echo ""
echo "Après avoir uploadé une image, exécutez :"
echo ""
echo "# Vérifier le produit en base"
echo "curl http://localhost:3000/api/products/1 | jq '.donnees.images'"
echo ""
echo "# Vérifier le fichier physique"
echo "ls -lh uploads/products/"
echo ""

echo "✅ Tests automatiques terminés"
echo ""
echo "📚 Documentation : cat CORRECTION_UPLOAD_IMAGES_PRODUITS.md"
