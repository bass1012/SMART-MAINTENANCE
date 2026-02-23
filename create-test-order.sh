#!/bin/bash

# Script pour créer une commande de test pour le paiement

API_URL="http://localhost:3000"
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NjYsImVtYWlsIjoiYmFzc2lyb3UyMDEwQGdtYWlsLmNvbSIsInJvbGUiOiJjdXN0b21lciIsImlhdCI6MTc2OTY3OTcxNywiZXhwIjoxNzcwMjg0NTE3fQ.BbM_-5iDpP904mSI3mrmaqQ-zvMfsXCCluYN7aKiEjw"

echo "🛒 Création d'une commande de test"
echo "==================================="
echo ""

# 1. Récupérer les produits disponibles
echo "📦 Récupération des produits..."
PRODUCTS=$(curl -s "${API_URL}/api/products/public" | jq '.data[0:3]')

if [ "$PRODUCTS" = "null" ] || [ -z "$PRODUCTS" ]; then
  echo "❌ Aucun produit trouvé"
  echo ""
  echo "💡 Créez d'abord des produits depuis le dashboard admin"
  exit 1
fi

PRODUCT_ID=$(echo "$PRODUCTS" | jq -r '.[0].id')
PRODUCT_NAME=$(echo "$PRODUCTS" | jq -r '.[0].nom')
PRODUCT_PRICE=$(echo "$PRODUCTS" | jq -r '.[0].prix')

echo "✅ Produit trouvé: $PRODUCT_NAME (${PRODUCT_PRICE} FCFA)"
echo ""

# 2. Créer la commande
echo "📝 Création de la commande..."

ORDER_DATA='{
  "items": [
    {
      "productId": '"$PRODUCT_ID"',
      "quantity": 2,
      "unitPrice": '"$PRODUCT_PRICE"'
    }
  ],
  "shippingAddress": "Abidjan, Cocody",
  "notes": "Commande de test pour CinetPay"
}'

RESPONSE=$(curl -s -X POST "${API_URL}/api/orders" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$ORDER_DATA")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
  ORDER_ID=$(echo "$RESPONSE" | jq -r '.data.id')
  TOTAL=$(echo "$RESPONSE" | jq -r '.data.totalAmount')
  
  echo "✅ Commande créée avec succès!"
  echo ""
  echo "📋 Détails de la commande:"
  echo "   ID: $ORDER_ID"
  echo "   Montant total: ${TOTAL} FCFA"
  echo ""
  echo "🚀 Vous pouvez maintenant tester le paiement:"
  echo ""
  echo "   1. Modifiez ORDER_ID dans test-cinetpay-quick.sh:"
  echo "      nano test-cinetpay-quick.sh"
  echo "      Changez ORDER_ID=\"$ORDER_ID\""
  echo ""
  echo "   2. Lancez le test de paiement:"
  echo "      ./test-cinetpay-quick.sh"
  echo ""
  
  # Sauvegarder l'ORDER_ID
  echo "$ORDER_ID" > last-order-id.txt
  echo "💾 ORDER_ID sauvegardé dans last-order-id.txt"
  
else
  echo "❌ Erreur lors de la création de la commande"
  echo ""
  echo "Réponse:"
  echo "$RESPONSE" | jq .
fi
