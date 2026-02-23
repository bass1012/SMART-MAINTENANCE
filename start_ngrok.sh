#!/bin/bash
# Script pour lancer ngrok et exposer l'API backend

echo "🚀 Démarrage de ngrok pour exposer l'API MCT Maintenance..."
echo ""
echo "⚠️  IMPORTANT: Gardez ce terminal ouvert tant que vous utilisez ngrok!"
echo ""

# Vérifier si ngrok est installé
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok n'est pas installé. Installez-le avec:"
    echo "   brew install ngrok"
    exit 1
fi

# Vérifier si le backend tourne
if ! curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "⚠️  Le backend ne semble pas tourner sur le port 3000"
    echo "   Lancez d'abord: cd mct-maintenance-api && npm run dev"
    echo ""
fi

echo "📋 Instructions après le lancement de ngrok:"
echo ""
echo "1. Copiez l'URL 'Forwarding' qui ressemble à:"
echo "   https://xxxx-xxx-xxx.ngrok-free.app"
echo ""
echo "2. Modifiez le fichier:"
echo "   mct_maintenance_mobile/lib/config/environment.dart"
echo ""
echo "3. Changez ces lignes:"
echo "   - currentLocation = Location.ngrok;"
echo "   - ngrokUrl = 'https://xxxx-xxx-xxx.ngrok-free.app';"
echo ""
echo "4. Hot reload l'app Flutter (r dans le terminal flutter run)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Lancer ngrok
ngrok http 3000
