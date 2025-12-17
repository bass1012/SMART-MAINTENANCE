#!/bin/bash

# Script d'installation rapide du système d'upload d'images
# Usage: bash setup-images.sh

echo "🚀 Installation du système d'upload d'images pour interventions"
echo "================================================================"
echo ""

# 1. Installer multer
echo "📦 Étape 1/3 : Installation de multer..."
npm install multer
echo "✅ Multer installé"
echo ""

# 2. Appliquer la migration
echo "🗄️  Étape 2/3 : Application de la migration base de données..."
node apply-intervention-images-migration.js
echo "✅ Migration appliquée"
echo ""

# 3. Créer le dossier uploads
echo "📁 Étape 3/3 : Création du dossier uploads..."
mkdir -p uploads/interventions
echo "✅ Dossier uploads/interventions créé"
echo ""

echo "🎉 Installation terminée avec succès !"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Vérifier que les fichiers sont en place :"
echo "      - src/models/InterventionImage.js"
echo "      - src/config/multer.js"
echo "      - src/controllers/intervention/interventionController.js (modifié)"
echo "      - src/app.js (modifié)"
echo ""
echo "   2. Redémarrer le serveur :"
echo "      npm run dev"
echo ""
echo "   3. Tester depuis l'app mobile :"
echo "      cd ../mct_maintenance_mobile && flutter run"
echo ""
echo "✨ Le système est prêt à recevoir jusqu'à 5 photos par intervention !"
