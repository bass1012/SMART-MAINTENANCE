# 🔧 CORRECTION : Assignation Technicien - Notifications

## ❌ Problème Identifié

Quand vous assigniez un technicien depuis le dashboard web, **le technicien ne recevait PAS de notification**.

### **Pourquoi ?**

Le dashboard utilisait la route **PUT /api/interventions/:id** (mise à jour générale) au lieu de **PATCH /api/interventions/:id/assign** (assignation spécifique).

**Résultat :** La notification était envoyée au **CLIENT** au lieu du **TECHNICIEN**.

---

## ✅ Solutions Appliquées

### **1. Backend : Support PATCH en plus de POST**

**Fichier :** `/src/routes/interventionRoutes.js`

**Avant :**
```javascript
router.post('/:id/assign', 
  authenticate, 
  authorize('technician', 'admin'), 
  interventionController.assignIntervention
);
```

**Après :**
```javascript
// Support POST et PATCH pour l'assignation (compatibilité dashboard web)
router.post('/:id/assign', 
  authenticate, 
  authorize('technician', 'admin'), 
  interventionController.assignIntervention
);

router.patch('/:id/assign', 
  authenticate, 
  authorize('technician', 'admin'), 
  interventionController.assignIntervention
);
```

---

### **2. Dashboard Web : Utiliser assignTechnician au lieu de updateIntervention**

**Fichier :** `/src/pages/InterventionsPage.tsx`

**Avant :**
```typescript
if (editMode && selectedIntervention) {
  await interventionsService.updateIntervention(
    selectedIntervention.id, 
    interventionData
  );
  message.success('Intervention modifiée avec succès');
}
```

**Après :**
```typescript
if (editMode && selectedIntervention) {
  // Vérifier si le technicien a changé
  const technicianChanged = 
    selectedIntervention.technician_id !== newIntervention.technician_id;
  
  if (technicianChanged && newIntervention.technician_id) {
    // Utiliser la route d'assignation spécifique
    await interventionsService.assignTechnician(
      selectedIntervention.id, 
      newIntervention.technician_id
    );
    message.success('Technicien assigné avec succès');
    
    // Mettre à jour les autres champs si nécessaire
    const otherChanges = { ...interventionData };
    delete otherChanges.technician_id;
    
    if (Object.keys(otherChanges).length > 0) {
      await interventionsService.updateIntervention(
        selectedIntervention.id, 
        otherChanges
      );
    }
  } else {
    // Mise à jour normale
    await interventionsService.updateIntervention(
      selectedIntervention.id, 
      interventionData
    );
    message.success('Intervention modifiée avec succès');
  }
}
```

---

## 📊 Comparaison Avant/Après

### **AVANT (Logs serveur) :**
```
PUT /api/interventions/4
📤 Envoi notification modification intervention au client user_id: 10
✅ Notification envoyée au client pour la modification de l'intervention
```
❌ Notification envoyée au **CLIENT** (user_id: 10)  
❌ **AUCUNE** notification au technicien (user_id: 8)

---

### **APRÈS (Logs attendus) :**
```
PATCH /api/interventions/4/assign
📤 Envoi notification assignation au technicien user_id: 8
📬 Notification créée pour user 8: Nouvelle intervention assignée
🔔 Notification envoyée en temps réel à 1 client(s) de user 8
✅ Notification envoyée au technicien pour l'assignation
```
✅ Notification envoyée au **TECHNICIEN** (user_id: 8)  
✅ Type : `intervention_assigned`  
✅ Socket.IO + FCM push

---

## 🧪 Test de la Correction

### **Étape 1 : Redémarrer les serveurs**

```bash
# Backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Dashboard Web
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard
npm start
```

### **Étape 2 : Assigner un technicien**

1. Ouvrir le dashboard web : http://localhost:3001
2. Se connecter en tant qu'admin
3. Aller dans "Interventions"
4. Cliquer sur une intervention
5. Sélectionner un technicien dans le dropdown
6. Cliquer "Enregistrer"

### **Étape 3 : Vérifier les logs backend**

Vous devriez voir :
```
PATCH /api/interventions/:id/assign
📤 Envoi notification assignation au technicien user_id: X
📬 Notification créée pour user X: Nouvelle intervention assignée
🔌 Tentative d'envoi Socket.IO à la room "user:X"
✅ Notification envoyée au technicien pour l'assignation
```

### **Étape 4 : Vérifier dans l'app mobile**

Si le technicien a l'app mobile ouverte :
- ✅ Une notification doit apparaître
- ✅ Badge sur l'icône de notification
- ✅ Message : "Nouvelle intervention assignée"

