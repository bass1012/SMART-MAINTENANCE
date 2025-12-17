#!/bin/bash

echo "🧪 TEST NOTIFICATION FCM MANUEL"
echo "================================"
echo ""

# Récupérer le token d'un utilisateur avec FCM
echo "1️⃣ Récupération des infos utilisateur..."
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

USER_ID=$(sqlite3 database.sqlite "SELECT id FROM users WHERE fcm_token IS NOT NULL LIMIT 1;")
USER_EMAIL=$(sqlite3 database.sqlite "SELECT email FROM users WHERE id=$USER_ID;")
FCM_TOKEN=$(sqlite3 database.sqlite "SELECT substr(fcm_token, 1, 30) FROM users WHERE id=$USER_ID;")

echo "   User ID: $USER_ID"
echo "   Email: $USER_EMAIL"
echo "   Token FCM: $FCM_TOKEN..."
echo ""

# Récupérer un token JWT valide
echo "2️⃣ Connexion pour obtenir un token JWT..."
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"password\"}" \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Erreur: Impossible de se connecter"
  echo "   Vérifiez que le mot de passe de $USER_EMAIL est 'password'"
  exit 1
fi

echo "   ✅ Token JWT obtenu"
echo ""

# Créer une réclamation via API
echo "3️⃣ Création d'une réclamation via API..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/customer/complaints \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test FCM via API",
    "description": "Test notification push",
    "priority": "high",
    "relatedTo": "service"
  }')

COMPLAINT_ID=$(echo $RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

echo "   ✅ Réclamation créée (ID: $COMPLAINT_ID)"
echo ""

# Attendre un peu
sleep 2

# Changer le statut via curl (en tant qu'admin)
echo "4️⃣ Changement de statut de la réclamation..."
echo "   ⚠️  Besoin d'un token admin..."

# Se connecter en tant qu'admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@mct-maintenance.com","password":"Admin123!"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
  echo "   ❌ Erreur: Impossible de se connecter en tant qu'admin"
  echo "   Changement direct en base de données..."
  sqlite3 database.sqlite "UPDATE complaints SET status='in_progress', updated_at=datetime('now') WHERE id=$COMPLAINT_ID;"
else
  echo "   ✅ Token admin obtenu"
  curl -s -X PATCH http://localhost:3000/api/complaints/$COMPLAINT_ID/status \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{"status":"in_progress"}' > /dev/null
fi

echo "   ✅ Statut changé vers 'in_progress'"
echo ""

echo "📱 VÉRIFIEZ VOTRE MOBILE !"
echo ""
echo "👀 Vérifiez aussi les logs du backend (terminal npm start)"
echo "   Cherchez: '✅ Notification FCM envoyée avec succès'"
echo ""

read -p "Avez-vous reçu la notification ? (o/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Oo]$ ]]; then
  echo "🎉 SUCCÈS ! Les notifications push FCM fonctionnent !"
else
  echo "❌ Notification non reçue."
  echo ""
  echo "🔍 Vérifications à faire:"
  echo "   1. Backend: Logs dans le terminal 'npm start'"
  echo "   2. Mobile: Permissions notifications activées ?"
  echo "   3. Mobile: App en arrière-plan ou fermée ?"
fi

echo ""
echo "🧹 Nettoyage..."
sqlite3 database.sqlite "DELETE FROM complaints WHERE id=$COMPLAINT_ID;" 2>/dev/null
echo "✅ Terminé"
