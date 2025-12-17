# 🔔 Correction : Messages de Notification Différents pour Client et Technicien

## Problème Signalé

Lors de l'assignation d'un technicien à une intervention :
- ❌ Le **client** recevait le même message que le **technicien**
- ❌ Message incorrect : *"Nouvelle intervention assignée - Une intervention vous a été assignée"*
- ✅ **Attendu** : Messages distincts et appropriés pour chaque rôle

---

## Solution Implémentée

### **1. Nouvelle Fonction de Notification pour le Client**

**Fichier :** `src/services/notificationHelpers.js`

```javascript
// Notification: Technicien assigné à l'intervention (pour le client)
const notifyTechnicianAssignedToCustomer = async (intervention, customer, technician) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'technician_assigned',
    title: 'Technicien assigné',
    message: `${technician.first_name} ${technician.last_name} a été assigné à votre intervention`,
    data: {
      interventionId: intervention.id,
      technicianId: technician.id,
      technicianName: `${technician.first_name} ${technician.last_name}`
    },
    priority: 'high',
    actionUrl: `/interventions`
  });
};
```

### **2. Intégration dans le Contrôleur**

**Fichier :** `src/controllers/intervention/interventionController.js`

**Fonction :** `assignTechnicianToIntervention()`

```javascript
// 🔔 Notifier le technicien de l'assignation
await notifyInterventionAssigned(updatedIntervention, technician);

// 🔔 Notifier le client de l'assignation du technicien
const customer = updatedIntervention.customer;
if (customer) {
  await notifyTechnicianAssignedToCustomer(updatedIntervention, customer, technician);
}
```

### **3. Nouveau Type de Notification**

**Fichier :** `src/models/Notification.js`

Ajout du type `'technician_assigned'` dans l'ENUM :

```javascript
type: DataTypes.ENUM(
  'intervention_request',
  'intervention_assigned',      // Pour le technicien
  'technician_assigned',        // Pour le client ✅ NOUVEAU
  'intervention_completed',
  // ...
)
```

### **4. Migration de Base de Données**

**Fichier créé :** `migrations/add_technician_assigned_notification_type.sql`

Recréation de la table `notifications` avec le nouveau type.

**Script d'exécution :** `run-notification-migration.js`

---

## Comparaison Avant/Après

### **Avant (❌ Incorrect)**

| Destinataire | Message Reçu |
|--------------|--------------|
| **Technicien** | "Nouvelle intervention assignée - Une intervention vous a été assignée" |
| **Client** | "Nouvelle intervention assignée - Une intervention vous a été assignée" ❌ |

### **Après (✅ Correct)**

| Destinataire | Notification | Message |
|--------------|--------------|---------|
| **Technicien** | `intervention_assigned` | "Nouvelle intervention assignée - Une intervention vous a été assignée" |
| **Client** | `technician_assigned` | "Technicien assigné - [Nom du technicien] a été assigné à votre intervention" ✅ |

---

## Flux de Notification

```
┌─────────────────────────────────────┐
│ Admin assigne technicien            │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ assignTechnicianToIntervention()    │
└─────────────┬───────────────────────┘
              │
              ├──────────────────────────┐
              │                          │
              ▼                          ▼
┌─────────────────────────┐  ┌─────────────────────────┐
│ Notification Technicien │  │ Notification Client     │
│                         │  │                         │
│ Type: intervention_     │  │ Type: technician_       │
│       assigned          │  │       assigned          │
│                         │  │                         │
│ Message:                │  │ Message:                │
│ "Une intervention vous  │  │ "[Nom] a été assigné    │
│  a été assignée"        │  │  à votre intervention"  │
│                         │  │                         │
│ Canaux:                 │  │ Canaux:                 │
│ - DB                    │  │ - DB                    │
│ - Socket.IO             │  │ - Socket.IO             │
│ - FCM Push              │  │ - FCM Push              │
└─────────────────────────┘  └─────────────────────────┘
```

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `notificationHelpers.js` | Ajout fonction `notifyTechnicianAssignedToCustomer()` |
| `interventionController.js` | Appel de la nouvelle fonction pour notifier le client |
| `Notification.js` | Ajout type `'technician_assigned'` dans l'ENUM |

