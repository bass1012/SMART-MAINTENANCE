#!/bin/bash

# Script pour obtenir un token admin
# Usage: ./get-admin-token.sh

BASE_URL="http://localhost:5000"

echo "🔑 Obtention token admin"
echo "========================"
echo ""

# Demander les credentials
read -p "Email admin: " EMAIL
read -sp "Mot de passe: " PASSWORD
echo ""

# Connexion
echo ""
echo "🔄 Connexion en cours..."
RESPONSE=$(curl -s -X POST "${BASE_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")

# Vérifier succès
SUCCESS=$(echo $RESPONSE | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
  TOKEN=$(echo $RESPONSE | jq -r '.data.token')
  ROLE=$(echo $RESPONSE | jq -r '.data.user.role')
  NAME=$(echo $RESPONSE | jq -r '.data.user.firstName')
  
  echo ""
  echo "✅ Connexion réussie!"
  echo "👤 Utilisateur: ${NAME}"
  echo "🎭 Rôle: ${ROLE}"
  echo ""
  
  if [ "$ROLE" = "admin" ]; then
    echo "🔑 TOKEN ADMIN:"
    echo "${TOKEN}"
    echo ""
    echo "Pour tester les analytics:"
    echo "./test-analytics-simple.sh ${TOKEN}"
  else
    echo "❌ Cet utilisateur n'est pas admin!"
    echo "Rôle actuel: ${ROLE}"
  fi
else
  echo ""
  echo "❌ Échec de connexion"
  echo "$RESPONSE" | jq '.'
fi
