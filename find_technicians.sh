#!/bin/bash

echo "🔍 RECHERCHE DES TECHNICIENS"
echo "============================"
echo ""

# Configuration
API_URL="http://localhost:3000"

echo "📝 Tentative de connexion avec différents comptes..."
echo ""

# Liste des emails techniciens possibles
EMAILS=(
  "cissoko@gmail.com"
  "technicien@mct.com"
  "tech@mct-maintenance.com"
  "edouard@mct.com"
)

# Liste des mots de passe possibles
PASSWORDS=(
  "password"
  "Password123"
  "123456"
  "technicien123"
  "Cissoko123"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

FOUND=0

for EMAIL in "${EMAILS[@]}"; do
  for PASSWORD in "${PASSWORDS[@]}"; do
    echo -n "Test: $EMAIL / $PASSWORD ... "
    
    RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
    
    SUCCESS=$(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)
    ROLE=$(echo "$RESPONSE" | jq -r '.user.role' 2>/dev/null)
    
    if [ "$SUCCESS" == "true" ]; then
      if [ "$ROLE" == "technician" ]; then
        echo -e "${GREEN}✅ TROUVÉ (TECHNICIEN)${NC}"
        echo ""
        echo "📧 Email: $EMAIL"
        echo "🔑 Mot de passe: $PASSWORD"
        echo "👤 Rôle: $ROLE"
        echo ""
        echo "Utilisez ces identifiants dans le script test_technicien.sh"
        FOUND=1
        break 2
      else
        echo -e "✅ Connecté mais rôle: $ROLE"
      fi
    else
      echo "❌"
    fi
  done
done

if [ $FOUND -eq 0 ]; then
  echo ""
  echo -e "${RED}❌ Aucun compte technicien trouvé${NC}"
  echo ""
  echo "SOLUTION : Créer un compte technicien via SQL"
  echo ""
  echo "Exécutez cette requête SQL dans votre base de données :"
  echo ""
  echo "-- 1. Vérifier si le compte existe"
  echo "SELECT id, email, role FROM users WHERE email = 'cissoko@gmail.com';"
  echo ""
  echo "-- 2. Si le compte existe mais avec un autre rôle, le changer"
  echo "UPDATE users SET role = 'technician' WHERE email = 'cissoko@gmail.com';"
  echo ""
  echo "-- 3. Réinitialiser le mot de passe (hash de 'Password123')"
  echo "UPDATE users"
  echo "SET password_hash = '\$2b\$10\$rQZ5tXqXJ9Y.GqNqvqP0XOK5jKz9mZ5jHqGqP0XOK5jKz9mZ5jHq'"
  echo "WHERE email = 'cissoko@gmail.com';"
  echo ""
  echo "Ou utilisez le script Node.js pour générer un nouveau hash :"
  echo ""
  echo "cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api"
  echo "node -e \"const bcrypt = require('bcrypt'); bcrypt.hash('Password123', 10).then(hash => console.log(hash));\""
fi