## Fichiers Créés

| Fichier | Description |
|---------|-------------|
| `migrations/add_technician_assigned_notification_type.sql` | Migration SQL pour ajouter le type |
| `run-notification-migration.js` | Script d'exécution de la migration |
| `NOTIFICATION_CLIENT_ASSIGNATION.md` | Documentation de la correction |

---

## Instructions de Déploiement

### **1. Exécuter la Migration**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node run-notification-migration.js
```

**Output attendu :**
```
🔄 Exécution de la migration pour ajouter le type "technician_assigned"...

📝 Exécution: CREATE TABLE notifications_new...
📝 Exécution: INSERT INTO notifications_new...
📝 Exécution: DROP TABLE notifications...
📝 Exécution: ALTER TABLE notifications_new RENAME TO notif...
📝 Exécution: CREATE INDEX idx_notifications_user_id ON not...

✅ Migration réussie !

📊 Vérification de la table notifications...

📈 Types de notifications dans la base:
   - intervention_request: 5 notification(s)
   - intervention_assigned: 3 notification(s)

🎉 Migration terminée avec succès !
```

### **2. Redémarrer le Backend**

```bash
npm start
```

### **3. Tester l'Assignation**

**Via le dashboard web admin :**
1. Créer une nouvelle intervention (ou utiliser une existante)
2. Assigner un technicien
3. Vérifier les notifications :
   - Technicien reçoit : "Une intervention vous a été assignée"
   - Client reçoit : "[Nom du technicien] a été assigné à votre intervention"

---

## Logs de Vérification

**Backend (lors de l'assignation) :**
```
📤 Envoi notification assignation au technicien user_id: 15
✅ Notification envoyée au technicien pour l'assignation
📤 Envoi notification assignation au client user_id: 9
✅ Notification envoyée au client pour l'assignation du technicien
```

**Mobile (notification push) :**
```
Technicien:
🔔 Notification reçue
   Titre: "Nouvelle intervention assignée"
   Message: "Une intervention vous a été assignée"

Client:
🔔 Notification reçue
   Titre: "Technicien assigné"
   Message: "Hamed OUATTARA a été assigné à votre intervention"
```

---

## Tests à Effectuer

### **Test 1 : Assignation d'un Technicien**

**Préconditions :**
- 1 intervention en statut `pending` ou `assigned`
- 1 technicien disponible
- Client et technicien connectés sur mobile

**Actions :**
1. Admin assigne le technicien à l'intervention
2. Vérifier notification technicien
3. Vérifier notification client

**Résultats Attendus :**
- ✅ Technicien : "Une intervention vous a été assignée"
- ✅ Client : "[Nom] a été assigné à votre intervention"

### **Test 2 : Création avec Technicien Assigné**

**Actions :**
1. Admin crée une intervention en assignant directement un technicien
2. Vérifier les notifications

**Résultats Attendus :**
- ✅ Admin reçoit : "Nouvelle demande d'intervention"
- ✅ Technicien reçoit : "Une intervention vous a été assignée"
- ✅ Client reçoit : "[Nom] a été assigné à votre intervention"

---

## Types de Notifications (Mise à Jour)

| Type | Destinataire | Titre | Message |
|------|--------------|-------|---------|
| `intervention_request` | Admins | "Nouvelle demande d'intervention" | "[Client] a créé une demande d'intervention" |
| `intervention_assigned` | Technicien | "Nouvelle intervention assignée" | "Une intervention vous a été assignée" |
| `technician_assigned` | Client ✨ | "Technicien assigné" | "[Technicien] a été assigné à votre intervention" |
| `intervention_completed` | Client | "Intervention terminée" | "Votre intervention a été terminée avec succès" |
| `report_submitted` | Client + Admins | "Rapport d'intervention disponible" | "Le rapport de votre intervention est disponible" |

---

## Date de Résolution

**30 octobre 2025**

---

**Statut :** ✅ Corrigé et prêt pour déploiement
