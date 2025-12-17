#!/bin/bash

echo "🔍 Vérification complète du système de notifications"
echo "===================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Backend
echo -e "${BLUE}1️⃣  Backend API${NC}"
if lsof -ti:3000 > /dev/null 2>&1; then
  echo -e "   ${GREEN}✅ Backend actif sur port 3000${NC}"
  
  # Test de santé
  if curl -s http://localhost:3000/health | grep -q "OK"; then
    echo -e "   ${GREEN}✅ API répond correctement${NC}"
  else
    echo -e "   ${RED}❌ API ne répond pas${NC}"
  fi
else
  echo -e "   ${RED}❌ Backend non actif${NC}"
fi
echo ""

# 2. Dashboard
echo -e "${BLUE}2️⃣  Dashboard Web${NC}"
if lsof -ti:3001 > /dev/null 2>&1; then
  echo -e "   ${GREEN}✅ Dashboard actif sur port 3001${NC}"
else
  echo -e "   ${RED}❌ Dashboard non actif${NC}"
fi
echo ""

# 3. Base de données
echo -e "${BLUE}3️⃣  Base de données${NC}"
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Vérifier les admins
ADMIN_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM users WHERE role='admin' AND status='active';" 2>/dev/null)
if [ "$ADMIN_COUNT" -gt 0 ]; then
  echo -e "   ${GREEN}✅ $ADMIN_COUNT admin(s) actif(s)${NC}"
  sqlite3 database.sqlite "SELECT '   📧 ' || email || ' (ID: ' || id || ')' FROM users WHERE role='admin' AND status='active';"
else
  echo -e "   ${RED}❌ Aucun admin actif${NC}"
fi
echo ""

# Vérifier les notifications
NOTIF_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM notifications;" 2>/dev/null)
echo -e "   ${GREEN}📊 $NOTIF_COUNT notification(s) en base${NC}"

RECENT_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM notifications WHERE created_at > datetime('now', '-1 hour');" 2>/dev/null)
if [ "$RECENT_COUNT" -gt 0 ]; then
  echo -e "   ${GREEN}✅ $RECENT_COUNT notification(s) dans la dernière heure${NC}"
  echo ""
  echo -e "   ${YELLOW}Dernières notifications:${NC}"
  sqlite3 database.sqlite "SELECT '   ' || substr(created_at, 12, 5) || ' → ' || type || ' (User ' || user_id || ')' FROM notifications ORDER BY created_at DESC LIMIT 3;"
else
  echo -e "   ${YELLOW}⚠️  Aucune notification récente${NC}"
fi
echo ""

# 4. Fichiers critiques
echo -e "${BLUE}4️⃣  Fichiers critiques${NC}"

# NotificationBell.tsx
if [ -f "/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard/src/components/Notifications/NotificationBell.tsx" ]; then
  echo -e "   ${GREEN}✅ NotificationBell.tsx existe${NC}"
  
  # Vérifier si les logs de debug sont présents
  if grep -q "NotificationBell mounted" "/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard/src/components/Notifications/NotificationBell.tsx"; then
    echo -e "   ${GREEN}✅ Logs de debug présents${NC}"
  else
    echo -e "   ${YELLOW}⚠️  Logs de debug manquants${NC}"
  fi
else
  echo -e "   ${RED}❌ NotificationBell.tsx manquant${NC}"
fi

# socketService.ts
if [ -f "/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard/src/services/socketService.ts" ]; then
  echo -e "   ${GREEN}✅ socketService.ts existe${NC}"
else
  echo -e "   ${RED}❌ socketService.ts manquant${NC}"
fi

# notificationService.js (backend)
if [ -f "/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/src/services/notificationService.js" ]; then
  echo -e "   ${GREEN}✅ notificationService.js existe${NC}"
else
  echo -e "   ${RED}❌ notificationService.js manquant${NC}"
fi
echo ""

# 5. Test Socket.IO
echo -e "${BLUE}5️⃣  Test Socket.IO${NC}"
echo -e "   ${YELLOW}Pour tester Socket.IO:${NC}"
echo -e "   1. Ouvrir: file:///Users/bassoued/Documents/MAINTENANCE/test-socketio.html"
echo -e "   2. Cliquer sur 'Se connecter'"
echo -e "   3. Lancer: node trigger-test-notification.js"
echo ""

# Résumé
echo "===================================================="
echo ""
echo -e "${GREEN}📋 PROCHAINES ÉTAPES:${NC}"
echo ""
echo "1. Ouvrir le dashboard: http://localhost:3001"
echo "2. Se connecter avec: admin@mct-maintenance.com"
echo "3. Appuyer sur F5 pour rafraîchir"
echo "4. Appuyer sur F12 pour ouvrir la console"
echo "5. Partager les logs de la console"
echo ""
