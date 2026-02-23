#!/bin/bash

echo "🧪 Test API Direct - Paiement Commande"
echo "======================================"

# Se connecter comme admin
echo "🔑 Connexion admin..."
LOGIN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@mct.com","password":"admin123"}')

TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Échec connexion. Essayons avec un autre compte..."
  LOGIN=$(curl -s -X POST http://localhost:3000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"bassirou2010@gmail.com","password":"123456"}')
  TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ]; then
  echo "❌ Impossible de se connecter"
  echo "Réponse: $LOGIN"
  exit 1
fi

echo "✅ Token obtenu: ${TOKEN:0:20}..."
echo ""

# Marquer la commande comme payée
echo "💳 Marquage commande #34 comme 'paid'..."
echo ""

RESPONSE=$(curl -s -X PATCH http://localhost:3000/api/orders/34/payment-status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paymentStatus":"paid"}')

echo "📡 Réponse API:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

echo "⏳ Attente 3 secondes pour le traitement..."
sleep 3

echo ""
echo "🔍 VÉRIFICATION EN BASE:"
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

sqlite3 database.sqlite << EOF
.mode column
.headers on
SELECT 
  'Order#' || o.id as Cmd,
  o.payment_status as Pay_Cmd,
  'Quote#' || q.id as Devis,
  q.payment_status as Pay_Devis,
  'Interv#' || i.id as Interv,
  i.status as Status,
  COALESCE(CAST(i.technician_id AS TEXT), 'NULL') as Tech_ID
FROM orders o
LEFT JOIN quotes q ON o.quote_id = q.id
LEFT JOIN interventions i ON q.intervention_id = i.id
WHERE o.id = 34;
EOF

echo ""
echo "📧 NOTIFICATIONS (2 dernières minutes):"
sqlite3 database.sqlite << EOF
.mode column
.headers on
SELECT 
  user_id,
  type,
  substr(title, 1, 30) as title,
  substr(message, 1, 50) as message
FROM notifications
WHERE created_at > datetime('now', '-2 minutes')
ORDER BY created_at DESC
LIMIT 5;
EOF

echo ""
echo "======================================"
echo "✅ Vérifiez les logs du terminal 'npm start'"
echo "   Vous devriez voir des logs détaillés"
