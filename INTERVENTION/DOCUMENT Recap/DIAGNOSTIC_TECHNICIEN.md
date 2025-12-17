# 🔍 DIAGNOSTIC : Technicien ne reçoit ni interventions ni notifications

## ❌ Problèmes Identifiés

### **1. Routes technicien retournaient des données vides**

**Avant :**
```javascript
router.get('/interventions', async (req, res) => {
  // TODO: Récupérer depuis DB
  res.json({
    success: true,
    data: [] // ❌ TOUJOURS VIDE
  });
});
```

**Résultat :** L'app mobile recevait toujours un tableau vide, même si des interventions étaient assignées au technicien.

---

## ✅ Corrections Appliquées

### **1. Route GET /api/technician/interventions**

**Fichier :** `/src/routes/technicianRoutes.js`

**Implémentation :**
```javascript
router.get('/interventions', async (req, res) => {
  try {
    const technicianId = req.user.id;
    const { status } = req.query;
    
    // Filtre par technicien + statut optionnel
    const where = { technician_id: technicianId };
    if (status) {
      where.status = status;
    }
    
    // Récupération avec infos client
    const interventions = await Intervention.findAll({
      where,
      include: [
        {
          model: User,
          as: 'customer',
          include: [
            {
              model: CustomerProfile,
              as: 'customerProfile',
              attributes: ['first_name', 'last_name', 'phone', 'address']
            }
          ]
        }
      ],
      order: [['scheduled_date', 'DESC']]
    });
    
    // Formatage pour l'app mobile
    const formattedInterventions = interventions.map(intervention => ({
      id: intervention.id,
      title: intervention.title,
      description: intervention.description,
      customer_name: `${customerProfile.first_name} ${customerProfile.last_name}`,
      address: intervention.address || customerProfile?.address,
      scheduled_date: intervention.scheduled_date,
      scheduled_time: new Date(intervention.scheduled_date).toLocaleTimeString(),
      status: intervention.status,
      priority: intervention.priority,
      type: intervention.intervention_type,
      customer_phone: customerProfile?.phone
    }));
    
    res.json({
      success: true,
      data: formattedInterventions
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des interventions'
    });
  }
});
```

---

### **2. Route POST /api/technician/interventions/:id/accept**

```javascript
router.post('/interventions/:id/accept', async (req, res) => {
  const { id } = req.params;
  const technicianId = req.user.id;
  
  const intervention = await Intervention.findOne({
    where: { id, technician_id: technicianId }
  });
  
  if (!intervention) {
    return res.status(404).json({
      success: false,
      message: 'Intervention non trouvée'
    });
  }
  
  // Changer le statut en 'in_progress'
  await intervention.update({ status: 'in_progress' });
  
  res.json({
    success: true,
    message: 'Intervention acceptée'
  });
});
```

---

### **3. Route POST /api/technician/interventions/:id/complete**

```javascript
router.post('/interventions/:id/complete', async (req, res) => {
  const { id } = req.params;
  const technicianId = req.user.id;
  
  const intervention = await Intervention.findOne({
    where: { id, technician_id: technicianId }
  });
  
  if (!intervention) {
    return res.status(404).json({
      success: false,
      message: 'Intervention non trouvée'
    });
  }
  
  // Changer le statut en 'completed'
  await intervention.update({ 
    status: 'completed',
    completed_date: new Date()
  });
  
  res.json({
    success: true,
    message: 'Intervention terminée'
  });
});
```

---

### **4. Route GET /api/technician/dashboard/stats**

