#!/bin/bash
# Script de Test Upload Images - MCT Maintenance
# Date : 16 octobre 2025

echo "🧪 Tests Upload Images - MCT Maintenance"
echo "========================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
API_URL="http://localhost:3000"
FRONTEND_URL="http://localhost:3001"
TEST_IMAGE="test-image.jpg"

echo "📋 Vérifications préliminaires..."
echo ""

# 1. Test Backend API
echo -n "1️⃣  Backend API (port 3000)... "
if curl -s "$API_URL/api/products" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR${NC}"
    echo "   Le serveur backend n'est pas accessible"
    exit 1
fi

# 2. Test Frontend
echo -n "2️⃣  Frontend Dashboard (port 3001)... "
if curl -s "$FRONTEND_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING${NC}"
    echo "   Le frontend n'est peut-être pas encore démarré"
fi

# 3. Test dossiers uploads
echo -n "3️⃣  Dossiers uploads/... "
if [ -d "uploads/avatars" ] && [ -d "uploads/products" ] && [ -d "uploads/equipments" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR${NC}"
    echo "   Les dossiers uploads n'existent pas"
    exit 1
fi

# 4. Permissions dossiers
echo -n "4️⃣  Permissions dossiers... "
if [ -w "uploads/avatars" ] && [ -w "uploads/products" ] && [ -w "uploads/equipments" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR${NC}"
    echo "   Les dossiers uploads ne sont pas accessibles en écriture"
    exit 1
fi

echo ""
echo "✅ Vérifications préliminaires terminées"
echo ""

# Tests manuels requis
echo "📝 Tests Manuels Requis"
echo "======================="
echo ""
echo "⚠️  Les tests suivants nécessitent une interaction manuelle :"
echo ""
echo "1️⃣  Test ProductForm (Upload Image Produit)"
echo "   - Ouvrir : $FRONTEND_URL"
echo "   - Aller dans : Menu → Produits"
echo "   - Cliquer : 'Nouveau produit'"
echo "   - Remplir le formulaire"
echo "   - Créer le produit"
echo "   - Modifier le produit"
echo "   - Faire défiler jusqu'à 'Image du produit'"
echo "   - Uploader une image (drag & drop ou cliquer)"
echo "   - Vérifier : Preview s'affiche ✅"
echo "   - Vérifier : Message 'Image uploadée avec succès' ✅"
echo ""
echo "2️⃣  Test EquipmentForm (Upload Image Équipement)"
echo "   - Aller dans : Menu → Équipements"
echo "   - Cliquer : 'Ajouter un équipement'"
echo "   - Remplir le formulaire"
echo "   - Créer l'équipement"
echo "   - Modifier l'équipement"
echo "   - Uploader une photo"
echo "   - Vérifier : Preview s'affiche ✅"
echo ""
echo "3️⃣  Test UserForm (Upload Avatar)"
echo "   - Aller dans : Menu → Utilisateurs"
echo "   - Cliquer : 'Ajouter un utilisateur'"
echo "   - Remplir le formulaire"
echo "   - Faire défiler jusqu'à 'Photo de profil'"
echo "   - Uploader un avatar"
echo "   - Vérifier : Preview circulaire s'affiche ✅"
echo ""

# Information sur les fichiers uploadés
echo ""
echo "📂 Fichiers Uploadés"
echo "==================="
echo ""
echo "Avatars :"
ls -lh uploads/avatars/ 2>/dev/null | grep -v "^total" | grep -v "^d" || echo "  Aucun fichier"
echo ""
echo "Products :"
ls -lh uploads/products/ 2>/dev/null | grep -v "^total" | grep -v "^d" || echo "  Aucun fichier"
echo ""
echo "Equipments :"
ls -lh uploads/equipments/ 2>/dev/null | grep -v "^total" | grep -v "^d" || echo "  Aucun fichier"
echo ""

echo "🎯 Checklist de Test"
echo "===================="
echo ""
echo "ProductForm :"
echo "  [ ] Upload fonctionne"
echo "  [ ] Preview s'affiche"
echo "  [ ] Suppression fonctionne"
echo "  [ ] Drag & drop fonctionne"
echo ""
echo "EquipmentForm :"
echo "  [ ] Upload fonctionne"
echo "  [ ] Preview s'affiche"
echo "  [ ] Suppression fonctionne"
echo ""
echo "UserForm :"
echo "  [ ] Upload fonctionne"
echo "  [ ] Preview circulaire"
echo "  [ ] Suppression fonctionne"
echo ""

echo "📚 Documentation"
echo "==============="
echo ""
echo "Guide de test détaillé : GUIDE_TEST_UPLOAD_IMAGES.md"
echo "Rapport complet        : SESSION_COMPLETE_16_OCT_2025.md"
echo ""

echo "✅ Script de test terminé"
echo ""
echo "💡 Pour plus d'informations : cat GUIDE_TEST_UPLOAD_IMAGES.md"
