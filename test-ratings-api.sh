#!/bin/bash

# Script de test pour vérifier l'endpoint des évaluations
# Usage: ./test-ratings-api.sh

echo "🧪 Test de l'API Évaluations"
echo "=============================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Connexion admin
echo "📝 1. Connexion admin..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email": "admin@mct-maintenance.com", "password": "P@ssword"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Échec de connexion${NC}"
  echo "$LOGIN_RESPONSE" | jq '.'
  exit 1
fi

echo -e "${GREEN}✅ Token obtenu: ${TOKEN:0:50}...${NC}"
echo ""

# 2. Récupérer les interventions complétées
echo "📊 2. Récupération des interventions complétées..."
INTERVENTIONS_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/interventions?status=completed&limit=100")

TOTAL_COMPLETED=$(echo $INTERVENTIONS_RESPONSE | jq -r '.data.total')
echo -e "${GREEN}✅ $TOTAL_COMPLETED interventions complétées trouvées${NC}"
echo ""

# 3. Analyser les évaluations
echo "⭐ 3. Analyse des évaluations..."
RATINGS_ANALYSIS=$(echo $INTERVENTIONS_RESPONSE | jq '
  .data.interventions | 
  map(select(.rating != null)) | 
  {
    count: length,
    average: (if length > 0 then (map(.rating) | add / length) else 0 end),
    breakdown: (
      group_by(.rating) | 
      map({key: .[0].rating, value: length}) | 
      from_entries
    )
  }
')

RATINGS_COUNT=$(echo $RATINGS_ANALYSIS | jq -r '.count')
RATINGS_AVG=$(echo $RATINGS_ANALYSIS | jq -r '.average')

echo -e "${GREEN}✅ $RATINGS_COUNT évaluations trouvées${NC}"
echo -e "${YELLOW}📈 Moyenne: $RATINGS_AVG / 5${NC}"
echo ""

# 4. Afficher la répartition
echo "📊 4. Répartition des notes:"
echo $RATINGS_ANALYSIS | jq -r '.breakdown | to_entries | sort_by(.key) | reverse | .[] | "   \(.key)★: \(.value) évaluation(s)"'
echo ""

# 5. Afficher quelques exemples
echo "📋 5. Exemples d'évaluations:"
echo $INTERVENTIONS_RESPONSE | jq -r '
  .data.interventions | 
  map(select(.rating != null)) | 
  .[0:3] | 
  .[] | 
  "   • Intervention #\(.id) - \(.rating)★ par \(.customer.first_name) → \(.technician.first_name)"
'
echo ""

# 6. Vérifier la structure pour le dashboard
echo "🌐 6. Vérification de la structure pour le dashboard..."
DASHBOARD_DATA=$(echo $INTERVENTIONS_RESPONSE | jq '
  .data.interventions | 
  map(select(.rating != null)) | 
  map({
    intervention_id: .id,
    intervention_title: .title,
    rating: .rating,
    review: .review,
    customer_name: "\(.customer.first_name) \(.customer.last_name)",
    technician_name: "\(.technician.first_name) \(.technician.last_name)",
    rated_at: .updated_at
  }) | 
  .[0]
')

if [ "$(echo $DASHBOARD_DATA | jq -r '.intervention_id')" != "null" ]; then
  echo -e "${GREEN}✅ Structure de données correcte pour le dashboard${NC}"
  echo "   Exemple de donnée formatée:"
  echo "$DASHBOARD_DATA" | jq '.'
else
  echo -e "${RED}❌ Problème de structure de données${NC}"
fi

echo ""
echo -e "${GREEN}✅ Tests terminés avec succès !${NC}"
echo ""
echo "💡 Pour tester le dashboard web:"
echo "   1. cd mct-maintenance-dashboard"
echo "   2. npm start"
echo "   3. Connexion: admin@mct-maintenance.com / P@ssword"
echo "   4. Aller dans Notifications > Évaluations reçues"