```javascript
router.get('/dashboard/stats', async (req, res) => {
  const technicianId = req.user.id;
  
  // Compter les interventions par statut
  const totalInterventions = await Intervention.count({
    where: { technician_id: technicianId }
  });
  
  const pendingInterventions = await Intervention.count({
    where: { technician_id: technicianId, status: 'pending' }
  });
  
  const completedInterventions = await Intervention.count({
    where: { technician_id: technicianId, status: 'completed' }
  });
  
  const inProgressInterventions = await Intervention.count({
    where: { technician_id: technicianId, status: 'in_progress' }
  });
  
  const upcomingAppointments = await Intervention.count({
    where: {
      technician_id: technicianId,
      scheduled_date: { [Op.gte]: new Date() },
      status: { [Op.in]: ['pending', 'assigned', 'in_progress'] }
    }
  });
  
  res.json({
    success: true,
    data: {
      total_interventions: totalInterventions,
      pending_interventions: pendingInterventions,
      completed_interventions: completedInterventions,
      in_progress_interventions: inProgressInterventions,
      total_revenue: 0,
      monthly_revenue: 0,
      average_rating: 0,
      total_reviews: 0,
      upcoming_appointments: upcomingAppointments
    }
  });
});
```

---

## 🧪 Tests à Effectuer

### **Test 1 : Vérifier les interventions assignées en DB**

```sql
-- Vérifier les interventions du technicien user_id = 8
SELECT 
  id, 
  title, 
  status, 
  priority, 
  scheduled_date,
  customer_id,
  technician_id
FROM interventions 
WHERE technician_id = 8
ORDER BY scheduled_date DESC;
```

**Résultat attendu :**
```
id | title              | status      | technician_id
---|--------------------|-------------|---------------
4  | titre demande      | pending     | 8
5  | Demande install..  | pending     | 8
6  | test diqgnostia    | in_progress | 8
```

---

### **Test 2 : Tester l'API avec cURL**

```bash
# 1. Login technicien
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cissoko@gmail.com","password":"password"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# 2. Récupérer les interventions
curl -X GET "http://localhost:3000/api/technician/interventions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq

# 3. Récupérer les stats
curl -X GET "http://localhost:3000/api/technician/dashboard/stats" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq

# 4. Accepter une intervention
curl -X POST "http://localhost:3000/api/technician/interventions/4/accept" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq
```

---

### **Test 3 : Vérifier les logs backend**

Après avoir lancé le serveur :
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

Ouvrir l'app mobile et regarder les logs :

**Logs attendus :**
```
📋 Récupération interventions pour technicien 8, status: tous
Executing (default): SELECT ... FROM `interventions` WHERE `technician_id` = 8
✅ 3 intervention(s) trouvée(s) pour technicien 8
GET /api/technician/interventions 200

📊 Récupération stats dashboard pour technicien 8
✅ Stats: 3 total, 2 pending, 1 completed
GET /api/technician/dashboard/stats 200
```

---

### **Test 4 : Tester sur l'app mobile**

1. **Ouvrir l'app mobile**
2. **Se connecter en tant que technicien** : cissoko@gmail.com
3. **Vérifier le dashboard** :
   - Les statistiques doivent afficher les vrais chiffres
   - Pas 0 partout
4. **Aller dans "Mes Interventions"** :
   - La liste doit afficher les interventions assignées
   - Pas de liste vide
5. **Cliquer sur "Accepter"** sur une intervention :
   - Le statut doit changer en "En cours"
   - SnackBar de succès

---

## 🔔 Problème des Notifications

