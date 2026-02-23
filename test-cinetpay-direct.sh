#!/bin/bash

# Test direct CinetPay avec montant fixe

API_URL="http://localhost:3000"
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NjYsImVtYWlsIjoiYmFzc2lyb3UyMDEwQGdtYWlsLmNvbSIsInJvbGUiOiJjdXN0b21lciIsImlhdCI6MTc2OTY3OTI1MywiZXhwIjoxNzcwMjg0MDUzfQ.jjlAWTUkqITaLaCJ3n1ZwfMvhFI962qWHHtkEeBXtJc"

echo "🧪 Test Paiement CinetPay Direct"
echo "================================"
echo ""

# 1. Créer une commande avec un montant valide via SQL
echo "📝 Création d'une commande de test..."
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite <<EOF
INSERT INTO Orders (customerId, total_amount, status, paymentStatus, shippingAddress, reference, createdAt, updatedAt)
VALUES (61, 10000, 'pending', 'pending', 'Abidjan Test', 'CMD-TEST-$(date +%s)', datetime('now'), datetime('now'));
SELECT 'ORDER_ID=' || last_insert_rowid();
EOF

# Récupérer l'ID de la commande créée
ORDER_ID=$(sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite "SELECT id FROM Orders ORDER BY id DESC LIMIT 1")

echo ""
echo "✅ Commande créée: #$ORDER_ID avec 10,000 FCFA"
echo ""

# 2. Initialiser le paiement
echo "💳 Initialisation du paiement..."
echo ""

RESPONSE=$(curl -s -X POST "${API_URL}/api/payments/cinetpay/initialize" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"orderId\": ${ORDER_ID}}")

echo "$RESPONSE" | jq .

# Extraire les données
PAYMENT_URL=$(echo "$RESPONSE" | jq -r '.data.payment_url')
TRANSACTION_ID=$(echo "$RESPONSE" | jq -r '.data.transaction_id')

if [ "$PAYMENT_URL" != "null" ]; then
  echo ""
  echo "✅ Paiement initialisé!"
  echo ""
  echo "🌐 URL de paiement:"
  echo "$PAYMENT_URL"
  echo ""
  echo "📋 Transaction ID: $TRANSACTION_ID"
  echo ""
  echo "🧪 Numéros de test CinetPay:"
  echo "   📱 Mobile Money Orange: 0707070707 (OTP: 1234)"
  echo "   💳 Carte bancaire: 4000000000000002 (Exp: 12/25, CVV: 123)"
  echo ""
  echo "💡 Ouvrez le lien dans votre navigateur pour payer"
else
  echo ""
  echo "❌ Erreur lors de l'initialisation"
fi
