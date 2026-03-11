#!/bin/bash
# ================================================================
# Script d'installation du serveur - Smart Maintenance
# Pour VPS OVH Ubuntu 22.04 LTS
# ================================================================

set -e

echo "═══════════════════════════════════════════════════════════"
echo "    INSTALLATION SERVEUR SMART MAINTENANCE"
echo "═══════════════════════════════════════════════════════════"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables à configurer
DOMAIN_API="api.sandbox.mct.ci"
DOMAIN_DASHBOARD="dashboard.sandbox.mct.ci"
APP_USER="smartmaintenance"
APP_DIR="/var/www/smartmaintenance"

echo -e "\n${YELLOW}[1/8] Mise à jour du système...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "\n${YELLOW}[2/8] Installation des dépendances...${NC}"
sudo apt install -y curl git nginx certbot python3-certbot-nginx ufw

echo -e "\n${YELLOW}[3/8] Installation de Node.js 20 LTS...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
echo "   Node.js: $(node --version)"
echo "   npm: $(npm --version)"

echo -e "\n${YELLOW}[4/8] Installation de PM2...${NC}"
sudo npm install -g pm2
pm2 --version

echo -e "\n${YELLOW}[5/8] Création de l'utilisateur et du dossier...${NC}"
# Créer l'utilisateur si nécessaire
if ! id "$APP_USER" &>/dev/null; then
    sudo adduser --system --group --home /home/$APP_USER $APP_USER
fi

# Créer le dossier de l'application
sudo mkdir -p $APP_DIR
sudo chown -R $APP_USER:$APP_USER $APP_DIR

echo -e "\n${YELLOW}[6/8] Configuration du pare-feu...${NC}"
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw --force enable
sudo ufw status

echo -e "\n${YELLOW}[7/8] Configuration PM2 au démarrage...${NC}"
pm2 startup systemd -u root --hp /root
sudo systemctl enable pm2-root

echo -e "\n${GREEN}[8/8] Installation terminée !${NC}"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    PROCHAINES ÉTAPES"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Copiez vos fichiers vers le serveur:"
echo "   scp -r mct-maintenance-api/ root@IP_SERVEUR:$APP_DIR/"
echo "   scp -r mct-maintenance-dashboard/build/ root@IP_SERVEUR:$APP_DIR/dashboard/"
echo ""
echo "2. Sur le serveur, configurez l'environnement:"
echo "   cd $APP_DIR/mct-maintenance-api"
echo "   cp .env.example .env && nano .env"
echo "   npm install --production"
echo ""
echo "3. Démarrez l'API avec PM2:"
echo "   pm2 start ecosystem.config.js"
echo "   pm2 save"
echo ""
echo "4. Configurez Nginx (voir nginx-mct.conf)"
echo ""
echo "5. Installez les certificats SSL:"
echo "   sudo certbot --nginx -d $DOMAIN_API -d $DOMAIN_DASHBOARD"
echo ""
echo "═══════════════════════════════════════════════════════════"
