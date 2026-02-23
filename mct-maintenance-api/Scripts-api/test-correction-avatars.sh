#!/bin/bash
# Test Correction Upload Avatars Utilisateurs
# Date : 16 octobre 2025

echo "🧪 Test Correction Upload Avatars Utilisateurs"
echo "=============================================="
echo ""

API_URL="http://localhost:3000"

# Test 1 : Vérifier le modèle User
echo "1️⃣  Vérification du modèle User..."
echo ""
node -e "
const { User } = require('./src/models');
const profileField = User.rawAttributes.profile_image;
if (profileField) {
  console.log('✅ Champ profile_image existe');
  console.log('   Type: ' + profileField.type.key);
  console.log('   AllowNull: ' + profileField.allowNull);
} else {
  console.log('❌ Champ profile_image manquant');
}
"
echo ""

# Test 2 : Lister les utilisateurs avec avatars
echo "2️⃣  Utilisateurs existants avec avatars..."
curl -s "$API_URL/api/users" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
if (data.success && data.data && data.data.length > 0) {
  let usersWithAvatar = 0;
  data.data.forEach(u => {
    if (u.profile_image) {
      console.log('   User #' + u.id + ': ' + u.first_name + ' ' + u.last_name);
      console.log('   Avatar: ' + u.profile_image);
      console.log('');
      usersWithAvatar++;
    }
  });
  if (usersWithAvatar === 0) {
    console.log('   Aucun utilisateur avec avatar');
  } else {
    console.log('   Total: ' + usersWithAvatar + ' utilisateur(s) avec avatar');
  }
} else {
  console.log('   Aucun utilisateur trouvé');
}
"
echo ""

# Test 3 : Vérifier les fichiers uploadés
echo "3️⃣  Fichiers dans uploads/avatars/..."
if [ -d "uploads/avatars" ]; then
  FILE_COUNT=$(ls uploads/avatars/ 2>/dev/null | grep -v ".gitkeep" | wc -l | tr -d ' ')
  if [ "$FILE_COUNT" -gt 0 ]; then
    echo "   $FILE_COUNT fichier(s) trouvé(s) :"
    ls -lh uploads/avatars/ | grep -v ".gitkeep" | grep -v "^total" | awk '{print "   - "$9" ("$5")"}'
  else
    echo "   Aucun fichier uploadé"
  fi
else
  echo "   ❌ Dossier uploads/avatars/ manquant"
fi
echo ""

# Test 4 : Vérifier authController accepte profile_image
echo "4️⃣  Vérification authController.js..."
if grep -q "profile_image" src/controllers/auth/authController.js; then
  echo "   ✅ authController accepte profile_image"
else
  echo "   ⚠️  profile_image non trouvé dans authController"
fi
echo ""

# Test 5 : Vérifier userController accepte profile_image
echo "5️⃣  Vérification userController.js..."
if grep -q "profile_image" src/controllers/user/userController.js; then
  echo "   ✅ userController accepte profile_image"
else
  echo "   ⚠️  profile_image non trouvé dans userController"
fi
echo ""

# Instructions test manuel
echo "📝 Test Manuel à Effectuer"
echo "=========================="
echo ""
echo "1. Ouvrir : http://localhost:3001"
echo "2. Aller dans : Menu → Utilisateurs"
echo ""
echo "TEST A : Nouvel utilisateur avec avatar"
echo "   → Cliquer 'Nouvel utilisateur'"
echo "   → Remplir : Prénom, Nom, Email, Mot de passe, Rôle"
echo "   → Upload un avatar (zone preview circulaire)"
echo "   → Cliquer 'Enregistrer'"
echo "   → Vérifier : Avatar visible dans la liste ✅"
echo ""
echo "TEST B : Modification avatar existant"
echo "   → Cliquer 'Modifier' sur un utilisateur"
echo "   → Vérifier : Avatar existant affiché (si existe)"
echo "   → Upload un nouvel avatar"
echo "   → Vérifier : Message 'Avatar uploadé avec succès'"
echo "   → Fermer SANS enregistrer"
echo "   → Vérifier : Nouvel avatar visible dans la liste ✅"
echo ""
echo "TEST C : Suppression avatar"
echo "   → Cliquer 'Modifier' sur un utilisateur avec avatar"
echo "   → Cliquer 'Supprimer l'image'"
echo "   → Enregistrer"
echo "   → Vérifier : Avatar disparue de la liste ✅"
echo ""

echo "🔍 Vérification Backend Post-Upload"
echo "===================================="
echo ""
echo "Après avoir uploadé un avatar, exécutez :"
echo ""
echo "# Lister les utilisateurs avec avatars"
echo "curl http://localhost:3000/api/users | jq '.data[] | {id, first_name, profile_image}'"
echo ""
echo "# Vérifier un utilisateur spécifique"
echo "curl http://localhost:3000/api/users/5 | jq '.data.profile_image'"
echo ""
echo "# Vérifier les fichiers physiques"
echo "ls -lh uploads/avatars/"
echo ""

echo "✅ Tests automatiques terminés"
echo ""
echo "📚 Documentation : cat CORRECTION_UPLOAD_AVATARS_USERS.md"
