#!/bin/bash

echo "🧪 Création d'une réclamation via l'API"
echo "======================================="
echo ""

# Chercher un token admin pour créer au nom d'un client
echo "📋 Configuration..."
echo ""

# On va créer directement la réclamation
# Customer ID 8 = Bassirou (user actif)

echo "📤 Envoi de la requête API..."
echo ""

RESPONSE=$(curl -s -X POST http://localhost:3000/api/complaints \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 8,
    "subject": "🧪 Test notification - Réclamation temps réel",
    "description": "Test du système de notifications en temps réel pour les réclamations",
    "priority": "high",
    "category": "product_quality"
  }')

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

echo ""
echo "======================================"
echo ""

if echo "$RESPONSE" | grep -q "success"; then
  echo "✅ Réclamation créée avec succès !"
  echo ""
  echo "👀 Vérifiez IMMÉDIATEMENT le dashboard :"
  echo "   - Badge apparaît sur la cloche 🔔"
  echo "   - Toast 'Nouvelle réclamation'"
  echo "   - Message avec le nom du client"
  echo ""
  
  # Extraire l'ID
  COMPLAINT_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null)
  if [ ! -z "$COMPLAINT_ID" ]; then
    echo "   🔗 URL: /reclamations/$COMPLAINT_ID"
  fi
else
  echo "❌ Erreur lors de la création"
  echo ""
  echo "💡 L'API des réclamations nécessite peut-être l'authentification"
  echo "   Essayez avec le dashboard directement ou l'app mobile"
fi

echo ""
