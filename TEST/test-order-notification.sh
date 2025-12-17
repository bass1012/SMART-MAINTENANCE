#!/bin/bash

echo "🧪 Test de notification - Commande"
echo "==================================="
echo ""

TOKEN="${1:-YOUR_TOKEN_HERE}"

if [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
  echo "⚠️  Usage: ./test-order-notification.sh VOTRE_TOKEN"
  exit 1
fi

echo "📤 Création d'une commande de test..."
echo ""

RESPONSE=$(curl -s -X POST http://localhost:3000/api/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "product_id": 1,
        "quantity": 2
      }
    ],
    "shipping_address": "123 Test Street, Abidjan, Côte d'\''Ivoire",
    "payment_method": "mobile_money",
    "notes": "Test notification système"
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo "✅ Commande créée avec succès !"
  echo ""
  
  # Extraire l'ID de la commande
  ORDER_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null)
  
  if [ ! -z "$ORDER_ID" ]; then
    echo "📋 ID de la commande : $ORDER_ID"
    echo ""
    echo "👀 Vérifiez le dashboard :"
    echo "   - Badge s'incrémente sur la cloche 🔔"
    echo "   - Toast 'Nouvelle commande'"
    echo "   - Cliquez sur la notification"
    echo "   - Devrait rediriger vers /commandes/$ORDER_ID"
  fi
else
  echo "❌ Erreur lors de la création"
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
fi

echo ""
