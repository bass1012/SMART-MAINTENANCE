#!/bin/bash

echo "🧪 Test de l'API FineoPay"
echo "========================="
echo ""

# Variables
BASE_URL="https://demo.fineopay.com/api/v1/business"
BUSINESS_CODE="smart_maintenance_by_mct"
API_KEY="fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923"

echo "📋 Configuration:"
echo "  - URL: $BASE_URL"
echo "  - Business Code: $BUSINESS_CODE"
echo "  - API Key: ${API_KEY:0:20}..."
echo ""

# Test 1 : Créer un lien de paiement
echo "🔹 Test 1 : Création d'un lien de paiement"
echo "-------------------------------------------"

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${BASE_URL}/checkout-link" \
  -H "Content-Type: application/json" \
  -H "businessCode: ${BUSINESS_CODE}" \
  -H "apiKey: ${API_KEY}" \
  -d '{
    "title": "Test Paiement MCT",
    "amount": 1000,
    "callbackUrl": "http://192.168.1.139:3000/api/fineopay/callback",
    "syncRef": "TEST_ORDER_999"
  }')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

echo "Status HTTP: $HTTP_CODE"
echo "Réponse:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

# Test 2 : Vérifier si l'URL est correcte
echo "🔹 Test 2 : Vérification de l'endpoint"
echo "---------------------------------------"

# Tester différentes URLs
URLS=(
  "https://demo.fineopay.com/api/v1/business/checkout-link"
  "https://dev.fineopay.com/api/v1/business/checkout-link"
  "https://api.fineopay.com/v1/business/checkout-link"
)

for URL in "${URLS[@]}"; do
  echo "Testing: $URL"
  curl -s -o /dev/null -w "  → HTTP %{http_code}\n" -X POST "$URL" \
    -H "Content-Type: application/json" \
    -H "businessCode: ${BUSINESS_CODE}" \
    -H "apiKey: ${API_KEY}" \
    -d '{"title":"Test","amount":100}'
done

echo ""
echo "✅ Tests terminés !"
echo ""
echo "📝 Notes:"
echo "  - Si HTTP 200/201 : L'API fonctionne ✅"
echo "  - Si HTTP 401/403 : Problème d'authentification ❌"
echo "  - Si HTTP 404 : URL incorrecte ❌"
echo "  - Si HTTP 500 : Erreur serveur FineoPay ❌"
