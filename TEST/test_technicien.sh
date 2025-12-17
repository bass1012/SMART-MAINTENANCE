#!/bin/bash

echo "🔍 TEST DU SYSTÈME TECHNICIEN"
echo "================================"
echo ""

# Configuration
API_URL="http://localhost:3000"
TECH_EMAIL="cissoko@gmail.com"
TECH_PASSWORD="P@ssword"  # Remplacer par le vrai mot de passe

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
echo "📝 Étape 1 : Login technicien"
echo "------------------------------"
echo "Email: $TECH_EMAIL"

LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TECH_EMAIL\",\"password\":\"$TECH_PASSWORD\"}")

echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

# Extraire le token (peut être dans .token ou .data.accessToken)
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.accessToken // .token' 2>/dev/null)

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Échec de connexion ou token non trouvé${NC}"
  echo "Réponse: $LOGIN_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ Connecté avec succès${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

echo "📊 Étape 2 : Récupérer les statistiques"
echo "---------------------------------------"
STATS_RESPONSE=$(curl -s -X GET "$API_URL/api/technician/dashboard/stats" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$STATS_RESPONSE" | jq '.' 2>/dev/null || echo "$STATS_RESPONSE"

TOTAL_INTERVENTIONS=$(echo "$STATS_RESPONSE" | jq -r '.data.total_interventions' 2>/dev/null)

if [ "$TOTAL_INTERVENTIONS" == "null" ] || [ "$TOTAL_INTERVENTIONS" == "0" ]; then
  echo -e "${YELLOW}⚠️  Aucune intervention assignée${NC}"
else
  echo -e "${GREEN}✅ $TOTAL_INTERVENTIONS intervention(s) assignée(s)${NC}"
fi
echo ""

echo "📋 Étape 3 : Récupérer les interventions"
echo "----------------------------------------"
INTERVENTIONS_RESPONSE=$(curl -s -X GET "$API_URL/api/technician/interventions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$INTERVENTIONS_RESPONSE" | jq '.' 2>/dev/null || echo "$INTERVENTIONS_RESPONSE"

INTERVENTIONS_COUNT=$(echo "$INTERVENTIONS_RESPONSE" | jq '.data | length' 2>/dev/null)

if [ "$INTERVENTIONS_COUNT" == "0" ] || [ -z "$INTERVENTIONS_COUNT" ]; then
  echo -e "${RED}❌ Aucune intervention retournée${NC}"
  echo ""
  echo "🔍 DIAGNOSTIC :"
  echo "1. Vérifiez en DB si des interventions sont assignées au technicien"
  echo "   SELECT * FROM interventions WHERE technician_id = (SELECT id FROM users WHERE email = '$TECH_EMAIL');"
  echo ""
  echo "2. Vérifiez les logs du serveur backend"
  echo "   Cherchez : '📋 Récupération interventions pour technicien'"
else
  echo -e "${GREEN}✅ $INTERVENTIONS_COUNT intervention(s) récupérée(s)${NC}"
  echo ""
  echo "Interventions :"
  echo "$INTERVENTIONS_RESPONSE" | jq -r '.data[] | "  - [\(.id)] \(.title) - \(.status) - \(.customer_name)"' 2>/dev/null
fi
echo ""

echo "🔔 Étape 4 : Vérifier les notifications"
echo "---------------------------------------"
echo "Pour vérifier les notifications, exécutez en SQL :"
echo ""
echo "SELECT id, type, title, message, is_read, created_at"
echo "FROM notifications"
echo "WHERE user_id = (SELECT id FROM users WHERE email = '$TECH_EMAIL')"
echo "ORDER BY created_at DESC"
echo "LIMIT 5;"
echo ""

echo "================================"
echo "✅ Test terminé"
echo ""
echo "📝 RÉSUMÉ :"
echo "- Token JWT : ${TOKEN:0:30}..."
echo "- Total interventions : $TOTAL_INTERVENTIONS"
echo "- Interventions récupérées : $INTERVENTIONS_COUNT"
echo ""

if [ "$INTERVENTIONS_COUNT" -gt "0" ]; then
  echo -e "${GREEN}🎉 LE SYSTÈME FONCTIONNE !${NC}"
  echo ""
  echo "L'app mobile devrait maintenant afficher :"
  echo "- Les statistiques sur le dashboard"
  echo "- La liste des interventions assignées"
  echo "- Les boutons 'Accepter' et 'Terminer' fonctionnels"
else
  echo -e "${RED}⚠️  PROBLÈME DÉTECTÉ${NC}"
  echo ""
  echo "Prochaines étapes :"
  echo "1. Assignez une intervention au technicien depuis le dashboard web"
  echo "2. Relancez ce test"
  echo "3. Si toujours vide, vérifiez les logs du serveur backend"
fi
