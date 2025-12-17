#!/bin/bash

# Script pour démarrer le backend MCT Maintenance
# Usage: ./START_BACKEND.sh

echo "🔄 Arrêt du serveur existant..."
lsof -ti:3000 | xargs kill -9 2>/dev/null

echo "⏳ Attente de la libération du port..."
sleep 2

echo "🚀 Démarrage du serveur..."
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
