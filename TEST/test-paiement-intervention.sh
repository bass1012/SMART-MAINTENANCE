#!/bin/bash

# Script de test du flux : Paiement devis → Assignation intervention
# Teste l'assignation automatique du technicien et la planification

echo "🧪 TEST : Flux Paiement Devis → Intervention Planifiée"
echo "========================================================"
echo ""

# Configuration
API_URL="http://localhost:5000/api"
DB_PATH="/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "📋 Étape 1 : Vérifier qu'un devis existe avec un rapport de diagnostic"
echo "--------------------------------------------------------------------"

# Trouver un devis avec rapport de diagnostic
QUOTE_DATA=$(sqlite3 "$DB_PATH" << EOF
SELECT 
  q.id as quote_id,
  q.intervention_id,
  q.total,
  dr.id as diagnostic_id,
  dr.technician_id,
  i.customer_id,
  cp.user_id as customer_user_id
FROM quotes q
JOIN diagnostic_reports dr ON q.diagnostic_report_id = dr.id
JOIN interventions i ON q.intervention_id = i.id
JOIN customer_profiles cp ON i.customer_id = cp.id
WHERE q.payment_status = 'pending'
LIMIT 1;
EOF
)

if [ -z "$QUOTE_DATA" ]; then
  echo -e "${RED}❌ Aucun devis en attente trouvé${NC}"
  echo "Veuillez créer un devis depuis un rapport de diagnostic"
  exit 1
fi

# Parser les données
QUOTE_ID=$(echo "$QUOTE_DATA" | cut -d'|' -f1)
INTERVENTION_ID=$(echo "$QUOTE_DATA" | cut -d'|' -f2)
TOTAL=$(echo "$QUOTE_DATA" | cut -d'|' -f3)
TECHNICIAN_ID=$(echo "$QUOTE_DATA" | cut -d'|' -f5)
CUSTOMER_USER_ID=$(echo "$QUOTE_DATA" | cut -d'|' -f7)

echo -e "${GREEN}✓${NC} Devis trouvé:"
echo "  - ID Devis: $QUOTE_ID"
echo "  - ID Intervention: $INTERVENTION_ID"
echo "  - Montant: $TOTAL FCFA"
echo "  - Technicien du diagnostic: $TECHNICIAN_ID"
echo "  - Client (user_id): $CUSTOMER_USER_ID"
echo ""

echo "📋 Étape 2 : État AVANT paiement"
echo "--------------------------------"

# État de l'intervention avant
INTERVENTION_BEFORE=$(sqlite3 "$DB_PATH" << EOF
SELECT status, technician_id, scheduled_date 
FROM interventions 
WHERE id = $INTERVENTION_ID;
EOF
)

echo "Intervention #$INTERVENTION_ID :"
echo "  - Statut: $(echo "$INTERVENTION_BEFORE" | cut -d'|' -f1)"
echo "  - Technicien: $(echo "$INTERVENTION_BEFORE" | cut -d'|' -f2)"
echo "  - Date planifiée: $(echo "$INTERVENTION_BEFORE" | cut -d'|' -f3)"
echo ""

echo "📋 Étape 3 : Simuler le webhook de paiement CinetPay"
echo "----------------------------------------------------"

# Générer un ID de transaction
TRANSACTION_ID="QTE-${QUOTE_ID}-$(date +%s)"

echo "Transaction ID: $TRANSACTION_ID"
echo ""

# Simuler le webhook CinetPay
echo "Envoi du webhook de confirmation de paiement..."

