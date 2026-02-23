#!/bin/bash

# Script pour obtenir un token client pour tester les paiements
API_URL="http://localhost:3000"

echo "🔐 Obtention Token Client - MCT Maintenance"
echo "==========================================="
echo ""

# Option 1: Utiliser un compte existant
echo "Option 1: Se connecter avec un compte existant"
read -p "Email client: " EMAIL
read -sp "Mot de passe: " PASSWORD
echo ""
echo ""

echo "🔄 Connexion en cours..."
RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

# Vérifier si la réponse contient un token
if echo "$RESPONSE" | grep -q "token"; then
  # Extraire le token avec jq (plus fiable)
  if command -v jq &> /dev/null; then
    TOKEN=$(echo "$RESPONSE" | jq -r '.token')
    USER_NAME=$(echo "$RESPONSE" | jq -r '.user.email')
    USER_ROLE=$(echo "$RESPONSE" | jq -r '.user.role // "customer"')
  else
    # Fallback si jq n'est pas installé
    TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
    USER_NAME=$EMAIL
    USER_ROLE="customer"
  fi
  
  echo ""
  echo "✅ Connexion réussie !"
  echo "👤 Utilisateur: $USER_NAME"
  echo "🎭 Rôle: $USER_ROLE"
  echo ""
  echo "🔑 TOKEN:"
  echo "----------------------------------------"
  echo "$TOKEN"
  echo "----------------------------------------"
  echo ""
  
  # Sauvegarder le token
  echo "$TOKEN" > customer-token.txt
  echo "💾 Token sauvegardé dans customer-token.txt"
  echo ""
  
  # Afficher les prochaines étapes
  echo "🚀 PROCHAINES ÉTAPES:"
  echo ""
  echo "1. Testez le paiement avec ce script:"
  echo "   export TOKEN='$TOKEN'"
  echo "   ./test-cinetpay-quick.sh"
  echo ""
  echo "2. Ou copiez-collez le token dans test-cinetpay-payment.js"
  echo ""
  echo "3. Pour vérifier vos commandes:"
  echo "   curl -H 'Authorization: Bearer $TOKEN' $API_URL/api/orders | jq"
  echo ""
  
else
  echo ""
  echo "❌ Erreur de connexion"
  echo ""
  echo "Réponse du serveur:"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
  echo ""
  echo "💡 Vérifiez que:"
  echo "   - Le backend est lancé (sur le port 3000)"
  echo "   - L'email et le mot de passe sont corrects"
  echo "   - Le compte existe dans la base de données"
  echo ""
  echo "Pour créer un nouveau compte client, utilisez l'application mobile"
  echo "ou exécutez ce cURL:"
  echo ""
  echo "curl -X POST $API_URL/api/auth/register \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '{"
  echo "    \"email\": \"test@example.com\","
  echo "    \"password\": \"Test123!\","
  echo "    \"firstName\": \"Test\","
  echo "    \"lastName\": \"User\","
  echo "    \"phone\": \"0707070707\","
  echo "    \"role\": \"customer\""
  echo "  }'"
fi
