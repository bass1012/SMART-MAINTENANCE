#!/bin/bash

# Script pour obtenir un token d'authentification
API_URL="http://localhost:3000"

echo "🔐 Connexion à l'API MCT Maintenance"
echo "===================================="
echo ""

# Essayer de se connecter avec un compte admin par défaut
echo "Tentative de connexion avec admin@mct.com..."

RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mct.com",
    "password": "admin123"
  }')

if echo "$RESPONSE" | grep -q "token"; then
  TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
  echo "✅ Connexion réussie !"
  echo ""
  echo "📋 Token:"
  echo "$TOKEN"
  echo ""
  echo "💾 Token sauvegardé dans token.txt"
  echo "$TOKEN" > token.txt
  echo ""
  echo "🚀 Vous pouvez maintenant lancer:"
  echo "   ./test-notifications.sh $TOKEN"
else
  echo "❌ Erreur de connexion"
  echo "$RESPONSE"
  echo ""
  echo "💡 Essayez avec vos propres identifiants:"
  echo "   curl -X POST $API_URL/api/auth/login \\"
  echo "     -H 'Content-Type: application/json' \\"
  echo "     -d '{\"email\": \"votre@email.com\", \"password\": \"votrepassword\"}'"
fi
