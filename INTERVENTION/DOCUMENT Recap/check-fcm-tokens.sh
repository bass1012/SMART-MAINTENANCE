#!/bin/bash

echo "🔍 VÉRIFICATION DES TOKENS FCM"
echo "=============================="
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

echo "📱 Tokens FCM enregistrés:"
sqlite3 database.sqlite <<EOF
.mode column
.headers on
SELECT 
  id,
  email,
  role,
  CASE 
    WHEN fcm_token IS NOT NULL 
    THEN '✅ Token: ' || substr(fcm_token, 1, 20) || '...' 
    ELSE '❌ PAS DE TOKEN' 
  END as fcm_status
FROM users 
WHERE role IN ('customer', 'admin')
ORDER BY id DESC 
LIMIT 10;
EOF

echo ""
echo "📊 Statistiques:"
sqlite3 database.sqlite "SELECT role, COUNT(*) as total, SUM(CASE WHEN fcm_token IS NOT NULL THEN 1 ELSE 0 END) as avec_token FROM users WHERE role IN ('customer', 'admin') GROUP BY role;"

echo ""
echo "💡 Pour tester:"
echo "   1. Connectez-vous dans l'app mobile"
echo "   2. Attendez 'FCM initialisé avec succès' dans les logs"
echo "   3. Relancez ce script"
