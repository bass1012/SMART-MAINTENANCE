# 🔔 SYSTÈME DE NOTIFICATIONS TECHNICIEN

## 📋 Problème

Le technicien reçoit bien les interventions via l'API, mais **ne reçoit pas de notifications** quand une nouvelle intervention lui est assignée.

---

## ✅ Système Actuel (Backend)

### **Quand une intervention est assignée :**

Le backend crée et envoie **3 types de notifications** :

```
PATCH /api/interventions/:id/assign
  ↓
notifyInterventionAssigned()
  ↓
┌─────────────────────────────────────┐
│ 1. Base de données (Notification)   │ ✅
│ 2. Socket.IO (temps réel web)       │ ✅
│ 3. FCM (push mobile)                │ ⚠️  Nécessite un token
└─────────────────────────────────────┘
```

**Code Backend :**

```javascript
// src/controllers/intervention/interventionController.js
const assignIntervention = async (req, res) => {
  // ... assignation intervention ...
  
  // 🔔 Notifier le technicien
  await notifyInterventionAssigned(updatedIntervention, technician);
};
```

```javascript
// src/services/notificationHelpers.js
const notifyInterventionAssigned = async (intervention, technician) => {
  return await notificationService.create({
    userId: technician.id,
    type: 'intervention_assigned',
    title: 'Nouvelle intervention assignée',
    message: 'Une intervention vous a été assignée',
    data: { interventionId: intervention.id },
    priority: 'high'
  });
};
```

```javascript
// src/services/notificationService.js
async create({ userId, type, title, message, ... }) {
  // 1. Créer en DB
  const notification = await Notification.create({...});
  
  // 2. Envoyer via Socket.IO
  this.io.to(`user:${userId}`).emit('new_notification', {...});
  
  // 3. Envoyer via FCM (si token existe)
  const user = await User.findByPk(userId);
  if (user.fcm_token) {
    await fcmService.sendToDevice(user.fcm_token, {...});
  }
}
```

---

## ❌ Cause du Problème

### **Le token FCM n'est pas enregistré**

```sql
SELECT id, email, role, fcm_token 
FROM users 
WHERE email = 'cissoko@gmail.com';
```

**Résultat :**
```
id | email                | role       | fcm_token
8  | cissoko@gmail.com    | technician | NULL       ❌
```

**Pourquoi `fcm_token` est NULL ?**

Le technicien s'est connecté **avant** qu'on implémente le système FCM dans l'app mobile, donc :
- L'app n'a jamais demandé de permission de notification
- L'app n'a jamais obtenu de token FCM
- L'app n'a jamais envoyé le token au backend

---

## ✅ Solutions

### **Solution 1 : Reconnecter le Technicien (Recommandée)**

C'est la solution la plus simple et rapide.

#### **Étapes :**

1. **Ouvrir l'app mobile**

2. **Se déconnecter** :
   - Aller dans **Paramètres** (icône ⚙️)
   - Cliquer sur **Déconnexion**
   - Confirmer

3. **Se reconnecter** :
   - Email : `cissoko@gmail.com`
   - Mot de passe : `P@ssword` (ou le bon mot de passe)

4. **Vérifier les logs Flutter** :
   ```
   🚀 Initialisation de Firebase...
   ✅ Permission de notification accordée
   📱 FCM Token obtenu: abc123def456...
   📤 Envoi du token FCM au backend...
   ✅ Token FCM enregistré dans le backend
   ✅ FCM initialisé avec succès après login
   ```

5. **Vérifier en base de données** :
   ```sql
   SELECT fcm_token FROM users WHERE id = 8;
   ```
   
   **Résultat attendu :**
   ```
   fcm_token
   ----------------------------------------------------------------
   dGhpc19pc19hX2ZjbV90b2tlbl9leGFtcGxlX2Zvcl9kb2N1bWVudGF0aW9u...  ✅
   ```

---

### **Solution 2 : Forcer l'Initialisation FCM**

Si le technicien ne veut pas se déconnecter, ajoutez un bouton dans les paramètres.

#### **Créer un bouton "Réinitialiser Notifications"**

Dans `/lib/screens/technician/technician_settings_screen.dart` :

```dart
ListTile(
  leading: Icon(Icons.notifications_active),
  title: Text('Réinitialiser les notifications'),
  subtitle: Text('Réactiver les notifications push'),
  onTap: () async {
    try {
      await FCMService().initialize();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Notifications réinitialisées'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
),
```

---

### **Solution 3 : Vérifier les Permissions Android/iOS**

