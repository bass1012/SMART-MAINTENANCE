#!/bin/bash
# ================================================================
# Script de déploiement - MCT Maintenance
# Usage: ./deploy.sh [api|dashboard|all]
# ================================================================

set -e

# Configuration - À MODIFIER
SERVER_IP="sandbox.mct.ci"
SERVER_USER="root"
APP_DIR="/var/www/smartmaintenance"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifier les paramètres
DEPLOY_TARGET=${1:-all}

echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════════"
echo "    DÉPLOIEMENT MCT MAINTENANCE → $SERVER_IP"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Fonction de déploiement de l'API
deploy_api() {
    echo -e "\n${YELLOW}[API] Préparation du déploiement...${NC}"
    
    # Créer le dossier temporaire
    rm -rf /tmp/mct-api-deploy
    mkdir -p /tmp/mct-api-deploy
    
    # Copier les fichiers nécessaires (sans node_modules, sans .env)
    echo "   📦 Copie des fichiers..."
    rsync -av --exclude='node_modules' --exclude='.env' --exclude='*.sqlite' --exclude='uploads/*' \
        mct-maintenance-api/ /tmp/mct-api-deploy/
    
    # Envoyer vers le serveur
    echo -e "   ${YELLOW}📤 Envoi vers le serveur...${NC}"
    ssh $SERVER_USER@$SERVER_IP "mkdir -p $APP_DIR/mct-maintenance-api/uploads"
    rsync -avz --delete /tmp/mct-api-deploy/ $SERVER_USER@$SERVER_IP:$APP_DIR/mct-maintenance-api/
    
    # Installer les dépendances et redémarrer
    echo -e "   ${YELLOW}🔧 Installation des dépendances...${NC}"
    ssh $SERVER_USER@$SERVER_IP "cd $APP_DIR/mct-maintenance-api && npm install --production"
    
    echo -e "   ${YELLOW}🔄 Redémarrage de l'API...${NC}"
    ssh $SERVER_USER@$SERVER_IP "cd $APP_DIR/mct-maintenance-api && pm2 restart smartmaintenance-api || pm2 start ecosystem.config.js"
    
    echo -e "   ${GREEN}✅ API déployée!${NC}"
}

# Fonction de déploiement du Dashboard
deploy_dashboard() {
    echo -e "\n${YELLOW}[Dashboard] Build de production...${NC}"
    
    cd mct-maintenance-dashboard
    
    # Build React
    echo "   📦 Build en cours..."
    npm run build
    
    # Envoyer vers le serveur
    echo -e "   ${YELLOW}📤 Envoi vers le serveur...${NC}"
    ssh $SERVER_USER@$SERVER_IP "mkdir -p $APP_DIR/dashboard"
    rsync -avz --delete build/ $SERVER_USER@$SERVER_IP:$APP_DIR/dashboard/
    
    cd ..
    
    echo -e "   ${GREEN}✅ Dashboard déployé!${NC}"
}

# Exécution
case $DEPLOY_TARGET in
    api)
        deploy_api
        ;;
    dashboard)
        deploy_dashboard
        ;;
    all)
        deploy_api
        deploy_dashboard
        ;;
    *)
        echo "Usage: ./deploy.sh [api|dashboard|all]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "    DÉPLOIEMENT TERMINÉ !"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""
echo "API:       https://api.sandbox.mct.ci"
echo "Dashboard: https://dashboard.sandbox.mct.ci"
echo "API:       https://api.votredomaine.com"
echo "Dashboard: https://dashboard.votredomaine.com"
echo ""
