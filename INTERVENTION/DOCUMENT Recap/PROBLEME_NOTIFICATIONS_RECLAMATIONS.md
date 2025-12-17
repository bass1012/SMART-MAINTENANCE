# 🐛 Problème : Notifications de réclamations ne s'affichent pas

## 🔍 Problème identifié

**Symptôme** : Les réclamations créées depuis l'application mobile ne génèrent pas de notifications sur le dashboard web.

**Cause racine** : Les CustomerProfiles n'ont pas de User actif associé (soft deleted).

---

## 📊 Diagnostic effectué

### **1. Code de notification**
✅ Le code dans `complaintController.js` est correct :
```javascript
// Ligne 224-236
const customerUser = complaintWithRelations.customer?.user;
if (customerUser) {
  const customer = {
    id: customerUser.id,
    first_name: complaintWithRelations.customer.first_name,
    last_name: complaintWithRelations.customer.last_name,
    email: customerUser.email
  };
  await notifyNewComplaint(complaintWithRelations, customer);
}
```

### **2. Problème de données**
❌ Certains clients ont des users soft-deleted :
```sql
SELECT cp.id, cp.first_name, cp.user_id, u.deleted_at 
FROM customer_profiles cp
LEFT JOIN users u ON cp.user_id = u.id;

-- Résultat
2|First|User|2|2025-10-16 15:03:55  ← User supprimé !
```

### **3. Relations Sequelize**
❌ Sequelize exclut automatiquement les enregistrements soft-deleted :
```javascript
include: [{
  model: User,
  as: 'user',
  // Par défaut : WHERE user.deleted_at IS NULL
}]
```

**Résultat** : `complaint.customer.user` est `undefined` → Pas de notification

---

## ✅ Solutions

### **Solution 1 : Utiliser des comptes actifs (RECOMMANDÉ)**

**Pour l'app mobile** :
1. Se connecter avec un compte **actif** (non supprimé)
2. Créer une réclamation
3. La notification s'affichera automatiquement

**Comptes actifs disponibles** :
```
ID 10 : bassoued7@gmail.com (Bassirou REMPLES)
ID  9 : cisse.bakary@gmail.com (Bakary Madou CISSE)
ID  7 : testmodif@mail.com (Zoumana Edouard OUATTARA)
```

---

### **Solution 2 : Script de test manuel**

Pour tester les notifications de réclamations :

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node send-complaint-notification.js
```

**Ce que fait le script** :
1. Trouve la dernière réclamation en base
2. Vérifie qu'elle a un customer avec un user actif
3. Envoie la notification aux admins
4. Affiche le résultat

---

### **Solution 3 : Corriger le contrôleur (si nécessaire)**

Si vous voulez gérer les cas où le user est supprimé, modifiez `complaintController.js` :

```javascript
// Option A : Utiliser paranoid: false pour inclure les users supprimés
include: [{
  model: User,
  as: 'user',
  attributes: ['id', 'email', 'first_name', 'last_name'],
  paranoid: false  // ← Inclure les users supprimés
}]

// Option B : Fallback sur les données du CustomerProfile
const customerData = {
  id: complaintWithRelations.customer.user_id,  // ← Direct depuis CustomerProfile
  first_name: complaintWithRelations.customer.first_name,
  last_name: complaintWithRelations.customer.last_name,
  email: 'unknown@example.com'  // ← Email par défaut si user supprimé
};
```

---

## 🧪 Test complet

### **Étape 1 : Créer une réclamation depuis le mobile**

1. **Lancer l'app mobile** :
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
   flutter run
   ```

2. **Se connecter avec un compte actif** :
   - Email : `bassoued7@gmail.com`
   - Password : (votre mot de passe)

3. **Créer une réclamation** :
   - Aller dans Support → Réclamations
   - Créer une nouvelle réclamation
   - Soumettre

### **Étape 2 : Vérifier le dashboard**

1. **Dashboard web** : `http://localhost:3001`
2. **Se connecter** : `admin@mct-maintenance.com`
3. **Vérifier** :
   - ✅ Badge sur la cloche 🔔
   - ✅ Toast "Nouvelle réclamation"
   - ✅ Notification dans le dropdown
   - ✅ Clic → Navigation vers `/reclamations/:id`

---

## 📝 Vérifications en base de données

### **Comptes clients actifs** :
```sql
SELECT u.id, u.email, u.first_name, u.last_name, cp.id as profile_id
FROM users u
LEFT JOIN customer_profiles cp ON u.id = cp.user_id
WHERE u.role = 'customer' AND u.deleted_at IS NULL;
```

### **Dernière notification de réclamation** :
```sql
SELECT id, user_id, type, title, message, action_url, created_at
FROM notifications
WHERE type = 'complaint_created'
ORDER BY created_at DESC
LIMIT 1;
```

### **Réclamations avec users actifs** :
```sql
SELECT c.id, c.reference, c.subject, cp.first_name, cp.last_name, u.email, u.deleted_at
FROM complaints c
JOIN customer_profiles cp ON c.customer_id = cp.id
LEFT JOIN users u ON cp.user_id = u.id
ORDER BY c.created_at DESC
LIMIT 5;
```

---

## 🎯 Résumé

### **Pourquoi ça ne marchait pas** :
1. CustomerProfiles pointent vers des Users soft-deleted
2. Sequelize exclut automatiquement les users supprimés
3. `customer.user` est `undefined`
4. Le code ne crée pas de notification

### **Solution rapide** :
Utiliser un compte client actif (non supprimé) pour créer des réclamations

### **Solution long terme** :
- Option A : Ne jamais soft-delete les users (désactiver au lieu de supprimer)
- Option B : Modifier le code pour gérer les users supprimés
- Option C : Nettoyer la base pour supprimer les CustomerProfiles orphelins

---

## ✅ Notification de test créée

**ID** : 9  
**Type** : complaint_created  
**Titre** : Nouvelle réclamation  
**Message** : Bassirou REMPLES a créé une réclamation  
**URL** : /reclamations/7  

**Vérifiez maintenant le dashboard !** 🎉
