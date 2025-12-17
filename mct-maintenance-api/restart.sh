#!/bin/bash

# Script pour redémarrer le serveur backend
echo "🔄 Arrêt du serveur existant..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

echo "🚀 Démarrage du serveur..."
npm start
