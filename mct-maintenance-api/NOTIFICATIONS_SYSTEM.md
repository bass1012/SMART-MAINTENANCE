# 🔔 Système de Notifications en Temps Réel - MCT Maintenance

## 📋 Vue d'ensemble

Système de notifications bidirectionnel en temps réel utilisant Socket.IO pour le web et Firebase Cloud Messaging (FCM) pour le mobile.

## 🎯 Fonctionnalités

### **Notifications Client → Admin/Techniciens**
- ✅ Nouvelle demande d'intervention
- ✅ Nouvelle réclamation
- ✅ Nouvelle souscription
- ✅ Nouvelle commande
- ✅ Devis accepté/rejeté

### **Notifications Admin/Techniciens → Client**
- ✅ Intervention assignée
- ✅ Intervention terminée
- ✅ Réponse à réclamation
- ✅ Nouveau devis créé
- ✅ Changement de statut de commande
- ✅ Nouveau contrat créé
- ✅ Contrat bientôt expiré
- ✅ Paiement reçu
- ✅ Rapport d'intervention disponible

## 🏗️ Architecture Backend

### **1. Modèle de données (Notification.js)**

```javascript
{
  id: INTEGER,
  user_id: INTEGER,
  type: ENUM(
    'intervention_request',
    'intervention_assigned',
    'intervention_completed',
    'complaint_created',
    'complaint_response',
    'subscription_created',
    'subscription_expiring',
    'order_created',
    'order_status_update',
    'quote_created',
    'quote_accepted',
    'quote_rejected',
    'contract_created',
    'contract_expiring',
    'payment_received',
    'report_submitted',
    'general'
  ),
  title: STRING,
  message: TEXT,
  data: JSON,
  is_read: BOOLEAN,
  read_at: DATE,
  priority: ENUM('low', 'medium', 'high', 'urgent'),
  action_url: STRING,
  created_at: DATE,
  updated_at: DATE
}
```

### **2. Service de notifications (notificationService.js)**

**Méthodes principales:**
- `initialize(io)` - Initialise Socket.IO
- `create(data)` - Crée et envoie une notification
- `createBulk(userIds, data)` - Notifications multiples
- `notifyAdmins(data)` - Notifie tous les admins
- `notifyTechnicians(data)` - Notifie tous les techniciens
- `getUserNotifications(userId, options)` - Liste des notifications
- `getUnreadCount(userId)` - Compte les non lues
- `markAsRead(notificationId)` - Marquer comme lue
- `markAllAsRead(userId)` - Tout marquer comme lu

### **3. Helpers de notifications (notificationHelpers.js)**

Fonctions spécialisées pour chaque type d'événement:
- `notifyNewIntervention(intervention, customer)`
- `notifyInterventionAssigned(intervention, technician)`
- `notifyInterventionCompleted(intervention, customer)`
- `notifyNewComplaint(complaint, customer)`
- `notifyComplaintResponse(complaint, customer)`
- `notifyNewSubscription(subscription, customer, offer)`
- `notifyNewOrder(order, customer)`
- `notifyOrderStatusUpdate(order, customer, newStatus)`
- `notifyNewQuote(quote, customer)`
- `notifyQuoteAccepted/Rejected(quote, customer)`
- `notifyNewContract(contract, customer)`
- `notifyPaymentReceived(payment, customer)`
- `notifyReportSubmitted(report, customer)`

### **4. API Endpoints**

```
GET    /api/notifications              - Liste des notifications
GET    /api/notifications/unread-count - Nombre de non lues
PATCH  /api/notifications/:id/read     - Marquer comme lue
POST   /api/notifications/mark-all-read - Tout marquer comme lu
DELETE /api/notifications/:id          - Supprimer une notification
```

## 🔌 Socket.IO

### **Configuration serveur (app.js)**

```javascript
const io = new Server(server, {
  cors: corsOptions,
  transports: ['websocket', 'polling']
});

notificationService.initialize(io);
```

### **Événements Socket.IO**

**Client → Serveur:**
- `authenticate` - Authentifier l'utilisateur
- `mark_read` - Marquer une notification comme lue
- `mark_all_read` - Tout marquer comme lu

**Serveur → Client:**
- `new_notification` - Nouvelle notification
- `notification_read` - Notification marquée comme lue
- `all_notifications_read` - Toutes marquées comme lues

### **Connexion client (exemple)**

```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3000', {
  transports: ['websocket', 'polling']
});

// Authentification
socket.emit('authenticate', userId);

// Écouter les nouvelles notifications
socket.on('new_notification', (notification) => {
  console.log('Nouvelle notification:', notification);
  // Afficher un toast, mettre à jour le badge, etc.
});
```

## 📱 Intégration Mobile (Flutter)

### **Firebase Cloud Messaging (FCM)**

**Dépendances à ajouter:**
```yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest
```

**Configuration:**
1. Ajouter `google-services.json` (Android)
2. Ajouter `GoogleService-Info.plist` (iOS)
3. Configurer les permissions
4. Enregistrer le token FCM sur le serveur

