#!/bin/bash

echo "🧪 Test rapide de notification d'intervention"
echo "=============================================="
echo ""

# Obtenir un token (essayer plusieurs comptes)
echo "🔐 Tentative de connexion..."

# Essai 1: admin@example.com
TOKEN=$(curl -s -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "admin123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  # Essai 2: client@example.com
  TOKEN=$(curl -s -X POST "http://localhost:3000/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email": "client@example.com", "password": "client123"}' \
    | grep -o '"token":"[^"]*' | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ]; then
  echo "❌ Impossible de se connecter"
  echo ""
  echo "💡 Veuillez vous connecter manuellement et obtenir un token:"
  echo "   1. Ouvrir Postman"
  echo "   2. POST http://localhost:3000/api/auth/login"
  echo "   3. Body: {\"email\": \"votre@email.com\", \"password\": \"password\"}"
  echo "   4. Copier le token"
  echo "   5. Relancer: ./test-intervention-simple.sh VOTRE_TOKEN"
  exit 1
fi

echo "✅ Connecté avec succès!"
echo ""

# Si un token est passé en paramètre, l'utiliser
if [ ! -z "$1" ]; then
  TOKEN="$1"
fi

echo "📋 Création d'une intervention de test..."
echo ""

RESPONSE=$(curl -s -X POST "http://localhost:3000/api/interventions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification - Climatiseur",
    "description": "Test du système de notifications en temps réel",
    "customer_id": 1,
    "scheduled_date": "2025-01-26T14:00:00Z",
    "priority": "high"
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo "✅ Intervention créée avec succès!"
  echo ""
  echo "📊 Vérifiez maintenant:"
  echo "   1. Dashboard web → Icône de cloche 🔔"
  echo "   2. Badge devrait afficher '1'"
  echo "   3. Toast 'Nouvelle demande d'intervention'"
  echo ""
  
  # Vérifier en base de données
  echo "🔍 Vérification en base de données..."
  cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
  NOTIF_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM notifications WHERE type='intervention_request';" 2>/dev/null)
  echo "   Notifications d'intervention en DB: $NOTIF_COUNT"
else
  echo "❌ Erreur lors de la création"
  echo "$RESPONSE"
fi
