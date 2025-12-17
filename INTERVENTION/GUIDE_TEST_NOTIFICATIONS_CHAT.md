# Guide de Test - Notifications de Chat

## 🎯 Fonctionnalités Implémentées

### Backend (Node.js)
- ✅ Envoi automatique de notifications push FCM quand un message est envoyé
- ✅ Client → Admin : Notification à tous les admins avec FCM token
- ✅ Admin → Client : Notification au client spécifique avec FCM token
- ✅ Format de notification : `{title, body}` + `{type: 'chat', sender_id, message_id}`

### Dashboard Web (Admin)
- ✅ Notifications toast (react-toastify) quand un message client arrive
- ✅ Affiche : nom du client + aperçu du message (50 caractères)
- ✅ Cliquable : ouvre la conversation au clic
- ✅ Position : top-right, durée 5 secondes

### Mobile (Flutter - Client)
- ✅ Notifications FCM natives avec son et vibration
- ✅ Canal spécial "Messages" pour les notifications de chat
- ✅ Gestion foreground/background/terminated
- ✅ Navigation vers le chat au clic sur la notification

---

## 📝 Scénarios de Test

### Test 1 : Client → Admin (Push Mobile)
1. **Ouvrir l'app mobile** sur iPhone (client connecté)
2. **Fermer l'app** ou la mettre en arrière-plan
3. **Sur le dashboard**, aller dans Chat et envoyer un message au client
4. **Vérifier** : 
   - ✅ Notification push reçue sur iPhone
   - ✅ Titre : "Nouveau message"
   - ✅ Corps : contenu du message (max 100 caractères)
   - ✅ Son et vibration

### Test 2 : Client → Admin (Toast Dashboard)
1. **Ouvrir le dashboard** (admin connecté)
2. **Ne PAS sélectionner** la conversation du client test
3. **Sur mobile**, envoyer un message via le chat
4. **Vérifier sur dashboard** :
   - ✅ Toast apparaît en haut à droite
   - ✅ Format : "💬 [Nom Client]: [message...]"
   - ✅ Cliquable pour ouvrir la conversation
   - ✅ Badge count augmente

### Test 3 : Admin → Client (Push Mobile)
1. **Fermer l'app mobile** (ou arrière-plan)
2. **Sur dashboard**, sélectionner une conversation client
3. **Envoyer un message** au client
4. **Vérifier sur mobile** :
   - ✅ Notification push reçue
   - ✅ Titre : "Nouveau message"
   - ✅ Corps : message de l'admin
   - ✅ Cliquer ouvre l'app sur le chat

### Test 4 : Multiple Admins
1. **Se connecter avec 2 comptes admin** sur 2 navigateurs
2. **Sur mobile**, envoyer un message client
3. **Vérifier** :
   - ✅ Les 2 admins reçoivent le toast
   - ✅ Les 2 admins voient le badge augmenter
   - ✅ Si un admin a l'app mobile, il reçoit la push

### Test 5 : Conversation Active (Pas de Notification)
1. **Sur dashboard**, sélectionner une conversation client
2. **Sur mobile**, ce client envoie un message
3. **Vérifier** :
   - ✅ Message apparaît dans le chat immédiatement
   - ✅ AUCUN toast n'apparaît (conversation déjà active)
   - ✅ Badge ne change pas

---

## 🔍 Vérifications Console

### Backend
```bash
# Quand un client envoie un message
📱 [Chat] Notification envoyée à X admin(s)

# Quand un admin envoie un message
📱 [Chat] Notification envoyée à l'utilisateur 123

# Si pas de token FCM
⚠️  [Chat] Pas de FCM token pour l'utilisateur 123
```

### Mobile (Flutter)
```bash
🔔 Notification reçue (foreground)
   Titre: Nouveau message
   Message: Contenu du message...
   Data: {type: chat, sender_id: 1, ...}
```

### Dashboard (Console navigateur)
```javascript
// Toast apparaît automatiquement, pas de log spécial
```

---

## 🛠️ Dépannage

### Pas de notification sur mobile
1. **Vérifier les permissions** : Paramètres → Notifications → MCT Maintenance
2. **Vérifier le token FCM** : Console mobile au démarrage
3. **Vérifier le backend** : Token FCM enregistré dans la DB ?
   ```sql
   SELECT id, email, fcm_token FROM users WHERE id = [USER_ID];
   ```

### Pas de toast sur dashboard
1. **Vérifier ToastContainer** : Doit être présent dans App.tsx
2. **Ouvrir la console** navigateur : Erreurs React ?
3. **Vérifier la connexion Socket.IO** : Badge fonctionne ?

### Notification mais pas de son
1. **Mobile** : Vérifier le mode silencieux et les paramètres système
2. **iOS** : Le son peut être désactivé dans les paramètres de notification
3. **Android** : Vérifier les paramètres du canal "Messages"

---

## 📊 Logs à Surveiller

### Serveur Backend
```bash
npm start

# Doit afficher :
✅ Socket.IO initialisé
🔥 Firebase Cloud Messaging initialisé
📱 [Chat] Notification envoyée à...
```

### Dashboard
```bash
npm start

# Console navigateur :
✅ Socket.IO connecté
🔔 Nouveau message reçu
```

### Mobile
```bash
flutter run

# Console :
🔔 [FCM] Initialisation terminée avec succès
📱 [FCM] Token obtenu: abc123...
✅ [FCM->Backend] Token FCM enregistré dans le backend
```

---

## 🎉 Résultat Attendu

### Scénario Complet
1. **Client mobile** envoie "Bonjour, j'ai un problème"
2. **Admin dashboard** (non sur la conversation) :
   - Toast apparaît : "💬 Jean Dupont: Bonjour, j'ai un problème"
   - Badge affiche "1"
3. **Admin clique** sur le toast
4. **Dashboard** ouvre la conversation
5. **Badge** se remet à 0
6. **Admin répond** : "Bonjour, que puis-je faire pour vous ?"
7. **Client mobile** (en arrière-plan) :
   - Notification push avec son et vibration
   - Titre : "Nouveau message"
   - Message : "Bonjour, que puis-je faire pour vous ?"
8. **Client clique** sur la notification
9. **App mobile** s'ouvre sur le chat

---

## 📱 Données de Notification

### Format Backend → Mobile
```json
{
  "notification": {
    "title": "Nouveau message",
    "body": "Contenu du message..."
  },
  "data": {
    "type": "chat",
    "sender_id": "1",
    "sender_role": "admin",
    "message_id": "456"
  }
}
```

### Format Toast Dashboard
```typescript
toast.info(`💬 ${clientName}: ${message.substring(0, 50)}...`, {
  position: 'top-right',
  autoClose: 5000,
  onClick: () => setSelectedUserId(senderId)
});
```

---

## ✅ Checklist de Validation

- [ ] Client → Admin : Toast dashboard fonctionne
- [ ] Client → Admin : Badge count augmente
- [ ] Admin → Client : Push mobile reçue
- [ ] Admin → Client : Son et vibration
- [ ] Clic sur toast ouvre la conversation
- [ ] Clic sur push mobile ouvre l'app
- [ ] Conversation active = pas de notification
- [ ] Multiple admins reçoivent tous les notifications
- [ ] Token FCM enregistré dans la DB
- [ ] Logs backend confirment l'envoi

---

**Date de création** : 6 novembre 2025  
**Dernière mise à jour** : 6 novembre 2025
