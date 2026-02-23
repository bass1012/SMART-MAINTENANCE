#!/bin/bash

# Script pour créer un administrateur dans la base de données
# Usage: ./create-admin.sh [email] [password]

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Chemin du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Vérifier que Node.js est installé
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js n'est pas installé${NC}"
    exit 1
fi

# Vérifier que le fichier .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Fichier .env introuvable${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Création d'un administrateur...${NC}"
echo ""

# Exécuter le script Node.js
if [ $# -eq 0 ]; then
    # Utiliser les valeurs par défaut
    node scripts/createAdmin.js
elif [ $# -eq 2 ]; then
    # Utiliser les valeurs fournies
    ADMIN_EMAIL="$1" ADMIN_PASSWORD="$2" node scripts/createAdmin.js
else
    echo -e "${RED}❌ Usage: $0 [email] [password]${NC}"
    echo "   Sans arguments: utilise supportuser@mct.ci / Keep0ut@2024!"
    echo "   Avec arguments: $0 admin@example.com MonMotDePasse"
    exit 1
fi

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Administrateur créé avec succès!${NC}"
else
    echo ""
    echo -e "${RED}❌ Échec de la création de l'administrateur${NC}"
    exit 1
fi
