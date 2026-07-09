#!/bin/bash

# Script de test rapide pour le paiement CinetPay

API_URL="http://localhost:3000"
TOKEN="${TOKEN:-}"
ORDER_ID="${ORDER_ID:-1}"

if [ -z "$TOKEN" ]; then
  echo "❌ TOKEN JWT requis. Exportez TOKEN avant d'exécuter ce script."
  exit 1
fi

echo "🧪 Test Paiement CinetPay"
echo ""

# Initialiser le paiement
echo "💳 Initialisation du paiement pour la commande #${ORDER_ID}..."
echo ""

RESPONSE=$(curl -s -X POST "${API_URL}/api/payments/cinetpay/initialize" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"orderId\": ${ORDER_ID}}")

echo "$RESPONSE" | jq .

# Extraire l'URL de paiement
PAYMENT_URL=$(echo "$RESPONSE" | jq -r '.data.payment_url')
TRANSACTION_ID=$(echo "$RESPONSE" | jq -r '.data.transaction_id')

if [ "$PAYMENT_URL" != "null" ]; then
  echo ""
  echo "✅ Paiement initialisé!"
  echo ""
  echo "🌐 Ouvrez cette URL dans votre navigateur:"
  echo "$PAYMENT_URL"
  echo ""
  echo "📋 Transaction ID: $TRANSACTION_ID"
  echo ""
  echo "🧪 Numéros de test CinetPay:"
  echo "   Mobile Money Orange: 0707070707 (OTP: 1234)"
  echo "   Carte: 4000000000000002 (Exp: 12/25, CVV: 123)"
  echo ""
  echo "⏳ Vérification du statut dans 30 secondes..."
  
  sleep 30
  
  echo ""
  echo "🔍 Vérification du statut..."
  curl -s "${API_URL}/api/payments/cinetpay/status/${TRANSACTION_ID}" \
    -H "Authorization: Bearer ${TOKEN}" | jq .
else
  echo ""
  echo "❌ Erreur lors de l'initialisation"
fi
