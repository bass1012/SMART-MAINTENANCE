#!/bin/bash

echo "🔥 TEST NOTIFICATION PUSH FCM"
echo "============================="
echo ""

cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Vérifier qu'un token FCM existe
TOKEN_COUNT=$(sqlite3 database.sqlite "SELECT COUNT(*) FROM users WHERE fcm_token IS NOT NULL;")

if [ "$TOKEN_COUNT" -eq 0 ]; then
  echo "❌ ERREUR: Aucun token FCM trouvé en base de données"
  echo ""
  echo "📱 Veuillez d'abord:"
  echo "   1. Lancer l'app mobile: flutter run"
  echo "   2. Se connecter avec votre compte"
  echo "   3. Attendre 'FCM initialisé avec succès'"
  echo "   4. Relancer ce script"
  exit 1
fi

echo "✅ $TOKEN_COUNT token(s) FCM trouvé(s)"
echo ""

# Récupérer l'ID d'un utilisateur avec token FCM
USER_ID=$(sqlite3 database.sqlite "SELECT id FROM users WHERE fcm_token IS NOT NULL LIMIT 1;")
USER_EMAIL=$(sqlite3 database.sqlite "SELECT email FROM users WHERE id=$USER_ID;")

echo "👤 Utilisateur de test: $USER_EMAIL (ID: $USER_ID)"
echo ""

# Créer une réclamation de test
echo "📝 Création d'une réclamation de test..."
CUSTOMER_PROFILE_ID=$(sqlite3 database.sqlite "SELECT customer_profiles.id FROM customer_profiles JOIN users ON customer_profiles.user_id = users.id WHERE users.id = $USER_ID LIMIT 1;")
COMPLAINT_ID=$(sqlite3 database.sqlite "INSERT INTO complaints (reference, customer_id, subject, description, status, priority, created_at, updated_at) VALUES ('REC-TEST-FCM', $CUSTOMER_PROFILE_ID, 'Test FCM', 'Test notification push', 'open', 'high', datetime('now'), datetime('now')); SELECT last_insert_rowid();")

echo "✅ Réclamation créée (ID: $COMPLAINT_ID)"
echo ""

# Attendre un peu
sleep 2

# Changer le statut de la réclamation
echo "🔄 Changement de statut de la réclamation..."
sqlite3 database.sqlite "UPDATE complaints SET status='in_progress', updated_at=datetime('now') WHERE id=$COMPLAINT_ID;"

echo "✅ Statut changé vers 'in_progress'"
echo ""

echo "📱 VÉRIFIEZ VOTRE MOBILE !"
echo ""
echo "Vous devriez recevoir une notification:"
echo "   📌 Titre: 'Réponse à votre réclamation'"
echo "   📄 Message: 'Une réponse a été ajoutée à votre réclamation'"
echo ""

# Attendre confirmation
read -p "Avez-vous reçu la notification ? (o/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Oo]$ ]]; then
  echo "🎉 SUCCÈS ! Les notifications push FCM fonctionnent !"
else
  echo "❌ Notification non reçue. Vérifiez:"
  echo "   1. Les logs backend: Cherchez 'Notification FCM envoyée'"
  echo "   2. Les logs Flutter: Cherchez 'Notification reçue'"
  echo "   3. Permissions Android: Paramètres > Apps > MCT > Notifications"
fi

echo ""
echo "🧹 Nettoyage de la réclamation de test..."
sqlite3 database.sqlite "DELETE FROM complaints WHERE id=$COMPLAINT_ID;"
echo "✅ Nettoyage terminé"
