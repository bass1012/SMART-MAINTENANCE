#!/bin/bash

echo "🧪 Test de notification - Intervention"
echo "======================================"
echo ""

# Créer une intervention de test via l'API
echo "📤 Création d'une intervention de test..."

# Vous devez remplacer TOKEN par un vrai token
TOKEN="YOUR_TOKEN_HERE"

if [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
  echo ""
  echo "⚠️  Pour utiliser ce script :"
  echo "   1. Connectez-vous au dashboard"
  echo "   2. F12 → Console"
  echo "   3. Tapez : localStorage.getItem('token')"
  echo "   4. Copiez le token"
  echo "   5. Relancez : ./test-intervention-notification.sh VOTRE_TOKEN"
  echo ""
  exit 1
fi

# Si un token est passé en paramètre
if [ ! -z "$1" ]; then
  TOKEN="$1"
fi

curl -X POST http://localhost:3000/api/interventions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test notification - Réparation urgente",
    "description": "Test du système de notifications en temps réel",
    "customer_id": 1,
    "scheduled_date": "2025-01-26T10:00:00Z",
    "priority": "high"
  }' | python3 -m json.tool

echo ""
echo "======================================"
echo ""
echo "✅ Intervention créée !"
echo ""
echo "👀 Vérifiez le dashboard :"
echo "   - Badge sur la cloche 🔔"
echo "   - Toast 'Nouvelle demande d'intervention'"
echo "   - Cliquez pour voir la notification"
echo ""
