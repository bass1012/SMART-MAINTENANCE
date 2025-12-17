# 📱 Types de Notifications - Réclamations Client

## Vue d'Ensemble

Ce document liste tous les types de notifications qu'un client peut recevoir concernant ses réclamations.

---

## 1️⃣ Nouvelle Réclamation (Admin/Tech)

**Quand** : Client crée une nouvelle réclamation

**Destinataires** : Admins et Techniciens

**Type** : `complaint_created`

```json
{
  "type": "complaint_created",
  "title": "Nouvelle réclamation",
  "message": "[Client] a créé une réclamation",
  "priority": "high",
  "actionUrl": "/reclamations/{id}"
}
```

**Exemple mobile** :
```
🔔 MCT Maintenance

Nouvelle réclamation
Jean Dupont a créé une réclamation

Il y a 2 minutes
```

---

## 2️⃣ Changement de Statut

**Quand** : Admin/Tech change le statut de la réclamation

**Destinataire** : Client (propriétaire de la réclamation)

**Type** : `complaint_status_change`

**Route API** : `PATCH /api/complaints/:id/status`

### Variantes selon le statut

#### 2.1 Open (Enregistrée)
```json
{
  "title": "Réclamation enregistrée",
  "message": "Votre réclamation a été enregistrée et sera traitée prochainement",
  "priority": "medium"
}
```

#### 2.2 In Progress (En cours)
```json
{
  "title": "Réclamation en cours de traitement",
  "message": "Votre réclamation est en cours de traitement par notre équipe",
  "priority": "high"
}
```

#### 2.3 Resolved (Résolue)
```json
{
  "title": "Réclamation résolue",
  "message": "Votre réclamation a été résolue. Merci de votre patience !",
  "priority": "high"
}
```

#### 2.4 Rejected (Rejetée)
```json
{
  "title": "Réclamation rejetée",
  "message": "Votre réclamation a été examinée et rejetée. Consultez la résolution pour plus de détails",
  "priority": "high"
}
```

#### 2.5 On Hold (En attente)
```json
{
  "title": "Réclamation en attente",
  "message": "Votre réclamation est temporairement en attente. Nous reviendrons vers vous prochainement",
  "priority": "medium"
}
```

**Exemple mobile** :
```
🔔 MCT Maintenance

Réclamation en cours de traitement
Votre réclamation est en cours de traitement par notre équipe

Il y a 5 minutes
```

---

## 3️⃣ Mise à Jour Générale

**Quand** : Admin/Tech modifie la résolution, description, priorité ou sujet

**Destinataire** : Client (propriétaire de la réclamation)

**Type** : `complaint_response`

**Route API** : `PUT /api/complaints/:id`

**Modifications concernées** :
- ✅ Résolution
- ✅ Description
- ✅ Sujet
- ✅ Priorité

```json
{
  "type": "complaint_response",
  "title": "Mise à jour de votre réclamation",
  "message": "Votre réclamation \"[sujet]\" a été mise à jour",
  "priority": "high",
  "data": {
    "complaintId": 123,
    "reference": "REC-2025-001"
  },
  "actionUrl": "/reclamations/123"
}
```

**Exemple mobile** :
```
🔔 MCT Maintenance

Mise à jour de votre réclamation
Votre réclamation "Problème avec l'équipement" a été mise à jour

Il y a quelques instants
```

---

## 4️⃣ Nouveau Suivi / Note

**Quand** : Admin/Tech ajoute une note/commentaire à la réclamation

**Destinataire** : Client (propriétaire de la réclamation)

**Type** : `complaint_response`

**Route API** : `POST /api/complaints/:id/notes`

```json
{
  "type": "complaint_response",
  "title": "Nouveau suivi sur votre réclamation",
  "message": "[Admin/Technicien] a ajouté un suivi à votre réclamation",
  "priority": "high",
  "data": {
    "complaintId": 123,
    "reference": "REC-2025-001",
    "notePreview": "Nous avons identifié le problème..."
  },
  "actionUrl": "/reclamations/123"
}
```

**Exemple mobile** :
```
🔔 MCT Maintenance

Nouveau suivi sur votre réclamation
Marie Technicien a ajouté un suivi à votre réclamation

Il y a 1 minute
```

---

## 🔄 Flux de Notifications

### Scénario Complet : Cycle de Vie d'une Réclamation

