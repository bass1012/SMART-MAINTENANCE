#!/bin/bash

# ===========================================
# Script de Déploiement - MCT Maintenance Mobile
# ===========================================

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Aller dans le dossier mobile
cd "$(dirname "$0")/mct_maintenance_mobile"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║  🚀 MCT Maintenance - Build & Deploy      ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Afficher la version actuelle
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo -e "${YELLOW}Version actuelle: $CURRENT_VERSION${NC}"

# Menu
echo ""
echo "Que voulez-vous faire ?"
echo "1) Build Android (AAB pour Play Store)"
echo "2) Build iOS (Archive pour App Store)"
echo "3) Build les deux"
echo "4) Incrémenter la version"
echo "5) Build APK debug"
echo "6) Annuler"
echo ""
read -p "Choix [1-6]: " choice

increment_version() {
    CURRENT=$(grep 'version:' pubspec.yaml | sed 's/version: //')
    BUILD=$(echo $CURRENT | cut -d'+' -f2)
    NEW_BUILD=$((BUILD + 1))
    VERSION=$(echo $CURRENT | cut -d'+' -f1)
    NEW_VERSION="$VERSION+$NEW_BUILD"
    
    # macOS compatible sed
    sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
    echo -e "${GREEN}✅ Version mise à jour: $NEW_VERSION${NC}"
}

build_android() {
    echo -e "${BLUE}📱 Build Android (AAB)...${NC}"
    
    # Vérifier le keystore
    if [ ! -f "android/key.properties" ]; then
        echo -e "${RED}❌ Fichier android/key.properties manquant !${NC}"
        echo "Créez ce fichier avec vos paramètres de signature."
        return 1
    fi
    
    flutter clean
    flutter pub get
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Android Build Success !${NC}"
        echo -e "${YELLOW}📁 Fichier: build/app/outputs/bundle/release/app-release.aab${NC}"
        
        # Copier dans un dossier releases
        mkdir -p ../releases/android
        cp build/app/outputs/bundle/release/app-release.aab "../releases/android/mct-maintenance-$(grep 'version:' pubspec.yaml | sed 's/version: //').aab"
        echo -e "${GREEN}📦 Copié dans releases/android/${NC}"
    else
        echo -e "${RED}❌ Android Build Failed${NC}"
        return 1
    fi
}

build_ios() {
    echo -e "${BLUE}🍎 Build iOS...${NC}"
    
    flutter clean
    flutter pub get
    
    cd ios
    pod install --repo-update
    cd ..
    
    flutter build ios --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ iOS Build Success !${NC}"
        echo -e "${YELLOW}📂 Ouvrez Xcode pour archiver:${NC}"
        echo "   cd mct_maintenance_mobile/ios && open Runner.xcworkspace"
        echo ""
        echo "Dans Xcode: Product → Archive → Distribute App → App Store Connect"
    else
        echo -e "${RED}❌ iOS Build Failed${NC}"
        return 1
    fi
}

build_apk_debug() {
    echo -e "${BLUE}📱 Build APK Debug...${NC}"
    flutter build apk --debug
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ APK Debug créé !${NC}"
        echo -e "${YELLOW}📁 build/app/outputs/flutter-apk/app-debug.apk${NC}"
    fi
}

case $choice in
    1)
        build_android
        ;;
    2)
        build_ios
        ;;
    3)
        build_android
        echo ""
        build_ios
        ;;
    4)
        increment_version
        ;;
    5)
        build_apk_debug
        ;;
    6)
        echo "Annulé."
        exit 0
        ;;
    *)
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Terminé !${NC}"
