#!/bin/bash

# Test manuel simplifié - À exécuter depuis le dashboard admin
echo "🧪 TEST MANUEL : Assignation Intervention après Paiement"
echo "========================================================"
echo ""
echo "📋 État AVANT modification:"
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

sqlite3 database.sqlite << EOF
.mode column
.headers on
SELECT 
  'Commande #' || o.id as Commande,
  o.payment_status as Paiement_Cmd,
  'Devis #' || q.id as Devis,
  q.payment_status as Paiement_Devis,
  'Intervention #' || i.id as Intervention,
  i.status as Status_Interv,
  COALESCE(CAST(i.technician_id AS TEXT), 'NULL') as Technicien
FROM orders o
LEFT JOIN quotes q ON o.quote_id = q.id
LEFT JOIN interventions i ON q.intervention_id = i.id
WHERE o.id = 34;
EOF

echo ""
echo "📝 INSTRUCTIONS:"
echo ""
echo "1. Ouvrez le dashboard admin dans votre navigateur"
echo "2. Allez dans la section 'Commandes'"
echo "3. Trouvez la commande #34 (CMD-1770369229200-29)"
echo "4. Changez le statut de paiement à 'Paid'"
echo ""
echo "5. Vérifiez les logs du backend (terminal npm start)"
echo "   Vous devriez voir:"
echo "   ✅ Order 34 payment status updated: pending → paid"
echo "   🔍 Commande liée à un devis (quote_id: 29)..."
echo "   ✅ Technicien 15 assigné à l'intervention 43"
echo ""
echo "6. Puis relancez ce script pour voir les changements"
echo ""
echo "Press Enter pour voir l'état APRÈS modification..."
read

echo ""
echo "📋 État APRÈS modification:"
echo ""

sqlite3 database.sqlite << EOF
.mode column
.headers on
SELECT 
  'Commande #' || o.id as Commande,
  o.payment_status as Paiement_Cmd,
  'Devis #' || q.id as Devis,
  q.payment_status as Paiement_Devis,
  'Intervention #' || i.id as Intervention,
  i.status as Status_Interv,
  COALESCE(CAST(i.technician_id AS TEXT), 'NULL') as Technicien,
  datetime(i.scheduled_date, 'localtime') as Date_Planifiee
FROM orders o
LEFT JOIN quotes q ON o.quote_id = q.id
LEFT JOIN interventions i ON q.intervention_id = i.id
WHERE o.id = 34;
EOF

echo ""
echo "📧 Notifications créées (dernières 2 minutes):"
echo ""

sqlite3 database.sqlite << EOF
.mode column
.headers on
SELECT 
  'User ' || user_id as Destinataire,
  type as Type,
  title as Titre,
  substr(message, 1, 50) as Message,
  priority as Priorite
FROM notifications
WHERE created_at > datetime('now', '-2 minutes')
ORDER BY created_at DESC
LIMIT 10;
EOF

echo ""
echo "========================================================"
