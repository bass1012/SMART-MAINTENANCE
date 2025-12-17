#!/bin/bash

echo "⚡ TEST RAPIDE FCM - Changement de statut"
echo "========================================="
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Récupérer l'ID de l'utilisateur avec token FCM
USER_ID=$(sqlite3 database.sqlite "SELECT id FROM users WHERE fcm_token IS NOT NULL LIMIT 1;")
USER_EMAIL=$(sqlite3 database.sqlite "SELECT email FROM users WHERE id=$USER_ID;")
CUSTOMER_PROFILE_ID=$(sqlite3 database.sqlite "SELECT customer_profiles.id FROM customer_profiles JOIN users ON customer_profiles.user_id = users.id WHERE users.id = $USER_ID LIMIT 1;")

echo "👤 Utilisateur: $USER_EMAIL (ID: $USER_ID)"
echo "📋 Customer Profile ID: $CUSTOMER_PROFILE_ID"
echo ""

# Créer une réclamation directement en base
echo "📝 Création d'une réclamation..."
COMPLAINT_ID=$(sqlite3 database.sqlite "INSERT INTO complaints (reference, customer_id, subject, description, status, priority, created_at, updated_at) VALUES ('REC-FCM-' || datetime('now'), $CUSTOMER_PROFILE_ID, 'Test notification FCM', 'Test automatique', 'open', 'high', datetime('now'), datetime('now')); SELECT last_insert_rowid();")

echo "✅ Réclamation créée (ID: $COMPLAINT_ID)"
echo ""

# Attendre
sleep 1

echo "🔄 Envoi de PATCH /api/complaints/$COMPLAINT_ID/status..."
echo ""

# Faire un curl PATCH pour changer le statut
RESPONSE=$(curl -s -X PATCH "http://localhost:3000/api/complaints/$COMPLAINT_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NiwiZW1haWwiOiJhZG1pbkBtY3QtbWFpbnRlbmFuY2UuY29tIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzYxMzAxNTgyLCJleHAiOjE3NjE5MDYzODJ9.jwicS4qUGudi7GnXnZpBCDIGNPtYgPFhrZpX19e78Gk" \
  -d '{"status":"in_progress","resolution":"Test en cours"}')

echo "📤 Réponse API:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
echo ""

echo "📱 VÉRIFIEZ VOTRE MOBILE !"
echo ""
echo "👀 Vérifiez les logs backend dans le terminal npm start"
echo "   Cherchez:"
echo "   - PATCH /api/complaints/$COMPLAINT_ID/status"
echo "   - 📬 Notification créée pour user $USER_ID"
echo "   - ✅ Notification FCM envoyée avec succès"
echo ""

read -p "Appuyez sur Entrée pour nettoyer..."

# Nettoyage
sqlite3 database.sqlite "DELETE FROM complaints WHERE id=$COMPLAINT_ID;"
echo "✅ Réclamation supprimée"
