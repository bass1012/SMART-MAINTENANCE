# 🔧 Correction : Notification Client avec Nom du Technicien

## 🎯 Problème Identifié

Le client recevait **"Nouvelle intervention assignée"** (notification du technicien) au lieu de **"Technicien assigné - [Nom du technicien]..."**.

**Cause racine :** Le champ `customer` était chargé **sans** `CustomerProfile`, donc `first_name` et `last_name` étaient **vides** → La notification `technician_assigned` échouait silencieusement.

---

## ✅ Corrections Appliquées

### **1. Problème de Structure de Données**

Pour un **customer** (client), les champs `first_name` et `last_name` sont dans la table `customer_profiles`, **PAS** dans `users`.

**Avant (❌ Incorrect) :**
```javascript
// Ne fonctionnait PAS pour les customers
{ model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
```

**Après (✅ Correct) :**
```javascript
{ 
  model: User, 
  as: 'customer', 
  attributes: ['id', 'email'],
  include: [
    {
      model: CustomerProfile,
      as: 'customerProfile',
      attributes: ['first_name', 'last_name']
    }
  ]
}
```

---

### **2. Enrichissement du Customer**

Avant d'envoyer les notifications, il faut extraire `first_name` et `last_name` de `customerProfile` :

**Code ajouté dans toutes les fonctions :**
```javascript
// Enrichir le customer avec les données du profil
const customer = {
  id: intervention.customer.id,
  email: intervention.customer.email,
  first_name: intervention.customer.customerProfile?.first_name || '',
  last_name: intervention.customer.customerProfile?.last_name || ''
};

// Maintenant customer.first_name et customer.last_name sont disponibles
await notifyTechnicianAssignedToCustomer(intervention, customer, technician);
```

---

## 📂 Fichiers Modifiés

| Fonction | Ligne | Modification |
|----------|-------|--------------|
| **`createIntervention`** | 142-158 | Charger CustomerProfile + enrichir customer |
| **`updateIntervention`** | 208-224 | Charger CustomerProfile + enrichir customer |
| **`assignIntervention`** | 294-310 | Charger CustomerProfile + enrichir customer |

---

## 🧪 Test à Effectuer

### **1. Redémarrer le Backend**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

### **2. Nettoyer les FCM Tokens Dupliqués (Important)**

```bash
node fix-duplicate-fcm-tokens.js
```

**Pourquoi ?** Si vous testez avec le même appareil pour client et technicien, ils partagent le même FCM token → Le client reçoit toutes les notifications du technicien.

### **3. Tester l'Assignation**

**Sur le dashboard admin :**
1. Créer une nouvelle intervention
2. Assigner un technicien (ex: Hamed OUATTARA)
3. Vérifier les notifications mobiles

**Logs backend attendus :**
```bash
📤 Envoi notification assignation au technicien user_id: 15
✅ Notification envoyée au technicien pour l'assignation

📤 Envoi notification assignation au client user_id: 9
👤 Client: Bakary Madou CISSE
✅ Notification envoyée au client pour l'assignation du technicien
```

**Notifications mobiles attendues :**

**Technicien (user_id: 15) :**
```
🔔 Nouvelle intervention assignée
   Une intervention vous a été assignée
```

**Client (user_id: 9) :**
```
🔔 Technicien assigné
   Hamed OUATTARA a été assigné à votre intervention
```

---

## 🔍 Vérification en Base de Données

Après l'assignation, vérifiez les notifications créées :

```bash
sqlite3 database.sqlite "SELECT n.id, u.role, n.type, n.title, n.message FROM notifications n JOIN users u ON n.user_id = u.id ORDER BY n.created_at DESC LIMIT 5;"
```

**Résultat attendu :**
```
ID  | role       | type                  | title                            | message
----+------------+-----------------------+----------------------------------+----------------------------------------
XXX | customer   | technician_assigned   | Technicien assigné               | Hamed OUATTARA a été assigné...
XXX | technician | intervention_assigned | Nouvelle intervention assignée   | Une intervention vous a été assignée
XXX | admin      | intervention_request  | Nouvelle demande d'intervention  | Bakary Madou CISSE a créé...
```

---

## 📊 Résumé des Problèmes Résolus

| # | Problème | Solution |
|---|----------|----------|
| 1 | Client reçoit notification technicien | ✅ Notifications séparées (intervention_assigned vs technician_assigned) |
| 2 | Customer sans first_name/last_name | ✅ Charger CustomerProfile dans toutes les fonctions |
| 3 | Notification client échoue silencieusement | ✅ Enrichir customer avant d'envoyer notification |
| 4 | Même FCM token pour 2 users | ✅ Supprimer token au logout + script de nettoyage |
| 5 | Double notification au client | ✅ Désactiver notification dans updateIntervention si assignation |

---

## 🎯 Checklist Finale

- [x] Migration type `technician_assigned` exécutée
- [x] `CustomerProfile` chargé dans toutes les fonctions
- [x] Customer enrichi avant notifications
- [x] FCM token supprimé au logout
- [ ] Redémarrer le backend
- [ ] Nettoyer FCM tokens dupliqués
- [ ] Tester avec une nouvelle assignation
- [ ] Vérifier les 2 notifications (technicien + client)

---

**Date de résolution :** 30 octobre 2025  
**Statut :** ✅ Prêt pour test
