# 🧪 Test Manuel des Notifications de Chat

## ❌ Problème Actuel : Pas de Notifications

### 🔍 Diagnostic Effectué

1. ✅ **Code Backend** : Correct, les notifications sont appelées
2. ✅ **Code Dashboard** : Toast configuré correctement
3. ❌ **Tokens FCM** : **AUCUN utilisateur n'a de token FCM enregistré**
4. ❌ **FCM Mobile** : Erreur lors de l'obtention du token iOS

---

## 📱 Résultat Attendu vs Réalité

### Pour les Notifications Push (Mobile)
❌ **NE FONCTIONNERA PAS** actuellement car:
- Aucun token FCM dans la base de données
- L'app mobile ne parvient pas à obtenir le token FCM
- Erreur: `[firebase_messaging/unknown] An unknown error has occurred`

**Raisons possibles:**
1. **Simulateur iOS** : FCM ne fonctionne PAS sur simulateur, nécessite un appareil physique
2. **Certificats APNs** : Manquants ou mal configurés dans Firebase Console
3. **GoogleService-Info.plist** : Peut-être manquant ou mal configuré

### Pour les Notifications Toast (Dashboard)
✅ **DEVRAIT FONCTIONNER** car ne nécessite pas FCM

---

## 🧪 Test 1 : Notifications Toast Dashboard (Admin)

### Prérequis
- Dashboard ouvert et connecté en tant qu'admin
- Client mobile connecté OU utiliser le test ci-dessous

### Étapes
1. **Ouvrir le dashboard** : http://localhost:3001
2. **Se connecter** comme admin
3. **Aller dans Chat** (menu de gauche)
4. **NE PAS sélectionner** de conversation
5. **Depuis l'app mobile**, envoyer un message

OU

1. **Ouvrir 2 onglets** du dashboard
2. **Onglet 1** : Se connecter comme admin, aller dans Chat, **ne pas sélectionner** de conversation
3. **Onglet 2** : Ouvrir la console navigateur (F12)
4. **Dans la console de l'onglet 2**, exécuter :
```javascript
// Simuler un message client
const socket = io('http://localhost:3000');
socket.emit('chat:authenticate', { userId: 14 });
setTimeout(() => {
  socket.emit('chat:send_message', {
    message: 'Test de notification toast',
    sender_role: 'customer'
  });
}, 2000);
```

### Résultat Attendu
- ✅ Toast apparaît en haut à droite de l'onglet 1
- ✅ Message : "💬 [Nom Client]: Test de notification toast"
- ✅ Badge augmente sur l'avatar du client
- ✅ Cliquable pour ouvrir la conversation

---

## 🧪 Test 2 : Vérifier les Logs Backend

### Étapes
1. **Terminal backend** : Regarder les logs en temps réel
2. **Depuis mobile ou dashboard**, envoyer un message

### Logs Attendus

**Quand un CLIENT envoie un message :**
```
⚠️  [Chat] Aucun admin avec FCM token trouvé
```
OU (si un admin avait un token)
```
📱 [Chat] Notification envoyée à 1 admin(s)
```

**Quand un ADMIN envoie un message :**
```
⚠️  [Chat] Pas de FCM token pour l'utilisateur 14
```
OU (si le client avait un token)
```
📱 [Chat] Notification envoyée à l'utilisateur 14
```

---

## 🛠️ Solutions pour Activer les Notifications Push

### Solution 1 : Tester sur un Appareil iOS Physique

1. **Brancher un iPhone/iPad** réel
2. **Rebuild l'app** :
   ```bash
   cd mct_maintenance_mobile
   flutter run -d [DEVICE_ID]
   ```
3. **Se connecter** dans l'app
4. **Vérifier les logs** : Le token FCM devrait s'afficher
5. **Vérifier la DB** :
   ```sql
   SELECT id, email, fcm_token FROM users WHERE id = 14;
   ```

### Solution 2 : Configurer les Certificats APNs (pour iOS)

1. **Apple Developer Console** :
   - Aller dans Certificates, Identifiers & Profiles
   - Créer un certificat APNs (Push Notifications)
   - Télécharger le fichier .p12

2. **Firebase Console** :
   - Aller dans Project Settings → Cloud Messaging
   - Onglet "Apple app configuration"
   - Upload le certificat APNs .p12

3. **Rebuild l'app**

### Solution 3 : Tester Manuellement avec un Token FCM

1. **Obtenir un token FCM** depuis un appareil réel
2. **L'insérer manuellement** dans la DB :
   ```bash
   cd mct-maintenance-api
   sqlite3 database.sqlite
   ```
   ```sql
   UPDATE users 
   SET fcm_token = 'VOTRE_TOKEN_FCM_ICI' 
   WHERE id = 14; -- ID du client
   ```
3. **Tester** : Envoyer un message depuis le dashboard

### Solution 4 : Utiliser l'Endpoint de Test

```bash
# Tester l'envoi FCM manuellement
curl -X POST http://localhost:3000/api/test-notification/send/14 \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test",
    "message": "Message de test"
  }'
```

---

## 📊 Checklist de Validation

### Notifications Toast (Dashboard)
- [ ] Dashboard ouvert en tant qu'admin
- [ ] Chat page ouverte
- [ ] Aucune conversation sélectionnée
- [ ] Message client envoyé
- [ ] Toast apparaît en haut à droite
- [ ] Badge augmente
- [ ] Clic sur toast ouvre la conversation

### Notifications Push (Mobile) - À faire APRÈS avoir un token FCM
- [ ] App installée sur appareil physique (pas simulateur)
- [ ] Permissions notifications activées
- [ ] Token FCM obtenu et affiché dans les logs
- [ ] Token FCM enregistré dans la DB
- [ ] Message envoyé depuis dashboard
- [ ] Notification push reçue sur mobile
- [ ] Son et vibration
- [ ] Clic ouvre l'app

---

## 🔍 Commandes de Diagnostic

### Vérifier les Tokens FCM dans la DB
```bash
cd mct-maintenance-api
sqlite3 database.sqlite "SELECT id, email, role, SUBSTR(fcm_token, 1, 30) as token_preview FROM users WHERE fcm_token IS NOT NULL;"
```

### Voir les Logs Backend en Temps Réel
```bash
cd mct-maintenance-api
npm start | grep -E "(Chat|FCM|📱)"
```

### Voir les Logs Mobile en Temps Réel
```bash
cd mct_maintenance_mobile
flutter run | grep -E "(FCM|Token|📱|🔔)"
```

### Tester la Connexion Socket.IO
```javascript
// Dans la console du dashboard
console.log('Socket connecté:', window.io !== undefined);
```

---

## 📝 Résumé

| Fonctionnalité | État | Raison |
|---------------|------|--------|
| Code Backend | ✅ OK | Notifications implémentées |
| Code Dashboard | ✅ OK | Toast configuré |
| Code Mobile | ✅ OK | FCM configuré |
| Toast Dashboard | ⚠️ À tester | Devrait fonctionner |
| Push Mobile | ❌ Bloqué | Pas de token FCM |
| Token FCM iOS | ❌ Erreur | Simulateur ou certificats manquants |

---

## 🎯 Prochaines Étapes

1. **Tester les notifications toast** sur le dashboard (devrait fonctionner)
2. **Obtenir un appareil iOS physique** pour tester les push notifications
3. **Configurer les certificats APNs** dans Firebase Console
4. **Rebuild et tester** sur l'appareil réel
5. **Vérifier que le token est bien enregistré** dans la DB

---

**Date** : 6 novembre 2025  
**Status** : En attente de tests et configuration FCM iOS