**Exemple d'implémentation:**
```dart
// Initialiser FCM
await Firebase.initializeApp();
final fcmToken = await FirebaseMessaging.instance.getToken();

// Envoyer le token au serveur
await apiService.updateFcmToken(fcmToken);

// Écouter les notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Afficher une notification locale
  showLocalNotification(message);
});
```

## 🌐 Intégration Dashboard Web (React)

### **Installation**

```bash
cd mct-maintenance-dashboard
npm install socket.io-client
```

### **Service Socket.IO (socketService.ts)**

```typescript
import io from 'socket.io-client';

class SocketService {
  private socket: Socket | null = null;

  connect(userId: number) {
    this.socket = io('http://localhost:3000');
    this.socket.emit('authenticate', userId);
  }

  onNewNotification(callback: (notification: any) => void) {
    this.socket?.on('new_notification', callback);
  }

  disconnect() {
    this.socket?.disconnect();
  }
}

export default new SocketService();
```

### **Composant Notifications (NotificationBell.tsx)**

```tsx
import { Badge, Dropdown, List } from 'antd';
import { BellOutlined } from '@ant-design/icons';

const NotificationBell = () => {
  const [count, setCount] = useState(0);
  const [notifications, setNotifications] = useState([]);

  useEffect(() => {
    // Charger les notifications
    loadNotifications();

    // Écouter les nouvelles
    socketService.onNewNotification((notification) => {
      setNotifications(prev => [notification, ...prev]);
      setCount(prev => prev + 1);
      // Afficher un toast
      message.info(notification.title);
    });
  }, []);

  return (
    <Dropdown overlay={<NotificationList />}>
      <Badge count={count}>
        <BellOutlined style={{ fontSize: 20 }} />
      </Badge>
    </Dropdown>
  );
};
```

## 🔧 Utilisation dans les Contrôleurs

### **Exemple: Nouvelle demande d'intervention**

```javascript
const { notifyNewIntervention } = require('../services/notificationHelpers');

// Dans le contrôleur d'intervention
const createIntervention = async (req, res) => {
  try {
    const intervention = await Intervention.create(req.body);
    const customer = await User.findByPk(req.user.id);

    // Envoyer la notification
    await notifyNewIntervention(intervention, customer);

    res.json({ success: true, data: intervention });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
```

### **Exemple: Changement de statut de commande**

```javascript
const { notifyOrderStatusUpdate } = require('../services/notificationHelpers');

const updateOrderStatus = async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id);
    const customer = await User.findByPk(order.customer_id);

    await order.update({ status: req.body.status });

    // Notifier le client
    await notifyOrderStatusUpdate(order, customer, req.body.status);

    res.json({ success: true, data: order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
```

## 🎨 Types de notifications et priorités

| Type | Priorité | Destinataire | Déclencheur |
|------|----------|--------------|-------------|
| intervention_request | high | Admins | Client crée une demande |
| intervention_assigned | high | Technicien | Admin assigne |
| intervention_completed | medium | Client | Technicien termine |
| complaint_created | high | Admins | Client crée réclamation |
| complaint_response | high | Client | Admin répond |
| subscription_created | medium | Client + Admins | Client souscrit |
| order_created | high | Admins | Client commande |
| order_status_update | medium | Client | Statut change |
| quote_created | high | Client | Admin crée devis |
| quote_accepted | high | Admins | Client accepte |
| contract_created | high | Client | Admin crée contrat |
| payment_received | medium | Client | Paiement confirmé |

## 📊 Statistiques et monitoring

### **Requêtes utiles**

```sql
-- Notifications non lues par utilisateur
SELECT COUNT(*) FROM notifications 
WHERE user_id = ? AND is_read = false;

-- Notifications par type (dernières 24h)
SELECT type, COUNT(*) as count 
FROM notifications 
WHERE created_at > datetime('now', '-1 day')
GROUP BY type;

-- Temps moyen de lecture
SELECT AVG(julianday(read_at) - julianday(created_at)) * 24 as hours
FROM notifications 
WHERE read_at IS NOT NULL;
```

## 🔒 Sécurité

1. **Authentification Socket.IO** - Vérifier le token JWT
2. **Autorisation** - Vérifier que l'utilisateur peut voir la notification
3. **Rate limiting** - Limiter le nombre de notifications
4. **Validation** - Valider toutes les données entrantes

## 🚀 Prochaines étapes

1. ✅ Backend Socket.IO configuré
2. ✅ Service de notifications créé
3. ✅ Helpers de notifications implémentés
4. ⏳ Intégrer Socket.IO dans le dashboard web
5. ⏳ Créer l'interface de notifications web
6. ⏳ Configurer FCM pour le mobile
7. ⏳ Ajouter les déclencheurs dans tous les contrôleurs
8. ⏳ Tests end-to-end

## 📝 Notes

- Les notifications sont stockées en base de données pour l'historique
- Socket.IO assure la livraison en temps réel si l'utilisateur est connecté
- FCM assure la livraison même si l'app mobile est fermée
- Les notifications non lues sont chargées au démarrage de l'application