#### **Android :**

1. **Paramètres** → **Applications** → **MCT Maintenance**
2. **Notifications** → Activer toutes les notifications

#### **iOS :**

1. **Réglages** → **Notifications** → **MCT Maintenance**
2. **Autoriser les notifications** → Activé
3. **Sons**, **Badges**, **Bannières** → Activés

---

## 🧪 Test Complet

### **Étape 1 : Vérifier le token enregistré**

```sql
-- Vérifier le token FCM du technicien
SELECT 
  id, 
  email, 
  role, 
  CASE 
    WHEN fcm_token IS NULL THEN '❌ MANQUANT'
    ELSE CONCAT('✅ ', SUBSTRING(fcm_token, 1, 30), '...')
  END as fcm_token_status
FROM users 
WHERE email = 'cissoko@gmail.com';
```

**Résultat attendu :**
```
id | email                | role       | fcm_token_status
8  | cissoko@gmail.com    | technician | ✅ dGhpc19pc19hX2ZjbV90b2tlbl...
```

---

### **Étape 2 : Assigner une intervention**

**Via Dashboard Web :**

1. Se connecter en tant qu'admin
2. **Interventions** → Sélectionner une intervention
3. **Modifier** → Assigner au technicien **Edourd Cissoko**
4. **Enregistrer**

**Logs Backend Attendus :**
```
PATCH /api/interventions/4/assign
📤 Envoi notification assignation au technicien user_id: 8
📬 Notification créée pour user 8: Nouvelle intervention assignée
🔌 Tentative d'envoi Socket.IO à la room "user:8"
👤 1 client(s) connecté(s) dans cette room
🔔 Notification envoyée en temps réel à 1 client(s)
✅ Token FCM enregistré dans le backend
📱 Notification FCM envoyée avec succès
```

---

### **Étape 3 : Vérifier sur l'app mobile**

**L'app mobile doit afficher :**

1. **Notification push Android/iOS** :
   ```
   🔔 Nouvelle intervention assignée
   Une intervention vous a été assignée
   ```

2. **Badge rouge** sur l'icône de l'app

3. **Notification dans la liste** :
   - Onglet **Mes Interventions** → Nouvelle intervention apparaît
   - Badge "Nouveau" ou badge numérique

4. **Centre de notifications** (si implémenté) :
   - Icône cloche avec badge
   - Liste des notifications non lues

---

### **Étape 4 : Vérifier en base de données**

```sql
-- Vérifier les notifications du technicien
SELECT 
  id,
  type,
  title,
  message,
  is_read,
  created_at
FROM notifications
WHERE user_id = 8
ORDER BY created_at DESC
LIMIT 5;
```

**Résultat attendu :**
```
id | type                   | title                         | is_read | created_at
12 | intervention_assigned  | Nouvelle intervention assignée| false   | 2025-10-28 08:45:00
11 | intervention_assigned  | Nouvelle intervention assignée| true    | 2025-10-27 14:30:00
```

---

## 🔍 Diagnostic des Problèmes

### **Problème 1 : Pas de notification push**

**Symptômes :**
- Pas de son
- Pas de notification Android/iOS
- Pas de badge sur l'icône

**Vérifications :**

1. **Token FCM enregistré ?**
   ```sql
   SELECT fcm_token FROM users WHERE id = 8;
   ```
   Si NULL → **Se reconnecter à l'app**

2. **Permissions accordées ?**
   - Android : Paramètres → Apps → MCT Maintenance → Notifications
   - iOS : Réglages → Notifications → MCT Maintenance

3. **Firebase configuré ?**
   - Fichier `google-services.json` (Android)
   - Fichier `GoogleService-Info.plist` (iOS)

4. **Clé serveur FCM valide ?**
   - Backend : Variable `FIREBASE_SERVER_KEY` dans `.env`

---

### **Problème 2 : Notification reçue mais pas affichée**

**Symptômes :**
- Notification en base de données ✅
- Mais pas visible dans l'app mobile ❌

**Vérifications :**

1. **L'écran de notifications existe ?**
   - Vérifier `/lib/screens/technician/notifications_screen.dart`

2. **L'API retourne les notifications ?**
   ```bash
   curl -X GET "http://localhost:3000/api/notifications" \
     -H "Authorization: Bearer TOKEN"
   ```

3. **Socket.IO connecté ?**
   - Logs backend : `✅ Utilisateur 8 authentifié sur socket abc123`

---

### **Problème 3 : Notifications multiples**

**Symptômes :**
- Le technicien reçoit 5 notifications identiques