```
1. Client crée une réclamation
   ↓
   [NOTIF] → Admins/Techs : "Nouvelle réclamation"

2. Admin ouvre la réclamation
   ↓
   [NOTIF] → Client : "Réclamation enregistrée"

3. Admin assigne et change le statut en "in_progress"
   ↓
   [NOTIF] → Client : "Réclamation en cours de traitement"

4. Technicien ajoute une note
   ↓
   [NOTIF] → Client : "Nouveau suivi sur votre réclamation"

5. Technicien ajoute une résolution (sans changer le statut)
   ↓
   [NOTIF] → Client : "Mise à jour de votre réclamation" ✨ NOUVEAU

6. Admin résout la réclamation (statut = resolved)
   ↓
   [NOTIF] → Client : "Réclamation résolue"
```

---

## 📊 Matrice de Notifications

| Action | Route API | Type Notification | Destinataire | Priorité |
|--------|-----------|-------------------|--------------|----------|
| Création | POST /complaints | `complaint_created` | Admin/Tech | High |
| Changement statut | PATCH /complaints/:id/status | `complaint_status_change` | Client | High/Medium |
| Modif résolution | PUT /complaints/:id | `complaint_response` | Client | High |
| Modif description | PUT /complaints/:id | `complaint_response` | Client | High |
| Modif priorité | PUT /complaints/:id | `complaint_response` | Client | High |
| Modif sujet | PUT /complaints/:id | `complaint_response` | Client | High |
| Ajout note | POST /complaints/:id/notes | `complaint_response` | Client | High |

---

## 🎯 Règles de Priorité

### Cas 1 : Statut change SEUL
→ Notification : `complaint_status_change`

### Cas 2 : Statut + autres champs changent
→ Notification : `complaint_status_change` (plus spécifique)

### Cas 3 : Autres champs changent (pas le statut)
→ Notification : `complaint_response`

### Cas 4 : Ajout de note
→ Notification : `complaint_response` (variante avec auteur)

---

## 🔔 Format Notifications Mobile (FCM)

### Structure générale

```json
{
  "notification": {
    "title": "Titre de la notification",
    "body": "Message de la notification"
  },
  "data": {
    "type": "complaint_response",
    "complaintId": "123",
    "reference": "REC-2025-001",
    "actionUrl": "/reclamations/123"
  },
  "android": {
    "priority": "high",
    "notification": {
      "sound": "default",
      "channelId": "complaints"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

### Canaux de notification (Android)

- **complaints** : Réclamations (high priority)
- **orders** : Commandes (medium priority)
- **interventions** : Interventions (high priority)
- **general** : Général (low priority)

---

## 🚀 Avant/Après la Correction

### ❌ AVANT (4 nov 2025)

| Action | Notification envoyée ? |
|--------|------------------------|
| Changement statut | ✅ OUI |
| Modif résolution | ❌ NON |
| Modif description | ❌ NON |
| Modif priorité | ❌ NON |
| Ajout note | ✅ OUI |

### ✅ APRÈS (4 nov 2025)

| Action | Notification envoyée ? |
|--------|------------------------|
| Changement statut | ✅ OUI |
| Modif résolution | ✅ OUI |
| Modif description | ✅ OUI |
| Modif priorité | ✅ OUI |
| Ajout note | ✅ OUI |

---

## 📱 Aperçu Mobile

### iOS
```
╔════════════════════════════════════╗
║ MCT Maintenance              Now  ║
╠════════════════════════════════════╣
║ Mise à jour de votre réclamation  ║
║ Votre réclamation "Problème       ║
║ avec l'équipement" a été mise à   ║
║ jour                               ║
╚════════════════════════════════════╝
```

### Android
```
┌────────────────────────────────────┐
│ 🔔 MCT Maintenance          Now   │
├────────────────────────────────────┤
│ Mise à jour de votre réclamation  │
│ Votre réclamation "Problème       │
│ avec l'équipement" a été mise à   │
│ jour                               │
└────────────────────────────────────┘
```

---

## 🔧 Configuration Requise

### Côté Serveur (API)

```javascript
// notificationService.js
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(
    require('../firebase-service-account.json')
  )
});
```

### Côté Client (Mobile)

```dart
// main.dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'complaint_response' ||
      message.data['type'] == 'complaint_status_change') {
    // Afficher la notification
    // Mettre à jour le badge
    // Jouer un son
  }
});
```

---

**Dernière mise à jour** : 4 novembre 2025  
**Version** : 2.0 (avec notifications de mise à jour)
