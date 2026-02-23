#!/bin/bash

# Test rapide du paiement de commande liée à un devis
# Ce script simule le paiement d'une commande qui déclenchera l'assignation d'intervention

echo "🧪 TEST : Paiement de commande → Assignation intervention"
echo "=========================================================="
echo ""

API_URL="http://localhost:5000/api"
DB_PATH="/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite"

# Récupérer un token admin pour le test
echo "🔑 Connexion admin..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mct.com",
    "password": "admin123"
  }')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Impossible de se connecter"
  exit 1
fi

echo "✅ Token obtenu"
echo ""

# Identifier la commande #34
ORDER_ID=34
echo "📦 Test avec commande #$ORDER_ID"
echo ""

# État AVANT
echo "📋 État AVANT paiement:"
echo "----------------------"
sqlite3 "$DB_PATH" << EOF
SELECT 
  'Commande:     Order #' || o.id || ' (' || o.reference || ')' || ' - Payment: ' || o.payment_status,
  'Devis:        Quote #' || q.id || ' - Payment: ' || q.payment_status,
  'Intervention: #' || i.id || ' - Status: ' || i.status || ' - Technicien: ' || COALESCE(CAST(i.technician_id AS TEXT), 'NULL')
FROM orders o
LEFT JOIN quotes q ON o.quote_id = q.id
LEFT JOIN interventions i ON q.intervention_id = i.id
WHERE o.id = $ORDER_ID;
EOF
echo ""

# Marquer comme payé
echo "💳 Marquage paiement comme 'paid'..."
PAYMENT_RESPONSE=$(curl -s -X PATCH \
  "${API_URL}/orders/${ORDER_ID}/payment-status" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paymentStatus": "paid"}')

echo "Réponse API:"
echo "$PAYMENT_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$PAYMENT_RESPONSE"
echo ""

# Attendre un peu pour le traitement
sleep 2

# État APRÈS
echo "📋 État APRÈS paiement:"
echo "----------------------"
sqlite3 "$DB_PATH" << EOF
SELECT 
  'Commande:     Order #' || o.id || ' - Payment: ' || o.payment_status,
  'Devis:        Quote #' || q.id || ' - Payment: ' || q.payment_status || ' - Payé le: ' || COALESCE(q.paid_at, 'NULL'),
  'Intervention: #' || i.id || ' - Status: ' || i.status || ' - Technicien: ' || COALESCE(CAST(i.technician_id AS TEXT), 'NULL'),
  'Date prévue:  ' || COALESCE(datetime(i.scheduled_date, 'localtime'), 'NULL')
FROM orders o
LEFT JOIN quotes q ON o.quote_id = q.id
LEFT JOIN interventions i ON q.intervention_id = i.id
WHERE o.id = $ORDER_ID;
EOF
echo ""

# Vérifier les notifications
echo "📧 Notifications récentes (dernières 2 minutes):"
echo "-----------------------------------------------"
sqlite3 "$DB_PATH" << EOF
SELECT 
  'User ' || user_id || ' - ' || type || ': ' || title || ' (Priority: ' || priority || ')'
FROM notifications
WHERE created_at > datetime('now', '-2 minutes')
ORDER BY created_at DESC
LIMIT 5;
EOF
echo ""

# Résumé
echo "=========================================================="
echo "✅ Test terminé !"
echo ""
echo "Vérifications à faire:"
echo "  1. Le devis doit être marqué 'paid'"
echo "  2. L'intervention doit être en statut 'assigned'"
echo "  3. Le technicien doit être assigné"
echo "  4. Une date doit être planifiée (environ 2 jours)"
echo "  5. Notifications pour le technicien et le client"
