#!/bin/bash

# Script pour mettre à jour automatiquement l'adresse IP dans l'app Flutter
# Utilisation: ./update_ip.sh

echo "🔍 MISE À JOUR DE L'ADRESSE IP"
echo "=============================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Chemin du fichier de configuration
CONFIG_FILE="/Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/lib/config/environment.dart"

# Détecter l'adresse IP actuelle
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

if [ -z "$CURRENT_IP" ]; then
  echo -e "${RED}❌ Impossible de détecter l'adresse IP${NC}"
  exit 1
fi

echo -e "📍 Adresse IP détectée : ${GREEN}$CURRENT_IP${NC}"
echo ""

# Lire l'ancienne IP du fichier
OLD_IP=$(grep "Environment.development:" "$CONFIG_FILE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$OLD_IP" ]; then
  echo -e "${RED}❌ Impossible de lire l'ancienne IP du fichier${NC}"
  exit 1
fi

echo "🔄 Ancienne IP : $OLD_IP"
echo ""

# Vérifier si l'IP a changé
if [ "$OLD_IP" == "$CURRENT_IP" ]; then
  echo -e "${GREEN}✅ L'adresse IP est déjà à jour !${NC}"
  exit 0
fi

# Demander confirmation
echo -e "${YELLOW}⚠️  L'adresse IP a changé !${NC}"
echo ""
read -p "Voulez-vous mettre à jour le fichier de configuration ? (o/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
  echo "❌ Mise à jour annulée"
  exit 0
fi

# Créer une sauvegarde
cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
echo "💾 Sauvegarde créée : ${CONFIG_FILE}.backup"

# Mettre à jour le fichier
sed -i '' "s/$OLD_IP/$CURRENT_IP/g" "$CONFIG_FILE"

echo -e "${GREEN}✅ Fichier mis à jour avec succès !${NC}"
echo ""
echo "📋 Nouvelle configuration :"
echo "   Développement : http://$CURRENT_IP:3000"
echo ""
echo "🔄 Prochaines étapes :"
echo "   1. Relancez l'app Flutter (hot restart avec 'R')"
echo "   2. L'app devrait maintenant se connecter au serveur"
echo ""
