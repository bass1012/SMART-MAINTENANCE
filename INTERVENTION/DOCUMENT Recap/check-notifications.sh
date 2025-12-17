#!/bin/bash

echo "🔍 Vérification du système de notifications"
echo "==========================================="
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# 1. Vérifier le backend
echo "1️⃣  Backend..."
if lsof -ti:3000 > /dev/null 2>&1; then
  echo "   ✅ Backend actif sur port 3000"
else
  echo "   ❌ Backend non actif"
  exit 1
fi

# 2. Vérifier Socket.IO
echo ""
echo "2️⃣  Socket.IO..."
if curl -s http://localhost:3000/health | grep -q "OK"; then
  echo "   ✅ API répond"
else
  echo "   ❌ API ne répond pas"
fi

# 3. Vérifier les admins
echo ""
echo "3️⃣  Admins en base..."
ADMIN_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM users WHERE role='admin' AND status='active';" 2>/dev/null)
if [ "$ADMIN_COUNT" -gt 0 ]; then
  echo "   ✅ $ADMIN_COUNT admin(s) actif(s)"
  sqlite3 database.sqlite "SELECT '   - ID: ' || id || ', Email: ' || email FROM users WHERE role='admin' AND status='active';"
else
  echo "   ❌ Aucun admin actif"
fi

# 4. Vérifier les notifications récentes
echo ""
echo "4️⃣  Notifications récentes..."
NOTIF_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM notifications WHERE created_at > datetime('now', '-1 hour');" 2>/dev/null)
if [ "$NOTIF_COUNT" -gt 0 ]; then
  echo "   ✅ $NOTIF_COUNT notification(s) dans la dernière heure"
  echo ""
  echo "   Dernières notifications:"
  sqlite3 database.sqlite "SELECT '   - ' || type || ' → User ' || user_id || ' (' || substr(created_at, 12, 5) || ')' FROM notifications ORDER BY created_at DESC LIMIT 3;"
else
  echo "   ⚠️  Aucune notification récente"
fi

# 5. Vérifier le dashboard
echo ""
echo "5️⃣  Dashboard..."
if lsof -ti:3001 > /dev/null 2>&1; then
  echo "   ✅ Dashboard actif sur port 3001"
else
  echo "   ❌ Dashboard non actif"
fi

echo ""
echo "==========================================="
echo ""
echo "📋 Pour tester :"
echo "   1. Ouvrir http://localhost:3001"
echo "   2. Se connecter avec admin@mct-maintenance.com"
echo "   3. Ouvrir la console (F12)"
echo "   4. Créer une intervention depuis le mobile"
echo "   5. Regarder la cloche 🔔"
echo ""