WEBHOOK_RESPONSE=$(curl -s -X POST \
  "${API_URL}/payments/cinetpay/notify-quote" \
  -H "Content-Type: application/json" \
  -d '{
    "cpm_trans_id": "'"$TRANSACTION_ID"'",
    "cpm_site_id": "test",
    "signature": "test",
    "payment_method": "MOBILE_MONEY",
    "cel_phone_num": "+225123456789",
    "cpm_phone_prefixe": "225",
    "cpm_language": "fr",
    "cpm_version": "V2",
    "cpm_payment_config": "SINGLE",
    "cpm_page_action": "PAYMENT",
    "cpm_custom": "'"$QUOTE_ID"'",
    "cpm_currency": "XOF",
    "cpm_payid": "123456789",
    "cpm_payment_date": "'"$(date -u +"%Y-%m-%d %H:%M:%S")"'",
    "cpm_payment_time": "'"$(date +%H:%M:%S)"'",
    "cpm_error_message": "",
    "cpm_algo": "sha256",
    "cpm_trans_status": "ACCEPTED",
    "cpm_designation": "Paiement devis #'"$QUOTE_ID"'",
    "buyer_name": "Client Test",
    "cpm_site_name": "Test Site",
    "cpm_amount": "'"$TOTAL"'",
    "cpm_trans_ref": "'"$TRANSACTION_ID"'",
    "cpm_result": "00",
    "cpm_trans_type": "PAYMENT"
  }')

echo -e "${BLUE}Réponse webhook:${NC}"
echo "$WEBHOOK_RESPONSE"
echo ""

# Attendre un peu pour que le traitement soit terminé
sleep 2

echo "📋 Étape 4 : Vérifier l'état APRÈS paiement"
echo "-------------------------------------------"

# État du devis après
QUOTE_AFTER=$(sqlite3 "$DB_PATH" << EOF
SELECT payment_status, paid_at, payment_method 
FROM quotes 
WHERE id = $QUOTE_ID;
EOF
)

echo -e "${YELLOW}Devis #$QUOTE_ID :${NC}"
echo "  - Statut paiement: $(echo "$QUOTE_AFTER" | cut -d'|' -f1)"
echo "  - Payé le: $(echo "$QUOTE_AFTER" | cut -d'|' -f2)"
echo "  - Méthode: $(echo "$QUOTE_AFTER" | cut -d'|' -f3)"
echo ""

# État de l'intervention après
INTERVENTION_AFTER=$(sqlite3 "$DB_PATH" << EOF
SELECT status, technician_id, scheduled_date, payment_date
FROM interventions 
WHERE id = $INTERVENTION_ID;
EOF
)

STATUS=$(echo "$INTERVENTION_AFTER" | cut -d'|' -f1)
TECH_ID=$(echo "$INTERVENTION_AFTER" | cut -d'|' -f2)
SCHEDULED=$(echo "$INTERVENTION_AFTER" | cut -d'|' -f3)
PAYMENT_DATE=$(echo "$INTERVENTION_AFTER" | cut -d'|' -f4)

echo -e "${YELLOW}Intervention #$INTERVENTION_ID :${NC}"
echo "  - Statut: $STATUS"
echo "  - Technicien assigné: $TECH_ID"
echo "  - Date planifiée: $SCHEDULED"
echo "  - Date paiement: $PAYMENT_DATE"
echo ""

# Vérifications
echo "📋 Étape 5 : Vérifications"
echo "--------------------------"

SUCCESS=true

# Vérifier que le devis est payé
if [ "$(echo "$QUOTE_AFTER" | cut -d'|' -f1)" = "paid" ]; then
  echo -e "${GREEN}✓${NC} Devis marqué comme payé"
else
  echo -e "${RED}✗${NC} Devis PAS marqué comme payé"
  SUCCESS=false
fi

# Vérifier que l'intervention est assignée
if [ "$STATUS" = "assigned" ]; then
  echo -e "${GREEN}✓${NC} Intervention marquée comme assignée"
else
  echo -e "${RED}✗${NC} Intervention NOT assigned (statut: $STATUS)"
  SUCCESS=false
fi

# Vérifier que le technicien est assigné
if [ "$TECH_ID" = "$TECHNICIAN_ID" ]; then
  echo -e "${GREEN}✓${NC} Technicien du diagnostic assigné (ID: $TECH_ID)"
else
  echo -e "${RED}✗${NC} Technicien différent ou non assigné (attendu: $TECHNICIAN_ID, obtenu: $TECH_ID)"
  SUCCESS=false
fi

