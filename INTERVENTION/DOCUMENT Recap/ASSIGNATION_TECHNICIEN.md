# ✅ Système d'Assignation de Technicien - CORRIGÉ

## 🎯 Problème résolu

**Avant :** La fonction `assignIntervention` n'était pas implémentée (retournait seulement "To be implemented")

**Après :** Fonction complète avec assignation + notification automatique au technicien

---

## 📡 API Endpoint

### **POST /api/interventions/:id/assign**

**Authentification :** Requise (JWT)  
**Rôles autorisés :** `admin`, `technician`

**Body :**
```json
{
  "technician_id": 123
}
```

**Réponse succès (200) :**
```json
{
  "success": true,
  "message": "Technicien assigné avec succès",
  "data": {
    "id": 456,
    "title": "Maintenance climatisation",
    "description": "...",
    "customer_id": 789,
    "technician_id": 123,
    "status": "assigned",
    "scheduled_date": "2025-10-28",
    "scheduled_time": "14:00",
    "customer": {
      "id": 789,
      "first_name": "Jean",
      "last_name": "Dupont",
      "email": "jean.dupont@example.com"
    },
    "technician": {
      "id": 123,
      "first_name": "Ahmed",
      "last_name": "Diallo",
      "email": "ahmed.diallo@mct.com"
    }
  }
}
```

---

## 🔔 Système de Notification

### **1. Notification en base de données**
Créée automatiquement dans la table `notifications` :
```sql
INSERT INTO notifications (
  user_id,          -- ID du technicien
  type,             -- 'intervention_assigned'
  title,            -- 'Nouvelle intervention assignée'
  message,          -- 'Une intervention vous a été assignée'
  data,             -- JSON avec interventionId
  priority,         -- 'high'
  action_url,       -- '/interventions'
  is_read,          -- false
  created_at,
  updated_at
)
```

### **2. Notification temps réel (Socket.IO)**
Envoyée instantanément si le technicien est connecté :
```javascript
// Room: user:123
io.to(`user:${technician_id}`).emit('new_notification', {
  id: notification.id,
  type: 'intervention_assigned',
  title: 'Nouvelle intervention assignée',
  message: 'Une intervention vous a été assignée',
  data: { interventionId: 456 },
  priority: 'high',
  action_url: '/interventions',
  created_at: '2025-10-27T17:45:00.000Z',
  is_read: false,
  user_id: 123
});
```

### **3. Notification push mobile (FCM)**
Si le technicien a un `fcm_token` enregistré :
```javascript
fcmService.sendToDevice(
  user.fcm_token,
  {
    title: 'Nouvelle intervention assignée',
    body: 'Une intervention vous a été assignée'
  },
  {
    type: 'intervention_assigned',
    actionUrl: '/interventions',
    notificationId: notification.id.toString(),
    interventionId: '456'
  }
);
```

---

## 📱 Intégration Mobile Flutter

### **Enregistrement du FCM Token**

L'application mobile doit enregistrer son token FCM lors de la connexion :

```dart
// Dans api_service.dart
Future<void> updateFcmToken(String fcmToken) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token');
  
  final response = await _client.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    },
    body: json.encode({'fcm_token': fcmToken}),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Erreur lors de l\'enregistrement du token FCM');
  }
}
```

### **Initialisation Firebase Cloud Messaging**

```dart
// Dans main.dart ou login_screen.dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Après la connexion réussie
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null) {
  await _apiService.updateFcmToken(fcmToken);
}

// Écouter les notifications en foreground
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('📬 Notification reçue: ${message.notification?.title}');
  
  // Afficher une notification locale ou un SnackBar
  if (message.notification != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification!.body ?? ''),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            // Navigation vers l'écran des interventions
            Navigator.pushNamed(context, '/technician/interventions');
          },
        ),
      ),
    );
  }
});
```

---

## 🔧 Fonctionnement Complet

### **Étape 1 : Admin assigne un technicien**
```javascript
// Dashboard Web React
const assignTechnician = async (interventionId, technicianId) => {
  const response = await axios.post(
    `http://localhost:3000/api/interventions/${interventionId}/assign`,
    { technician_id: technicianId },
    {
      headers: { Authorization: `Bearer ${token}` }
    }
  );
  return response.data;
};
```

### **Étape 2 : Backend traite l'assignation**
```javascript
// interventionController.js
1. Vérifie que l'intervention existe
2. Vérifie que le technicien existe (rôle = 'technician')
3. Met à jour l'intervention:
   - technician_id = 123
   - status = 'assigned'
