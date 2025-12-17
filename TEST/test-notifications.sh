#!/bin/bash

# Script de test pour les notifications MCT Maintenance
# Usage: ./test-notifications.sh [TOKEN]

API_URL="http://localhost:3000"
TOKEN="${1:-YOUR_TOKEN_HERE}"

echo "🧪 Test du système de notifications MCT Maintenance"
echo "=================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Nouvelle intervention
echo -e "${BLUE}📋 Test 1: Création d'une intervention${NC}"
echo "POST $API_URL/api/interventions"
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/interventions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification - Climatiseur en panne",
    "description": "Test du système de notifications en temps réel",
    "customer_id": 1,
    "scheduled_date": "2025-01-26T10:00:00Z",
    "priority": "high"
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✅ Intervention créée avec succès${NC}"
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${YELLOW}⚠️  Erreur lors de la création${NC}"
  echo "$RESPONSE"
fi

echo ""
echo "=================================================="
echo ""

# Test 2: Nouvelle réclamation
echo -e "${BLUE}📋 Test 2: Création d'une réclamation${NC}"
echo "POST $API_URL/api/complaints"
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/complaints" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "subject": "Test Notification - Produit défectueux",
    "description": "Test du système de notifications pour les réclamations",
    "priority": "high",
    "category": "product_quality"
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✅ Réclamation créée avec succès${NC}"
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${YELLOW}⚠️  Erreur lors de la création${NC}"
  echo "$RESPONSE"
fi

echo ""
echo "=================================================="
echo ""

# Test 3: Nouvelle commande
echo -e "${BLUE}📋 Test 3: Création d'une commande${NC}"
echo "POST $API_URL/api/orders"
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "product_id": 1,
        "quantity": 1
      }
    ],
    "shipping_address": "123 Test Street, Abidjan",
    "payment_method": "card",
    "notes": "Test notification commande"
  }')

if echo "$RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✅ Commande créée avec succès${NC}"
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${YELLOW}⚠️  Erreur lors de la création${NC}"
  echo "$RESPONSE"
fi

echo ""
echo "=================================================="
echo ""
echo -e "${GREEN}🎉 Tests terminés !${NC}"
echo ""
echo "📊 Vérifiez maintenant le dashboard web:"
echo "   1. Ouvrez http://localhost:3001"
echo "   2. Regardez l'icône de cloche 🔔 dans le header"
echo "   3. Le badge devrait afficher le nombre de notifications"
echo "   4. Cliquez sur la cloche pour voir les notifications"
echo ""
