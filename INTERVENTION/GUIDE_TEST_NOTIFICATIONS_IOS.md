# 🧪 Guide de Test des Notifications iOS

## 🎯 Objectif
Tester si les notifications iOS fonctionnent maintenant que la clé APNs est configurée.

---

## ✅ Prérequis
- [x] Compte Apple Developer payant
- [x] Clé APNs `.p8` uploadée dans Firebase
- [x] Key ID et Team ID configurés
- [x] App iOS installée sur l'iPhone
- [x] Backend en cours d'exécution

---

## 🚀 Méthode 1 : Test Manuel via l'API

### Étape 1 : Démarrer le Backend

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node src/app.js
```

**Attendez de voir :**
```
✅ Socket.IO initialisé
🚀 Serveur démarré sur le port 3000
```

### Étape 2 : Vérifier le Token FCM (Nouveau Terminal)

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Vérifier que l'utilisateur 14 a un token
sqlite3 database.sqlite "SELECT id, first_name, fcm_token FROM users WHERE id = 14;"
```

**Résultat attendu :**
```
14|Noel|cv4aheaESSKXzoGOOqmZgO:APA91b...
```

### Étape 3 : Envoyer une Notification de Test

Dans un autre terminal :

```bash
curl -X POST http://localhost:3000/api/test/notification/14 \
  -H "Content-Type: application/json"
```

**Résultat attendu dans le terminal du backend :**
```
🧪 TEST NOTIFICATION pour user 14
   User: Noel Pkanta
   Token: cv4aheaESSKXzoGOOqmZgO...
✅ Notification FCM envoyée avec succès
   Message ID: projects/xxx/messages/yyy
```

### Étape 4 : Vérifier sur l'iPhone

**Si l'app est ouverte :**
- Une popup devrait apparaître en haut : "🧪 Test iOS Notification"

**Si l'app est fermée :**
- Une bannière devrait apparaître sur l'écran d'accueil

**Si l'app est en background :**
- Badge + bannière de notification

---

## 🚀 Méthode 2 : Test Réel via le Dashboard

### Étape 1 : Ouvrir le Dashboard
```
http://localhost:3001
```

### Étape 2 : Créer une Intervention

1. Aller sur **Interventions**
2. **Créer une nouvelle intervention**
3. **Client** : Sélectionner Noel Pkanta (ID: 14)
4. **Technicien** : Assigner n'importe quel technicien
5. **Enregistrer**

### Étape 3 : Vérifier l'iPhone

Une notification devrait arriver :
- **Titre** : "Technicien assigné"
- **Message** : "Un technicien a été assigné à votre intervention"

---

## 🔍 Diagnostic des Problèmes

### Problème 1 : Pas de Notification Reçue

**Vérifier Firebase Console :**
1. https://console.firebase.google.com
2. **Project Settings** → **Cloud Messaging**
3. **Section iOS** → Vérifier que la clé APNs est bien uploadée
4. **Bundle ID** doit être : `com.bassoued.mctMaintenanceMobile`

**Logs à Chercher dans le Backend :**
```
✅ Notification FCM envoyée avec succès
```

**Si vous voyez :**
```
❌ Erreur envoi notification FCM: messaging/invalid-apns-credentials
```
→ La clé APNs est invalide ou mal configurée

**Si vous voyez :**
```
❌ Erreur: messaging/registration-token-not-registered
```
→ Le token FCM a expiré. Désinstallez et réinstallez l'app iOS.

### Problème 2 : Erreur "messaging/third-party-auth-error"

**Solution :**
1. Aller sur Apple Developer : https://developer.apple.com/account
2. Vérifier que Push Notifications est activé pour l'App ID `com.bassoued.mctMaintenanceMobile`
3. **Identifiers** → **App IDs** → Sélectionner votre app
4. ✅ Push Notifications doit être coché

### Problème 3 : Token FCM Null ou Vide

**Dans l'app iOS :**
1. Vérifier les permissions : **Réglages → MCT Maintenance → Notifications**
2. Tout doit être activé
3. Si pas de token après login, désinstallez et réinstallez l'app

---

## 🎯 Checklist Complète

### Configuration Firebase
- [ ] Clé APNs `.p8` uploadée dans Firebase Console
- [ ] Key ID renseigné
- [ ] Team ID renseigné
- [ ] Bundle ID correspond : `com.bassoued.mctMaintenanceMobile`

