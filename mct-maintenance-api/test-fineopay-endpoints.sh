#!/bin/bash

echo "🧪 Test de différents endpoints FineoPay"
echo "========================================"
echo ""

# Configuration
BUSINESS_CODE="smart_maintenance_by_mct"
API_KEY="fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923"

# Liste d'endpoints possibles
endpoints=(
  # Format 1 : Avec /api/v1
  "https://demo.fineopay.com/api/v1/checkout-link"
  "https://demo.fineopay.com/api/v1/payment/init"
  "https://demo.fineopay.com/api/v1/transaction/create"
  
  # Format 2 : Avec /api/v1/business
  "https://demo.fineopay.com/api/v1/business/checkout-link"
  "https://demo.fineopay.com/api/v1/business/payment/init"
  
  # Format 3 : Avec businessCode dans l'URL
  "https://demo.fineopay.com/${BUSINESS_CODE}/api/checkout-link"
  "https://demo.fineopay.com/${BUSINESS_CODE}/checkout-link"
  
  # Format 4 : Sans /api
  "https://demo.fineopay.com/checkout-link"
  "https://demo.fineopay.com/payment/create"
)

# Payload de test
PAYLOAD='{
  "title": "Test Payment",
  "amount": 1000,
  "callbackUrl": "http://localhost:3000/callback",
  "syncRef": "TEST_123"
}'

echo "📤 Test avec différents formats de headers et endpoints"
echo ""

test_endpoint() {
  local url=$1
  local header_format=$2
  
  echo "Testing: $url"
  echo "Headers: $header_format"
  
  case $header_format in
    "format1")
      RESPONSE=$(curl -s -w "\nHTTP:%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "businessCode: ${BUSINESS_CODE}" \
        -H "apiKey: ${API_KEY}" \
        -d "$PAYLOAD")
      ;;
    "format2")
      RESPONSE=$(curl -s -w "\nHTTP:%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "X-Business-Code: ${BUSINESS_CODE}" \
        -d "$PAYLOAD")
      ;;
    "format3")
      RESPONSE=$(curl -s -w "\nHTTP:%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "X-API-KEY: ${API_KEY}" \
        -H "X-BUSINESS-CODE: ${BUSINESS_CODE}" \
        -d "$PAYLOAD")
      ;;
  esac
  
  HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP:" | cut -d':' -f2)
  BODY=$(echo "$RESPONSE" | sed '/HTTP:/d' | head -c 500)
  
  echo "  → Status: $HTTP_CODE"
  
  # Vérifier si c'est du JSON
  if echo "$BODY" | jq '.' > /dev/null 2>&1; then
    echo "  → ✅ Response is JSON"
    echo "$BODY" | jq '.'
  elif [[ "$BODY" == *"<html"* ]] || [[ "$BODY" == *"<!DOCTYPE"* ]]; then
    echo "  → ❌ Response is HTML (endpoint incorrect)"
  else
    echo "  → Response: ${BODY:0:200}..."
  fi
  
  echo ""
}

# Tester chaque endpoint avec différents formats
for endpoint in "${endpoints[@]}"; do
  test_endpoint "$endpoint" "format1"
done

echo ""
echo "✅ Tests terminés !"
echo ""
echo "📝 ACTIONS À FAIRE:"
echo "  1. Contactez le support FineoPay pour obtenir:"
echo "     - La documentation API complète"
echo "     - L'URL exacte de l'endpoint"
echo "     - Le format des headers"
echo ""
echo "  2. Ou testez manuellement sur leur plateforme:"
echo "     - Allez sur https://demo.fineopay.com"
echo "     - Connectez-vous avec vos identifiants"
echo "     - Cherchez la documentation API dans le tableau de bord"
