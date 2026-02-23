#!/bin/bash

# 🎯 Script de démonstration LIVE pour FineoPay
# À exécuter devant l'équipe technique FineoPay

echo "===================================="
echo "🎯 DÉMONSTRATION FINEOPAY"
echo "===================================="
echo ""
echo "Business Code: smart_maintenance_by_mct"
echo "Environment: Sandbox/Dev"
echo ""

# Configuration
BUSINESS_CODE="smart_maintenance_by_mct"
API_KEY="fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923"
API_URL="https://dev.fineopay.com/api/v1/business/dev/checkout-link"
CALLBACK_URL="http://192.168.1.139:3000/api/fineopay/callback"

echo "===================================="
echo "ÉTAPE 1: GÉNÉRATION DU LIEN"
echo "===================================="
echo ""
echo "📤 Envoi de la requête à FineoPay API..."
echo "URL: $API_URL"
echo ""

# Générer un timestamp unique
TIMESTAMP=$(date +%s)
SYNC_REF="DEMO_${TIMESTAMP}"

# Créer le lien
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "businessCode: $BUSINESS_CODE" \
  -H "apiKey: $API_KEY" \
  -d "{
    \"title\": \"Démonstration Live FineoPay\",
    \"amount\": 1000,
    \"callbackUrl\": \"$CALLBACK_URL\",
    \"syncRef\": \"$SYNC_REF\"
  }")

echo "📥 RÉPONSE REÇUE:"
echo "$RESPONSE" | jq '.'
echo ""

# Extraire le checkoutLink
CHECKOUT_LINK=$(echo "$RESPONSE" | jq -r '.data.checkoutLink')

if [ "$CHECKOUT_LINK" != "null" ] && [ -n "$CHECKOUT_LINK" ]; then
  echo "✅ Lien généré avec succès!"
  echo ""
  echo "===================================="
  echo "ÉTAPE 2: VÉRIFICATION DU LIEN"
  echo "===================================="
  echo ""
  echo "🔗 CheckoutLink:"
  echo "$CHECKOUT_LINK"
  echo ""
  
  echo "⏰ Ouverture dans 3 secondes..."
  sleep 1
  echo "⏰ 2..."
  sleep 1
  echo "⏰ 1..."
  sleep 1
  
  # Ouvrir le lien dans le navigateur
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "$CHECKOUT_LINK"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open "$CHECKOUT_LINK"
  else
    echo "⚠️ Ouvrez manuellement ce lien dans votre navigateur:"
    echo "$CHECKOUT_LINK"
  fi
  
  echo ""
  echo "===================================="
  echo "RÉSULTAT ATTENDU"
  echo "===================================="
  echo ""
  echo "✅ Ce qui devrait se passer:"
  echo "   - Le navigateur s'ouvre"
  echo "   - La page FineoPay s'affiche"
  echo "   - L'utilisateur peut choisir son mode de paiement"
  echo ""
  echo "❌ Ce qui se passe actuellement:"
  echo "   - Le navigateur s'ouvre"
  echo "   - Message: 'Erreur interne du serveur'"
  echo "   - Aucune option de paiement visible"
  echo ""
  echo "===================================="
  echo "DÉTAILS TECHNIQUES"
  echo "===================================="
  echo ""
  echo "API Endpoint: $API_URL"
  echo "Business Code: $BUSINESS_CODE"
  echo "Sync Reference: $SYNC_REF"
  echo "Amount: 1000 FCFA"
  echo "Callback URL: $CALLBACK_URL"
  echo ""
  echo "Checkout URL retournée:"
  echo "$CHECKOUT_LINK"
  echo ""
  echo "Note: Le lien pointe vers demo.fineopay.com"
  echo "      alors que l'API est sur dev.fineopay.com"
  echo ""
  
else
  echo "❌ ERREUR: Impossible de générer le lien"
  echo ""
  echo "Réponse complète:"
  echo "$RESPONSE" | jq '.'
fi

echo "===================================="
echo "📊 TESTS SUPPLÉMENTAIRES"
echo "===================================="
echo ""

# Test avec différents montants
echo "Test avec 5 FCFA..."
TEST_5=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "businessCode: $BUSINESS_CODE" \
  -H "apiKey: $API_KEY" \
  -d "{\"title\":\"Test 5 FCFA\",\"amount\":5,\"callbackUrl\":\"$CALLBACK_URL\",\"syncRef\":\"TEST_5_${TIMESTAMP}\"}")

if echo "$TEST_5" | jq -e '.success == true' > /dev/null; then
  echo "✅ API accepte 5 FCFA"
  LINK_5=$(echo "$TEST_5" | jq -r '.data.checkoutLink')
  echo "   Lien: $LINK_5"
else
  echo "❌ API rejette 5 FCFA"
fi
echo ""

echo "Test avec 100 FCFA..."
TEST_100=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "businessCode: $BUSINESS_CODE" \
  -H "apiKey: $API_KEY" \
  -d "{\"title\":\"Test 100 FCFA\",\"amount\":100,\"callbackUrl\":\"$CALLBACK_URL\",\"syncRef\":\"TEST_100_${TIMESTAMP}\"}")

if echo "$TEST_100" | jq -e '.success == true' > /dev/null; then
  echo "✅ API accepte 100 FCFA"
  LINK_100=$(echo "$TEST_100" | jq -r '.data.checkoutLink')
  echo "   Lien: $LINK_100"
else
  echo "❌ API rejette 100 FCFA"
fi
echo ""

echo "Test avec 10000 FCFA..."
TEST_10000=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "businessCode: $BUSINESS_CODE" \
  -H "apiKey: $API_KEY" \
  -d "{\"title\":\"Test 10000 FCFA\",\"amount\":10000,\"callbackUrl\":\"$CALLBACK_URL\",\"syncRef\":\"TEST_10000_${TIMESTAMP}\"}")

if echo "$TEST_10000" | jq -e '.success == true' > /dev/null; then
  echo "✅ API accepte 10000 FCFA"
  LINK_10000=$(echo "$TEST_10000" | jq -r '.data.checkoutLink')
  echo "   Lien: $LINK_10000"
else
  echo "❌ API rejette 10000 FCFA"
fi
echo ""

echo "===================================="
echo "🎯 CONCLUSION"
echo "===================================="
echo ""
echo "✅ L'API FineoPay fonctionne (génère les liens)"
echo "❌ Les pages checkout ne fonctionnent pas (erreur 500)"
echo ""
echo "📋 Actions nécessaires:"
echo "   1. Vérifier la configuration du compte business"
echo "   2. Vérifier les logs serveur FineoPay"
echo "   3. Activer/configurer le compte sandbox"
echo "   4. Confirmer la whitelist des callback URLs"
echo ""
echo "💬 À discuter avec l'équipe FineoPay:"
echo "   - Pourquoi dev.fineopay.com retourne des liens demo.fineopay.com ?"
echo "   - Configuration manquante dans le dashboard ?"
echo "   - Compte business correctement activé ?"
echo ""
echo "===================================="
echo "Fin de la démonstration"
echo "===================================="