# Vérifier qu'une date est planifiée
if [ ! -z "$SCHEDULED" ]; then
  echo -e "${GREEN}✓${NC} Date d'intervention planifiée: $SCHEDULED"
  
  # Vérifier que c'est dans environ 2 jours
  SCHEDULED_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M:%S" "$SCHEDULED" +%s 2>/dev/null || echo "0")
  NOW_TIMESTAMP=$(date +%s)
  DAYS_DIFF=$(( ($SCHEDULED_TIMESTAMP - $NOW_TIMESTAMP) / 86400 ))
  
  if [ $DAYS_DIFF -ge 1 ] && [ $DAYS_DIFF -le 4 ]; then
    echo -e "${GREEN}✓${NC} Date dans $DAYS_DIFF jours (correct)"
  else
    echo -e "${YELLOW}⚠${NC} Date dans $DAYS_DIFF jours (attendu: 2-3 jours)"
  fi
  
  # Vérifier l'heure (doit être 9h)
  HOUR=$(echo "$SCHEDULED" | sed 's/.*\([0-9][0-9]\):[0-9][0-9]:[0-9][0-9]/\1/')
  if [ "$HOUR" = "09" ] || [ "$HOUR" = "9" ]; then
    echo -e "${GREEN}✓${NC} Heure définie à 9h00"
  else
    echo -e "${YELLOW}⚠${NC} Heure: ${HOUR}h (attendu: 9h)"
  fi
else
  echo -e "${RED}✗${NC} Pas de date planifiée"
  SUCCESS=false
fi

echo ""

# Vérifier les notifications
echo "📋 Étape 6 : Vérifier les notifications"
echo "---------------------------------------"

# Notification technicien
TECH_NOTIF=$(sqlite3 "$DB_PATH" << EOF
SELECT COUNT(*) FROM notifications 
WHERE user_id = $TECHNICIAN_ID 
AND type = 'intervention_assigned'
AND created_at > datetime('now', '-5 minutes');
EOF
)

if [ "$TECH_NOTIF" -gt "0" ]; then
  echo -e "${GREEN}✓${NC} Notification envoyée au technicien"
  
  # Afficher le contenu
  sqlite3 "$DB_PATH" << EOF
SELECT 
  '  Title: ' || title,
  '  Message: ' || message,
  '  Priority: ' || priority
FROM notifications 
WHERE user_id = $TECHNICIAN_ID 
AND type = 'intervention_assigned'
ORDER BY created_at DESC
LIMIT 1;
EOF
else
  echo -e "${RED}✗${NC} Pas de notification pour le technicien"
  SUCCESS=false
fi

echo ""

# Notification client
CLIENT_NOTIF=$(sqlite3 "$DB_PATH" << EOF
SELECT COUNT(*) FROM notifications 
WHERE user_id = $CUSTOMER_USER_ID 
AND type = 'payment_confirmed'
AND created_at > datetime('now', '-5 minutes');
EOF
)

if [ "$CLIENT_NOTIF" -gt "0" ]; then
  echo -e "${GREEN}✓${NC} Notification envoyée au client"
  
  # Afficher le contenu
  sqlite3 "$DB_PATH" << EOF
SELECT 
  '  Title: ' || title,
  '  Message: ' || message,
  '  Priority: ' || priority
FROM notifications 
WHERE user_id = $CUSTOMER_USER_ID 
AND type = 'payment_confirmed'
ORDER BY created_at DESC
LIMIT 1;
EOF
else
  echo -e "${RED}✗${NC} Pas de notification pour le client"
  SUCCESS=false
fi

echo ""
echo "========================================================"

if [ "$SUCCESS" = true ]; then
  echo -e "${GREEN}✅ TEST RÉUSSI !${NC}"
  echo ""
  echo "Résumé:"
  echo "  - Devis payé: ✓"
  echo "  - Technicien assigné: ✓"
  echo "  - Date planifiée: ✓"
  echo "  - Notifications envoyées: ✓"
  echo ""
  echo "Le flux est fonctionnel ! 🎉"
  exit 0
else
  echo -e "${RED}❌ TEST ÉCHOUÉ${NC}"
  echo ""
  echo "Certaines vérifications ont échoué."
  echo "Vérifiez les logs ci-dessus."
  exit 1
fi
