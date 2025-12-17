#!/bin/bash

echo "🧪 Test de notification - Réclamation"
echo "====================================="
echo ""

TOKEN="${1:-YOUR_TOKEN_HERE}"

if [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
  echo "⚠️  Usage: ./test-complaint-notification.sh VOTRE_TOKEN"
  exit 1
fi

echo "📤 Création d'une réclamation de test..."
echo ""

RESPONSE=$(curl -s -X POST http://localhost:3000/api/complaints \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "subject": "Test notification - Produit défectueux",
    "description": "Test du système de notifications pour les réclamations",
    "priority": "high",
    "category": "product_quality"
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo "✅ Réclamation créée avec succès !"
  echo ""
  
  # Extraire l'ID de la réclamation
  COMPLAINT_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null)
  
  if [ ! -z "$COMPLAINT_ID" ]; then
    echo "📋 ID de la réclamation : $COMPLAINT_ID"
    echo ""
    echo "👀 Vérifiez le dashboard :"
    echo "   - Badge s'incrémente sur la cloche 🔔"
    echo "   - Toast 'Nouvelle réclamation'"
    echo "   - Cliquez sur la notification"
    echo "   - Devrait rediriger vers /reclamations/$COMPLAINT_ID"
  fi
else
  echo "❌ Erreur lors de la création"
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
fi

echo ""