**Cause :**
- Plusieurs appareils connectés avec le même compte
- Plusieurs tokens FCM enregistrés

**Solution :**
```sql
-- Vérifier les tokens enregistrés
SELECT id, email, fcm_token 
FROM users 
WHERE id = 8;

-- Nettoyer les vieux tokens
UPDATE users 
SET fcm_token = NULL 
WHERE id = 8;

-- Puis se reconnecter à l'app
```

---

## 📊 Architecture Complète

```
┌────────────────────────────────────────────────────────────────┐
│                        DASHBOARD WEB                           │
│  Admin assigne intervention → PATCH /api/interventions/:id     │
└────────────────────────────────────────────────────────────────┘
                                   ↓
┌────────────────────────────────────────────────────────────────┐
│                    BACKEND (Node.js)                           │
│                                                                │
│  interventionController.assignIntervention()                   │
│    ↓                                                           │
│  notifyInterventionAssigned(intervention, technician)          │
│    ↓                                                           │
│  notificationService.create()                                  │
│    ├─→ 1. INSERT INTO notifications (user_id, type, ...)      │
│    ├─→ 2. io.to(`user:8`).emit('new_notification', {...})     │
│    └─→ 3. fcmService.sendToDevice(fcm_token, {...})           │
└────────────────────────────────────────────────────────────────┘
                    ↓                           ↓
    ┌───────────────────────┐   ┌─────────────────────────────┐
    │   Socket.IO (Web)     │   │   FCM (Mobile Push)         │
    │   Dashboard Technicien│   │   Android/iOS Notification  │
    └───────────────────────┘   └─────────────────────────────┘
                                              ↓
                            ┌─────────────────────────────────┐
                            │   APP MOBILE FLUTTER            │
                            │                                 │
                            │  - Notification push affichée   │
                            │  - Son + Vibration              │
                            │  - Badge sur icône              │
                            │  - Ajout à la liste             │
                            └─────────────────────────────────┘
```

---

## 📝 Checklist de Déploiement

Avant de mettre en production, vérifiez :

- [ ] Firebase configuré (google-services.json, GoogleService-Info.plist)
- [ ] Clé serveur FCM dans `.env` backend
- [ ] Permissions Android dans `AndroidManifest.xml`
- [ ] Permissions iOS dans `Info.plist`
- [ ] FCM initialisé au login (`login_form.dart`)
- [ ] FCM initialisé au démarrage si connecté (`splash_screen.dart`)
- [ ] Route API `PATCH /api/auth/fcm-token` fonctionnelle
- [ ] Socket.IO initialisé dans `app.js` backend
- [ ] Notifications créées en base pour chaque événement important
- [ ] Tests sur appareils physiques (Android + iOS)

---

## 🔗 Fichiers Importants

### **Backend :**
- `/src/controllers/intervention/interventionController.js` - Assignation intervention
- `/src/services/notificationHelpers.js` - Helpers de notifications
- `/src/services/notificationService.js` - Service principal (DB, Socket.IO, FCM)
- `/src/services/fcmService.js` - Service Firebase Cloud Messaging
- `/src/routes/interventionRoutes.js` - Routes interventions

### **Mobile :**
- `/lib/services/fcm_service.dart` - Service FCM mobile
- `/lib/services/api_service.dart` - Méthode updateFcmToken()
- `/lib/widgets/auth/login_form.dart` - Initialisation FCM au login
- `/lib/screens/splash_screen.dart` - Initialisation FCM au démarrage
- `/lib/main.dart` - Handler notifications background

---

## ✅ Résumé

**Problème :** Technicien ne reçoit pas de notifications d'assignation

**Cause :** Token FCM non enregistré (connexion avant implémentation du système)

**Solution :** Se déconnecter et se reconnecter à l'app mobile

**Vérification :** 
```sql
SELECT fcm_token FROM users WHERE email = 'cissoko@gmail.com';
-- Doit retourner un token, pas NULL
```

**Test :** Assigner une intervention → Notification push reçue ✅

---

**Fichiers Utiles :**
- 📚 `/NOTIFICATIONS_TECHNICIEN.md` - Ce document
- 🧪 `/test_technicien.sh` - Script de test API
- 🔧 `/DIAGNOSTIC_TECHNICIEN.md` - Diagnostic complet

**Besoin d'aide ?** Vérifiez les logs :
- Backend : `npm start` → Cherchez "📤 Envoi notification"
- Mobile : Flutter logs → Cherchez "🔔 Notification reçue"