Si l'app est fermée et que FCM est configuré :
- ✅ Notification push système
- ✅ Clic ouvre l'app → Liste des interventions

---

## 📱 Vérification Mobile

### **Vérifier le FCM Token**

```sql
SELECT id, email, role, fcm_token 
FROM users 
WHERE id = 8; -- ID du technicien
```

Si `fcm_token` est `NULL`, le technicien doit :
1. Se connecter à l'app mobile
2. L'app enregistre automatiquement le token

### **Vérifier la notification en DB**

```sql
SELECT * FROM notifications 
WHERE user_id = 8 
  AND type = 'intervention_assigned'
ORDER BY created_at DESC 
LIMIT 1;
```

Résultat attendu :
```
user_id: 8
type: 'intervention_assigned'
title: 'Nouvelle intervention assignée'
message: 'Une intervention vous a été assignée'
is_read: false
action_url: '/interventions'
```

---

## 🔔 Flux Complet de Notification

```
Admin assigne technicien (Dashboard Web)
  ↓
PATCH /api/interventions/:id/assign { technician_id: 8 }
  ↓
Backend : assignIntervention(req, res)
  ↓
1. Vérifier intervention existe ✓
2. Vérifier technicien existe (role='technician') ✓
3. Mettre à jour intervention.technician_id = 8 ✓
4. Mettre à jour intervention.status = 'assigned' ✓
  ↓
5. Créer notification en DB ✓
   - user_id: 8 (technicien)
   - type: 'intervention_assigned'
   - title: 'Nouvelle intervention assignée'
  ↓
6. Envoyer Socket.IO à room "user:8" ✓
   - Si connecté → Reçu instantanément
   - Si déconnecté → Stocké en DB uniquement
  ↓
7. Envoyer FCM push ✓
   - Si fcm_token existe → Notification push
   - Si null → Ignoré (sans erreur)
  ↓
Technicien reçoit notification 🔔
```

---

## 📋 Checklist Finale

- [x] Route PATCH ajoutée dans `interventionRoutes.js`
- [x] Dashboard utilise `assignTechnician` au lieu de `updateIntervention`
- [x] Fonction `assignIntervention` implémentée dans le contrôleur
- [x] Notification envoyée au **technicien** (pas au client)
- [x] Type de notification : `intervention_assigned`
- [x] Socket.IO configuré
- [x] FCM prêt (si token existe)
- [x] Logs détaillés pour debug

---

## 🚀 Résultat

✅ **Maintenant :** Quand vous assignez un technicien depuis le dashboard web, **le technicien reçoit une notification** !

### **Notifications reçues par le technicien :**

1. **Dashboard Web** (si connecté) :
   - Badge notification (compteur)
   - Dropdown avec liste
   - Toast popup

2. **Application Mobile** (si ouverte) :
   - Notification foreground
   - SnackBar avec bouton "Voir"

3. **Application Mobile** (fermée) :
   - Notification push système
   - Clic → Ouvre l'app

---

## 📝 Notes Importantes

1. **Double Notification :** Si vous modifiez AUSSI d'autres champs (titre, date, etc.), deux notifications seront envoyées :
   - Une au **technicien** (assignation)
   - Une au **client** (modification)

2. **Première Assignation :** Si l'intervention n'avait pas de technicien avant, seule la notification d'assignation est envoyée.

3. **Changement de Technicien :** Si vous changez de technicien :
   - L'ancien technicien ne reçoit PAS de notification
   - Le nouveau technicien reçoit une notification d'assignation

4. **FCM Token :** Le technicien doit se connecter au moins une fois avec l'app mobile pour que les notifications push fonctionnent.

---

## 🔍 Debugging

Si le technicien ne reçoit toujours pas de notification :

### **1. Vérifier les logs backend**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

Chercher :
```
📤 Envoi notification assignation au technicien user_id: X
```

### **2. Vérifier la route appelée**
Dans les logs, chercher :
```
PATCH /api/interventions/:id/assign  ✅ CORRECT
PUT /api/interventions/:id           ❌ INCORRECT
```

### **3. Vérifier en base de données**
```sql
SELECT * FROM notifications 
WHERE user_id = 8 
  AND type = 'intervention_assigned'
ORDER BY created_at DESC;
```

### **4. Vérifier Socket.IO**
```
🔌 Tentative d'envoi Socket.IO à la room "user:8"
👤 1 client(s) connecté(s) dans cette room  ✅ Connecté
👤 0 client(s) connecté(s) dans cette room  ⚠️  Déconnecté
```

---

**Testez maintenant et confirmez que ça fonctionne ! 🚀**
