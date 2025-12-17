#!/bin/bash

echo "🔥 TEST FCM - ANDROID UNIQUEMENT"
echo "================================"
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile

echo "📱 Lancement de l'app sur Android..."
echo ""
echo "⚠️  IMPORTANT: Connectez-vous dans l'app après le démarrage"
echo ""
echo "Logs à surveiller:"
echo "  ✅ 🔥 Firebase initialisé"
echo "  ✅ 📱 Handler background configuré"
echo "  ✅ ✅ Permission de notification accordée"
echo "  ✅ 📱 FCM Token obtenu: xxx..."
echo "  ✅ ✅ Token FCM enregistré dans le backend"
echo ""

flutter run -d $(flutter devices | grep android | head -1 | awk '{print $5}' | tr -d '•')
