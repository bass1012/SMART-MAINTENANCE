#!/bin/bash

# Script de test Analytics & Reporting
# Date: 19 décembre 2025

BASE_URL="http://localhost:3000"
ADMIN_EMAIL="admin@mct-maintenance.com"
ADMIN_PASSWORD="P@ssword"

echo "🧪 Test Analytics & Reporting - MCT Maintenance"
echo "================================================"
echo ""

# 1. Connexion admin et récupération du token
echo "1️⃣  Connexion admin..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Échec de connexion"
  echo "Réponse: $LOGIN_RESPONSE"
  echo ""
  echo "💡 Vérifiez les identifiants admin dans la base de données:"
  echo "   Email: $ADMIN_EMAIL"
  echo "   Mot de passe: $ADMIN_PASSWORD"
  exit 1
fi

echo "✅ Connecté avec succès"
echo "🔑 Token: ${TOKEN:0:20}..."
echo ""

# 2. Test statistiques globales
echo "2️⃣  Test: Statistiques globales"
STATS=$(curl -s -X GET "$BASE_URL/admin/analytics/stats" \
  -H "Authorization: Bearer $TOKEN")

if echo $STATS | grep -q "success"; then
  echo "✅ Statistiques récupérées"
  echo "$STATS" | jq -r '.data | "   Interventions: \(.interventions.total), Commandes: \(.orders.total), Revenue: \(.orders.revenue) FCFA"' 2>/dev/null || echo "   $STATS"
else
  echo "❌ Erreur: $STATS"
fi
echo ""

# 3. Test performance techniciens
echo "3️⃣  Test: Performance techniciens"
TECH_PERF=$(curl -s -X GET "$BASE_URL/admin/analytics/technicians" \
  -H "Authorization: Bearer $TOKEN")

if echo $TECH_PERF | grep -q "success"; then
  echo "✅ Performance techniciens récupérée"
  TECH_COUNT=$(echo $TECH_PERF | jq -r '.data | length' 2>/dev/null || echo "N/A")
  echo "   Nombre de techniciens: $TECH_COUNT"
else
  echo "❌ Erreur: $TECH_PERF"
fi
echo ""

# 4. Test graphique timeline interventions
echo "4️⃣  Test: Graphique timeline interventions"
CHART=$(curl -s -X GET "$BASE_URL/admin/analytics/charts/interventions-timeline?period=3" \
  -H "Authorization: Bearer $TOKEN")

if echo $CHART | grep -q "success"; then
  echo "✅ Données graphique récupérées"
  DATA_COUNT=$(echo $CHART | jq -r '.data | length' 2>/dev/null || echo "N/A")
  echo "   Points de données: $DATA_COUNT"
else
  echo "❌ Erreur: $CHART"
fi
echo ""

# 5. Test graphiques additionnels
echo "5️⃣  Test: Autres graphiques..."
for CHART_TYPE in "revenue-timeline" "interventions-by-type" "customer-satisfaction" "top-products"; do
  RESULT=$(curl -s -X GET "$BASE_URL/admin/analytics/charts/$CHART_TYPE" \
    -H "Authorization: Bearer $TOKEN")
  
  if echo $RESULT | grep -q "success"; then
    echo "   ✅ $CHART_TYPE"
  else
    echo "   ❌ $CHART_TYPE"
  fi
done
echo ""

echo "================================================"
echo "✅ Tests terminés!"
echo ""
echo "📥 Pour tester les exports:"
echo ""
echo "Excel:"
echo "curl -X GET \"$BASE_URL/admin/analytics/export/excel?type=interventions\" \\"
echo "  -H \"Authorization: Bearer $TOKEN\" \\"
echo "  --output rapport.xlsx"
echo ""
echo "PDF:"
echo "curl -X GET \"$BASE_URL/admin/analytics/export/pdf\" \\"
echo "  -H \"Authorization: Bearer $TOKEN\" \\"
echo "  --output rapport.pdf"
echo ""
# Test 5: Top produits
echo "5️⃣  Test: Top 10 produits"
echo "GET /admin/analytics/charts/top-products"
curl -s -X GET "${BASE_URL}/admin/analytics/charts/top-products" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.'
echo ""
echo "---"
echo ""

# Test 6: Export Excel (téléchargement)
echo "6️⃣  Test: Export Excel"
echo "GET /admin/analytics/export/excel"
echo "📥 Téléchargement: rapport_test.xlsx"
curl -s -X GET "${BASE_URL}/admin/analytics/export/excel?type=interventions" \
  -H "Authorization: Bearer ${TOKEN}" \
  --output rapport_test.xlsx

if [ -f "rapport_test.xlsx" ]; then
  SIZE=$(ls -lh rapport_test.xlsx | awk '{print $5}')
  echo "✅ Fichier Excel créé: rapport_test.xlsx (${SIZE})"
else
  echo "❌ Échec création fichier Excel"
fi
echo ""
echo "---"
echo ""

# Test 7: Export PDF (téléchargement)
echo "7️⃣  Test: Export PDF"
echo "GET /admin/analytics/export/pdf"
echo "📥 Téléchargement: rapport_test.pdf"
curl -s -X GET "${BASE_URL}/admin/analytics/export/pdf" \
  -H "Authorization: Bearer ${TOKEN}" \
  --output rapport_test.pdf

if [ -f "rapport_test.pdf" ]; then
  SIZE=$(ls -lh rapport_test.pdf | awk '{print $5}')
  echo "✅ Fichier PDF créé: rapport_test.pdf (${SIZE})"
else
  echo "❌ Échec création fichier PDF"
fi
echo ""
echo "---"
echo ""

echo "✅ Tests terminés!"
echo ""
echo "📁 Fichiers générés:"
echo "  - rapport_test.xlsx"
echo "  - rapport_test.pdf"
echo ""
echo "Pour ouvrir les fichiers:"
echo "  open rapport_test.xlsx"
echo "  open rapport_test.pdf"
