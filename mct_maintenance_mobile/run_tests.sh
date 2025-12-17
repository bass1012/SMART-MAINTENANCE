#!/bin/bash

# 🧪 Script d'Exécution des Tests E2E avec Patrol
# MCT Maintenance Mobile

set -e  # Arrêter en cas d'erreur

# Ajouter patrol au PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║       🧪  Tests E2E Patrol - MCT Maintenance Mobile         ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérifier que Patrol CLI est installé
if ! command -v patrol &> /dev/null; then
    echo -e "${RED}❌ Patrol CLI n'est pas installé${NC}"
    echo -e "${YELLOW}Installation...${NC}"
    dart pub global activate patrol_cli
    echo -e "${GREEN}✅ Patrol CLI installé${NC}"
fi

# Menu
echo ""
echo -e "${BLUE}Que voulez-vous faire ?${NC}"
echo ""
echo "  1) 🚀 Exécuter TOUS les tests (6 tests)"
echo "  2) 🔐 Test Connexion Client"
echo "  3) 🔧 Test Création Intervention"
echo "  4) 🛒 Test Achat Boutique"
echo "  5) 👨‍🔧 Test Workflow Technicien"
echo "  6) 📱 Test Permissions Natives"
echo "  7) 🔔 Test Notifications"
echo "  8) 📊 Rapport de Couverture"
echo "  9) 🎥 Exécuter avec Vidéo"
echo "  10) 🐛 Mode Debug (Verbose)"
echo ""
read -p "Choix (1-10): " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Exécution de TOUS les tests...${NC}"
        patrol test --target integration_test/app_test.dart
        ;;
    2)
        echo -e "${GREEN}🔐 Exécution Test Connexion Client...${NC}"
        patrol test --target integration_test/app_test.dart --name "Connexion Client"
        ;;
    3)
        echo -e "${GREEN}🔧 Exécution Test Création Intervention...${NC}"
        patrol test --target integration_test/app_test.dart --name "Création Intervention"
        ;;
    4)
        echo -e "${GREEN}🛒 Exécution Test Achat Boutique...${NC}"
        patrol test --target integration_test/app_test.dart --name "Achat Boutique"
        ;;
    5)
        echo -e "${GREEN}👨‍🔧 Exécution Test Workflow Technicien...${NC}"
        patrol test --target integration_test/app_test.dart --name "Workflow Technicien"
        ;;
    6)
        echo -e "${GREEN}📱 Exécution Test Permissions Natives...${NC}"
        patrol test --target integration_test/app_test.dart --name "Permissions Natives"
        ;;
    7)
        echo -e "${GREEN}🔔 Exécution Test Notifications...${NC}"
        patrol test --target integration_test/app_test.dart --name "Notifications"
        ;;
    8)
        echo -e "${GREEN}📊 Génération du rapport de couverture...${NC}"
        flutter test --coverage
        genhtml coverage/lcov.info -o coverage/html
        open coverage/html/index.html
        ;;
    9)
        echo -e "${GREEN}🎥 Exécution avec enregistrement vidéo...${NC}"
        patrol test --target integration_test/app_test.dart --record-video
        echo -e "${GREEN}✅ Vidéos disponibles dans ./build/patrol/video/${NC}"
        ;;
    10)
        echo -e "${GREEN}🐛 Exécution en mode debug...${NC}"
        patrol test --target integration_test/app_test.dart --verbose
        ;;
    *)
        echo -e "${RED}❌ Choix invalide${NC}"
        exit 1
        ;;
esac

# Résumé
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Tests terminés !${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "📁 Logs disponibles dans: ./build/patrol/"
echo "📸 Screenshots disponibles dans: ./screenshots/ (si échec)"
echo ""
