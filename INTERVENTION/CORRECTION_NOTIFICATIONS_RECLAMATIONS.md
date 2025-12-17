# 🔧 Correction : Notifications de Mise à Jour des Réclamations

## 📋 Problème Identifié

Lorsqu'un administrateur ou technicien modifie une réclamation depuis le dashboard web (description, résolution, priorité, sujet), le client ne recevait **aucune notification** sur son mobile.

### Cause du problème

Le contrôleur `complaintController.js` (route `PUT /api/complaints/:id`) n'envoyait de notification au client **QUE** si le statut changeait. Les autres modifications (résolution, description, priorité, sujet) étaient ignorées.

```javascript
// ❌ AVANT (ligne 299-313)
// Envoyer une notification au client si le statut change
if (updateData.status && updateData.status !== complaint.status) {
  try {
    if (updatedComplaint.customer && updatedComplaint.customer.user) {
      await notifyComplaintStatusChange(
        updatedComplaint, 
        updatedComplaint.customer.user, 
        updateData.status
      );
    }
  } catch (notifError) {
    console.error('Erreur lors de l\'envoi de la notification:', notifError);
  }
}
```

## ✅ Solution Implémentée

### 1. Modification du contrôleur (complaintController.js)

La logique de notification a été étendue pour couvrir **tous les types de modifications significatives** :

```javascript
// ✅ APRÈS
// Envoyer une notification au client
// 1. Si le statut change, notification de changement de statut
// 2. Sinon si d'autres champs changent, notification de réponse/mise à jour
try {
  if (updatedComplaint.customer && updatedComplaint.customer.user) {
    // Notification de changement de statut (prioritaire)
    if (updateData.status && updateData.status !== complaint.status) {
      await notifyComplaintStatusChange(
        updatedComplaint, 
        updatedComplaint.customer.user, 
        updateData.status
      );
      console.log(`✅ Notification changement statut réclamation ${id} vers "${updateData.status}" envoyée`);
    } 
    // Notification de mise à jour générale (si d'autres champs ont changé)
    else if (Object.keys(updateData).length > 0) {
      // Vérifier si des champs importants ont changé
      const hasSignificantChanges = 
        updateData.resolution !== undefined ||
        updateData.description !== undefined ||
        updateData.subject !== undefined ||
        updateData.priority !== undefined;
      
      if (hasSignificantChanges) {
        await notifyComplaintResponse(
          updatedComplaint, 
          updatedComplaint.customer.user
        );
        console.log(`✅ Notification mise à jour réclamation ${id} envoyée au client`);
      }
    }
  }
} catch (notifError) {
  console.error('Erreur lors de l\'envoi de la notification:', notifError);
}
```

### 2. Amélioration du message de notification (notificationHelpers.js)

Le message de la fonction `notifyComplaintResponse` a été rendu plus explicite :

```javascript
// ✅ AVANT
const notifyComplaintResponse = async (complaint, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'complaint_response',
    title: 'Réponse à votre réclamation',
    message: `Une réponse a été ajoutée à votre réclamation`,
    // ...
  });
};

// ✅ APRÈS
const notifyComplaintResponse = async (complaint, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'complaint_response',
    title: 'Mise à jour de votre réclamation',
    message: `Votre réclamation "${complaint.subject}" a été mise à jour`,
    data: {
      complaintId: complaint.id,
      reference: complaint.reference
    },
    // ...
  });
};
```

## 🎯 Cas d'Utilisation Couverts

Désormais, le client reçoit une notification mobile (via FCM) dans les cas suivants :

### 1. Changement de statut
- **Notification** : `notifyComplaintStatusChange`
- **Type** : `complaint_status_change`
- **Exemples** :
  - `open` → `in_progress` : "Réclamation en cours de traitement"
  - `in_progress` → `resolved` : "Réclamation résolue"
  - `open` → `rejected` : "Réclamation rejetée"

### 2. Mise à jour de la résolution
- **Notification** : `notifyComplaintResponse`
- **Type** : `complaint_response`
- **Message** : "Votre réclamation '[sujet]' a été mise à jour"

### 3. Modification de la description
- **Notification** : `notifyComplaintResponse`
- **Type** : `complaint_response`

### 4. Changement de priorité
- **Notification** : `notifyComplaintResponse`
- **Type** : `complaint_response`

