#!/bin/bash

# Script de test rapide pour vérifier les notifications de réclamation
# Usage: ./test_complaint_notifications.sh

echo "🧪 Test des notifications de réclamation"
echo "========================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Vérifier que l'API est en cours d'exécution
echo "1️⃣  Vérification de l'API..."
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${GREEN}✅ API en cours d'exécution sur le port 3000${NC}"
else
    echo -e "${RED}❌ API non démarrée. Démarrez l'API avec:${NC}"
    echo "   cd mct-maintenance-api && npm start"
    exit 1
fi

echo ""

# 2. Vérifier les fichiers modifiés
echo "2️⃣  Vérification des modifications..."
if grep -q "hasSignificantChanges" mct-maintenance-api/src/controllers/complaintController.js; then
    echo -e "${GREEN}✅ Fichier complaintController.js modifié correctement${NC}"
else
    echo -e "${RED}❌ Modifications manquantes dans complaintController.js${NC}"
    exit 1
fi

if grep -q "Mise à jour de votre réclamation" mct-maintenance-api/src/services/notificationHelpers.js; then
    echo -e "${GREEN}✅ Fichier notificationHelpers.js modifié correctement${NC}"
else
    echo -e "${RED}❌ Modifications manquantes dans notificationHelpers.js${NC}"
    exit 1
fi

echo ""

# 3. Exécuter le script de test
echo "3️⃣  Exécution du test de notification..."
node test-complaint-update-notification.js

echo ""
echo "========================================"
echo -e "${GREEN}✅ Tests terminés${NC}"
echo ""
echo "📱 Prochaines étapes:"
echo "   1. Ouvrez le dashboard web"
echo "   2. Modifiez une réclamation (résolution ou description)"
echo "   3. Vérifiez sur le mobile du client qu'il reçoit la notification"
echo ""
echo "🔍 Pour surveiller les logs en temps réel:"
echo "   cd mct-maintenance-api && tail -f logs/api.log"
