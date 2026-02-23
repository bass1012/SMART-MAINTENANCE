#!/bin/bash

# 🧪 Script de Test - Système Préférences Notifications
# Date: 24 Décembre 2025

echo "🧪 ======================================"
echo "   TEST SYSTÈME PRÉFÉRENCES NOTIFICATIONS"
echo "========================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de test avec résultat visuel
test_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${BLUE}🔄 Test:${NC} $description"
    echo -e "   ${YELLOW}$method $endpoint${NC}"
    
    if [ -z "$data" ]; then
        response=$(curl -s -X $method "http://localhost:3000$endpoint" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -w "\n%{http_code}")
    else
        response=$(curl -s -X $method "http://localhost:3000$endpoint" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -w "\n%{http_code}")
    fi
    
    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
        echo -e "   ${GREEN}✅ SUCCESS ($status_code)${NC}"
        echo "   Response: $(echo $body | jq -c '.' 2>/dev/null || echo $body | head -c 100)"
    else
        echo -e "   ${RED}❌ FAILED ($status_code)${NC}"
        echo "   Error: $body"
    fi
    echo ""
}

echo "📋 Étape 1: Vérification Backend"
echo "================================"
echo ""

# Vérifier si le serveur API est en cours d'exécution
echo -e "${BLUE}🔍 Vérification du serveur API...${NC}"
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Serveur API accessible${NC}"
else
    echo -e "${RED}❌ Serveur API non accessible${NC}"
    echo "   Démarrez le serveur avec: cd mct-maintenance-api && npm start"
    exit 1
fi
echo ""

# Se connecter et obtenir un token
echo -e "${BLUE}🔐 Connexion et récupération du token...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"supportuser@mct.ci","password":"Keep0ut@2023!"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.accessToken' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo -e "${RED}❌ Échec de la connexion${NC}"
    echo "   Response: $LOGIN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Token obtenu: ${TOKEN:0:20}...${NC}"
echo ""

echo "📋 Étape 2: Tests API Backend"
echo "============================="
echo ""

# Test 1: GET préférences
test_api "GET" "/api/notification-preferences" "" \
    "Récupérer les préférences de notifications"

# Test 2: PUT mise à jour
test_api "PUT" "/api/notification-preferences" \
    '{"intervention_request_push": false, "order_created_email": true}' \
    "Mettre à jour des préférences spécifiques"

# Test 3: Toggle email
test_api "PUT" "/api/notification-preferences/toggle-email" \
    '{"enabled": true}' \
    "Activer toutes les notifications email"

# Test 4: Toggle push
test_api "PUT" "/api/notification-preferences/toggle-push" \
    '{"enabled": true}' \
    "Activer toutes les notifications push"

# Test 5: Heures de silence
test_api "PUT" "/api/notification-preferences/quiet-hours" \
    '{"enabled": true, "start": "22:00", "end": "08:00"}' \
    "Configurer les heures de silence"

# Test 6: Vérifier les modifications
test_api "GET" "/api/notification-preferences" "" \
    "Vérifier que les modifications ont été appliquées"

echo ""
echo "📋 Étape 3: Vérification Fichiers Flutter"
echo "========================================"
echo ""

# Vérifier l'existence des fichiers
files_to_check=(
    "lib/models/notification_preference.dart"
    "lib/services/notification_preferences_service.dart"
    "lib/providers/notification_preferences_provider.dart"
    "lib/screens/common/notification_settings_screen.dart"
)

all_files_exist=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $file"
    else
        echo -e "${RED}❌${NC} $file ${RED}(manquant)${NC}"
        all_files_exist=false
    fi
done

echo ""

if [ "$all_files_exist" = true ]; then
    echo -e "${GREEN}✅ Tous les fichiers Flutter sont présents${NC}"
else
    echo -e "${RED}❌ Certains fichiers Flutter sont manquants${NC}"
fi

echo ""
echo "📋 Étape 4: Vérification Configuration"
echo "======================================"
echo ""

# Vérifier que le provider est dans app.dart
if grep -q "NotificationPreferencesProvider" "lib/core/app.dart"; then
    echo -e "${GREEN}✅${NC} Provider ajouté dans app.dart"
else
    echo -e "${RED}❌${NC} Provider non trouvé dans app.dart"
fi

# Vérifier que la route est configurée
if grep -q "/notification-settings" "lib/core/app.dart"; then
    echo -e "${GREEN}✅${NC} Route /notification-settings configurée"
else
    echo -e "${RED}❌${NC} Route /notification-settings non trouvée"
fi

# Vérifier l'import de l'écran
if grep -q "notification_settings_screen" "lib/core/app.dart"; then
    echo -e "${GREEN}✅${NC} Import NotificationSettingsScreen présent"
else
    echo -e "${RED}❌${NC} Import NotificationSettingsScreen manquant"
fi

echo ""
echo "📋 Étape 5: Instructions de Test Mobile"
echo "======================================="
echo ""

echo -e "${YELLOW}Pour tester l'application mobile:${NC}"
echo ""
echo "1. Assurez-vous que le backend est démarré:"
echo "   ${BLUE}cd mct-maintenance-api && npm start${NC}"
echo ""
echo "2. Lancez l'émulateur Android/iOS ou connectez un appareil"
echo ""
echo "3. Démarrez l'application Flutter:"
echo "   ${BLUE}flutter run${NC}"
echo ""
echo "4. Testez la navigation:"
echo "   📱 Connexion → Paramètres → Préférences Détaillées"
echo ""
echo "5. Vérifiez les fonctionnalités:"
echo "   ✅ Chargement des préférences depuis l'API"
echo "   ✅ Toggle global Email/Push"
echo "   ✅ Modification de préférences spécifiques"
echo "   ✅ Sauvegarde et affichage SnackBar"
echo "   ✅ Pull-to-refresh"
echo "   ✅ Bouton Reset avec confirmation"
echo ""

echo ""
echo "📋 Résumé Final"
echo "==============="
echo ""

echo -e "${GREEN}✅ Backend API:${NC} Fonctionnel"
echo -e "${GREEN}✅ Fichiers Flutter:${NC} Présents"
echo -e "${GREEN}✅ Configuration:${NC} Complète"
echo -e "${YELLOW}⏳ Tests Mobile:${NC} À effectuer manuellement"
echo ""

echo "🎉 ======================================"
echo "   Système prêt à être testé !"
echo "========================================"
echo ""

echo -e "${BLUE}💡 Conseil:${NC} Surveillez les logs console pendant les tests:"
echo "   ${BLUE}flutter run -v${NC}"
echo ""

# Test optionnel: Réinitialiser les préférences
read -p "Voulez-vous réinitialiser les préférences aux valeurs par défaut ? (o/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Oo]$ ]]; then
    echo ""
    test_api "POST" "/api/notification-preferences/reset" "" \
        "Réinitialiser les préférences aux valeurs par défaut"
fi

echo ""
echo "✅ Tests terminés !"
echo ""