### 5. Modification du sujet
- **Notification** : `notifyComplaintResponse`
- **Type** : `complaint_response`

### 6. Ajout d'une note (déjà fonctionnel)
- **Notification** : `notifyComplaintNoteAdded`
- **Type** : `complaint_response`
- **Route** : `POST /api/complaints/:id/notes`

## 🧪 Test de la Correction

Un script de test a été créé : `test-complaint-update-notification.js`

### Utilisation

```bash
cd /Users/bassoued/Documents/MAINTENANCE
node test-complaint-update-notification.js
```

### Ce que le script teste

1. ✅ Trouve une réclamation existante avec un client
2. ✅ Compte les notifications avant la mise à jour
3. ✅ Met à jour la résolution de la réclamation
4. ✅ Déclenche la notification
5. ✅ Vérifie que la notification a bien été créée
6. ✅ Affiche les détails de la notification

## 📱 Test sur Mobile

### 1. Depuis le Dashboard Web

1. Connectez-vous en tant qu'admin/technicien
2. Accédez à une réclamation existante
3. Modifiez la **résolution** ou la **description**
4. Sauvegardez

### 2. Vérification sur Mobile

L'application mobile du client doit recevoir :
- Une notification push FCM
- Type : `complaint_response`
- Titre : "Mise à jour de votre réclamation"
- Message : "Votre réclamation '[sujet]' a été mise à jour"

### 3. Logs à surveiller

Côté API, vous verrez :
```
✅ Notification mise à jour réclamation [ID] envoyée au client
```

## 📊 Architecture des Notifications

```
Dashboard Web (Admin/Tech)
    ↓
    PUT /api/complaints/:id { resolution: "..." }
    ↓
complaintController.updateComplaint()
    ↓
    ├─ Mise à jour en base de données
    ↓
    ├─ Détection des modifications significatives
    ↓
    ├─ notifyComplaintResponse(complaint, customer)
    ↓
    └─ notificationService.create()
        ↓
        ├─ Sauvegarde en base (notifications table)
        ├─ Socket.IO (notifications temps réel web)
        └─ FCM (notification push mobile) ✅
            ↓
        Mobile du client reçoit la notification
```

## 🔍 Points Techniques

### Routes concernées

- **PUT /api/complaints/:id** : Mise à jour générale (maintenant avec notifications)
- **PATCH /api/complaints/:id/status** : Changement de statut uniquement
- **POST /api/complaints/:id/notes** : Ajout de note

### Ordre de priorité des notifications

1. **Changement de statut** → `notifyComplaintStatusChange`
2. **Autres modifications** → `notifyComplaintResponse`

Si le statut ET d'autres champs changent simultanément, seule la notification de changement de statut est envoyée (plus spécifique).

### Champs surveillés pour notification

- `status` ✅
- `resolution` ✅
- `description` ✅
- `subject` ✅
- `priority` ✅

### Champs ignorés (pas de notification)

- `created_at`, `updated_at` (timestamps automatiques)
- Relations (`customerId`, `orderId`, `productId`) - normalement fixes

## 🚀 Déploiement

### 1. Redémarrer l'API

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm run restart
# ou
./restart.sh
```

### 2. Vérifier les logs

```bash
tail -f logs/api.log
```

Recherchez les messages :
- `✅ Notification changement statut réclamation X vers "resolved" envoyée`
- `✅ Notification mise à jour réclamation X envoyée au client`

## ✅ Résultat Final

**AVANT** : Client ne recevait de notification que si le statut changeait

**APRÈS** : Client reçoit une notification pour :
- ✅ Changement de statut
- ✅ Modification de la résolution
- ✅ Modification de la description
- ✅ Modification du sujet
- ✅ Changement de priorité
- ✅ Ajout de note (déjà fonctionnel)

## 📝 Notes

- Les notifications sont envoyées via **Socket.IO** (web) et **FCM** (mobile)
- Le type de notification est `complaint_response` pour les mises à jour générales
- Le type `complaint_status_change` reste spécifique aux changements de statut
- Les erreurs de notification ne bloquent pas la mise à jour (try/catch)

---

**Date de correction** : 4 novembre 2025  
**Fichiers modifiés** :
- `/mct-maintenance-api/src/controllers/complaintController.js`
- `/mct-maintenance-api/src/services/notificationHelpers.js`