### Configuration Apple Developer
- [ ] App ID créé : `com.bassoued.mctMaintenanceMobile`
- [ ] Push Notifications activé pour cet App ID
- [ ] Clé APNs générée et téléchargée

### Configuration iOS App (Xcode)
- [ ] Bundle ID : `com.bassoued.mctMaintenanceMobile`
- [ ] Capability : Push Notifications ajoutée
- [ ] Capability : Background Modes → Remote notifications coché
- [ ] GoogleService-Info.plist présent dans `ios/Runner/`

### App Installée sur iPhone
- [ ] App installée depuis Xcode
- [ ] Connexion réussie
- [ ] Permissions notifications accordées
- [ ] Token FCM enregistré en DB

### Backend
- [ ] Firebase Admin SDK initialisé
- [ ] firebase-service-account.json présent
- [ ] Service FCM initialisé
- [ ] Route de test `/api/test/notification/:userId` disponible

---

## 🧪 Script de Test Complet

Créez ce fichier : `test-ios-push.sh`

```bash
#!/bin/bash

echo "🧪 Test des Notifications iOS"
echo "================================"
echo ""

# 1. Vérifier que le backend tourne
echo "1️⃣ Vérification du backend..."
if curl -s http://localhost:3000/health > /dev/null; then
  echo "   ✅ Backend actif"
else
  echo "   ❌ Backend inactif. Lancez: node src/app.js"
  exit 1
fi

# 2. Vérifier le token FCM
echo ""
echo "2️⃣ Vérification du token FCM..."
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
TOKEN=$(sqlite3 database.sqlite "SELECT fcm_token FROM users WHERE id = 14;")

if [ -z "$TOKEN" ]; then
  echo "   ❌ Pas de token FCM pour user 14"
  echo "   → Ouvrez l'app iOS et connectez-vous"
  exit 1
else
  echo "   ✅ Token FCM présent: ${TOKEN:0:30}..."
fi

# 3. Envoyer une notification de test
echo ""
echo "3️⃣ Envoi de la notification de test..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/test/notification/14 \
  -H "Content-Type: application/json")

if echo "$RESPONSE" | grep -q "success.*true"; then
  echo "   ✅ Notification envoyée avec succès"
  echo ""
  echo "🎉 Vérifiez votre iPhone maintenant !"
  echo "   - App ouverte : popup en haut"
  echo "   - App fermée : bannière sur l'écran"
else
  echo "   ❌ Erreur lors de l'envoi"
  echo "   Réponse: $RESPONSE"
fi

echo ""
echo "================================"
```

**Rendre exécutable et lancer :**
```bash
chmod +x test-ios-push.sh
./test-ios-push.sh
```

---

## 📊 Logs à Surveiller

### Dans le Terminal du Backend

**Succès :**
```
✅ Firebase Admin SDK initialisé
✅ Notification FCM envoyée avec succès
   Token: cv4aheaESSKXzoGOOqmZgO...
   Titre: 🧪 Test iOS Notification
   Message ID: projects/xxx/messages/yyy
```

**Échec - Clé APNs Invalide :**
```
❌ Erreur envoi notification FCM: messaging/invalid-apns-credentials
```
→ Vérifier Firebase Console

**Échec - Token Invalide :**
```
❌ Erreur envoi notification FCM: messaging/registration-token-not-registered
```
→ Réinstaller l'app iOS

### Dans Xcode (si connecté)

Ouvrir la Console Xcode et chercher :
```
🔔 [FCM] Permission de notification accordée
📱 [FCM] Token obtenu: cv4aheaESSKXzoGOOqmZgO...
🔔 Notification reçue (foreground)
```

---

## 🆘 Support

Si rien ne fonctionne après tous les tests :

1. **Vérifier le Project ID Firebase**
   - Dashboard Firebase → Project Settings → General
   - Le Project ID doit correspondre à celui dans `firebase-service-account.json`

2. **Télécharger à nouveau GoogleService-Info.plist**
   - Firebase Console → Project Settings → iOS app
   - Télécharger le dernier fichier
   - Remplacer dans `ios/Runner/GoogleService-Info.plist`

3. **Rebuild complet**
   ```bash
   flutter clean
   cd ios
   pod install
   cd ..
   flutter run
   ```

4. **Tester avec Firebase Console directement**
   - Firebase Console → Cloud Messaging
   - **Send test message**
   - Coller le token FCM de l'utilisateur 14
   - Envoyer

Si ça marche depuis Firebase Console mais pas depuis votre backend, le problème est dans le code backend.

---

**Bonne chance ! 🍀📱**