4. Crée notification en DB
5. Envoie Socket.IO (si connecté)
6. Envoie FCM push (si fcm_token existe)
```

### **Étape 3 : Technicien reçoit la notification**

**A. Sur Dashboard Web (si connecté) :**
- 🔔 Badge notification apparaît
- Dropdown affiche la notification
- Toast popup s'affiche

**B. Sur Mobile Flutter (si app ouverte) :**
- 📱 Notification foreground s'affiche
- SnackBar avec bouton "Voir"

**C. Sur Mobile Flutter (app fermée) :**
- 📱 Notification push système
- Clic ouvre l'app → Écran interventions

---

## 🧪 Test de l'Assignation

### **Test 1 : Via cURL**
```bash
# 1. Login admin
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@mct.com","password":"admin123"}' \
  | jq -r '.token')

# 2. Créer une intervention
INTERVENTION_ID=$(curl -X POST http://localhost:3000/api/interventions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Maintenance test",
    "description": "Test assignation",
    "customer_id": 1,
    "scheduled_date": "2025-10-28",
    "scheduled_time": "14:00"
  }' | jq -r '.data.id')

# 3. Assigner un technicien
curl -X POST http://localhost:3000/api/interventions/$INTERVENTION_ID/assign \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"technician_id": 2}'
```

### **Test 2 : Via Dashboard Web**
```
1. Se connecter en tant qu'admin
2. Aller dans "Interventions"
3. Cliquer sur une intervention "pending"
4. Sélectionner un technicien dans le dropdown
5. Cliquer "Assigner"
6. ✅ Vérifier que le technicien reçoit la notification
```

### **Test 3 : Via Mobile**
```
1. Lancer l'app mobile (technicien)
2. Sur le dashboard web, assigner une intervention au technicien
3. ✅ Vérifier que la notification apparaît sur l'app mobile
```

---

## 📊 Logs Backend

Lors d'une assignation réussie, vous devriez voir :

```
📤 Envoi notification assignation au technicien user_id: 123
📬 Notification créée pour user 123: Nouvelle intervention assignée
🔌 Tentative d'envoi Socket.IO à la room "user:123"
👤 1 client(s) connecté(s) dans cette room
🔔 Notification envoyée en temps réel à 1 client(s) de user 123
✅ Notification envoyée au technicien pour l'assignation
```

Si le technicien n'est pas connecté :
```
⚠️  Aucun client connecté pour user 123, notification stockée uniquement en DB
```

Si FCM échoue (normal en dev) :
```
⚠️  Erreur envoi FCM (ignorée): Firebase non initialisé
```

---

## 🔍 Vérification Manuelle

### **1. Vérifier en base de données**
```sql
-- Vérifier l'intervention
SELECT id, title, customer_id, technician_id, status 
FROM interventions 
WHERE id = 456;

-- Vérifier la notification
SELECT user_id, type, title, message, is_read, created_at
FROM notifications
WHERE user_id = 123
ORDER BY created_at DESC
LIMIT 1;

-- Vérifier le FCM token du technicien
SELECT id, email, role, fcm_token
FROM users
WHERE id = 123;
```

### **2. Vérifier les logs serveur**
```bash
# Démarrer le serveur avec logs détaillés
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Ou avec PM2
pm2 logs mct-maintenance-api
```

---

## ✅ Résultat Final

**Statut :** ✅ **FONCTIONNEL**

- ✅ Assignation de technicien implémentée
- ✅ Notification en DB créée
- ✅ Socket.IO envoyé (si connecté)
- ✅ FCM push prêt (nécessite config Firebase)
- ✅ API endpoint testé
- ✅ Logs détaillés

**Pour que le technicien reçoive les notifications push mobile :**
1. Configurer Firebase dans le projet Flutter
2. Enregistrer le FCM token après login
3. L'app recevra automatiquement les notifications

---

## 📝 Notes Importantes

1. **FCM Token** : Le technicien doit se connecter au moins une fois avec l'app mobile pour enregistrer son token
2. **Socket.IO** : Fonctionne uniquement si le technicien est connecté au dashboard web ou mobile
3. **Base de données** : Les notifications sont TOUJOURS sauvegardées, même si l'envoi temps réel échoue
4. **Statut** : L'intervention passe automatiquement de `pending` à `assigned`