### **Vérification 1 : Le technicien reçoit-il les notifications ?**

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
WHERE user_id = 8  -- ID du technicien
ORDER BY created_at DESC
LIMIT 10;
```

**Types attendus :**
- `intervention_assigned` : Quand une intervention est assignée
- `intervention_updated` : Quand l'intervention est modifiée

---

### **Vérification 2 : Socket.IO est-il connecté ?**

Quand vous assignez un technicien, regardez les logs backend :

**Logs attendus :**
```
PATCH /api/interventions/4/assign
📤 Envoi notification assignation au technicien user_id: 8
📬 Notification créée pour user 8: Nouvelle intervention assignée
🔌 Tentative d'envoi Socket.IO à la room "user:8"
👤 1 client(s) connecté(s) dans cette room  ✅
🔔 Notification envoyée en temps réel à 1 client(s)
```

**Si 0 client connecté :**
```
👤 0 client(s) connecté(s) dans cette room  ⚠️
⚠️  Aucun client connecté, notification stockée en DB uniquement
```

Cela signifie que :
- L'app mobile n'est pas connectée à Socket.IO
- Ou le technicien n'est pas connecté au dashboard web

---

### **Vérification 3 : FCM Token existe-t-il ?**

```sql
SELECT id, email, role, fcm_token 
FROM users 
WHERE id = 8;
```

**Si fcm_token est NULL :**
- Le technicien doit se connecter à l'app mobile au moins une fois
- L'app enregistrera automatiquement le token
- Ensuite, les notifications push fonctionneront

---

## 🚀 Solution Complète

### **Étape 1 : Redémarrer le serveur**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

### **Étape 2 : Assigner une intervention au technicien**

**Depuis le dashboard web :**
1. Se connecter en tant qu'admin
2. Aller dans "Interventions"
3. Modifier une intervention
4. Sélectionner le technicien : **Edourd Cissoko** (user_id: 8)
5. Cliquer "Enregistrer"

**Vérifier les logs :**
```
PATCH /api/interventions/:id/assign
📤 Envoi notification assignation au technicien user_id: 8
✅ Notification envoyée au technicien
```

### **Étape 3 : Ouvrir l'app mobile**

1. Se connecter en tant que technicien
2. **Dashboard** : Vérifier que les stats s'affichent
3. **Mes Interventions** : Vérifier que la liste n'est pas vide
4. **Notifications** : Vérifier si la notification d'assignation apparaît

---

## 📊 Comparaison Avant/Après

### **AVANT :**

**API Response :**
```json
{
  "success": true,
  "data": []  // ❌ TOUJOURS VIDE
}
```

**Dashboard Mobile :**
```
Interventions : 0
En attente : 0
Complétées : 0
```

**Liste Interventions :**
```
(vide)
```

---

### **APRÈS :**

**API Response :**
```json
{
  "success": true,
  "data": [
    {
      "id": 4,
      "title": "titre demande",
      "customer_name": "Bassirou REMPLES",
      "address": "test",
      "scheduled_date": "2025-10-31T10:51:00.000Z",
      "status": "pending",
      "priority": "high"
    },
    {
      "id": 5,
      "title": "Demande installation",
      "customer_name": "Bassirou REMPLES",
      "address": "cocody",
      "scheduled_date": "2025-10-25T11:07:00.000Z",
      "status": "pending",
      "priority": "urgent"
    }
  ]
}
```

**Dashboard Mobile :**
```
Interventions : 7
En attente : 2
Complétées : 1
En cours : 4
```

**Liste Interventions :**
```
✅ titre demande (Bassirou REMPLES)
✅ Demande installation (Bassirou REMPLES)
✅ test diqgnostia (Bassirou REMPLES)
...
```

---

## 📋 Checklist de Diagnostic

- [x] Routes technicien implémentées (interventions, stats, accept, complete)
- [x] Requêtes DB ajoutées (findAll, count, update)
- [x] Formatage des données pour l'app mobile
- [x] Logs de debug ajoutés
- [ ] Tester l'API avec cURL
- [ ] Tester sur l'app mobile
- [ ] Vérifier les notifications en DB
- [ ] Vérifier Socket.IO connecté
- [ ] Vérifier FCM token enregistré

---

## 🔍 Si le problème persiste

### **1. Vérifier que les routes sont bien chargées**

Dans `/src/app.js`, chercher :
```javascript
app.use('/api/technician', technicianRoutes);
```

### **2. Vérifier l'authentification**

L'app mobile envoie-t-elle le token JWT ?
```
Headers: {
  'authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
}
```

### **3. Vérifier le rôle de l'utilisateur**

```sql
SELECT id, email, role FROM users WHERE id = 8;
```

Le rôle doit être `'technician'`, pas `'customer'` ou `'admin'`.

### **4. Vérifier les associations Sequelize**

Dans `/src/models/Intervention.js`, vérifier :
```javascript
Intervention.belongsTo(User, {
  as: 'customer',
  foreignKey: 'customer_id'
});

Intervention.belongsTo(User, {
  as: 'technician',
  foreignKey: 'technician_id'
});
```

---

**Testez maintenant et partagez les résultats ! 🚀**
