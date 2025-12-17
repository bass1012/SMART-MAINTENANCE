# 🔧 Fix : Statistiques Réelles dans l'Application Mobile

## ❌ Problème

Les statistiques affichées dans le dashboard mobile étaient **en dur** (hardcodées) et ne reflétaient pas les vraies données de la base de données.

**Avant :**
```javascript
const stats = {
  totalInterventions: 12,  // ❌ Valeur fixe
  pendingInterventions: 2,
  totalQuotes: 5,
  // ...
};
```

---

## ✅ Solution

Implémentation d'un contrôleur qui fait de **vraies requêtes** à la base de données pour calculer les statistiques en temps réel.

---

## 📁 Fichiers Créés/Modifiés

### **1. Nouveau Contrôleur**

**Fichier :** `/src/controllers/customer/dashboardController.js`

**Fonctionnalités :**
- Récupère le profil client depuis `user_id`
- Compte les interventions (total, en attente, terminées)
- Compte les devis (total, en attente, acceptés)
- Compte les commandes
- Calcule le total dépensé (commandes payées)
- Compte les réclamations (total, ouvertes)
- Compte les contrats (total, actifs)
- Compte les maintenances à venir (30 prochains jours)

**Requêtes SQL :**
```javascript
// Interventions
InterventionRequest.count({ where: { customer_id: userId } })
InterventionRequest.count({ where: { customer_id: userId, status: 'pending' } })
InterventionRequest.count({ where: { customer_id: userId, status: 'completed' } })

// Devis
Quote.count({ where: { customerId: customerId } })
Quote.count({ where: { customerId: customerId, status: 'pending' } })
Quote.count({ where: { customerId: customerId, status: 'accepted' } })

// Commandes
Order.count({ where: { customerId: userId } })
Order.sum('totalAmount', { where: { customerId: userId, status: 'paid' } })

// Réclamations
Complaint.count({ where: { customerId: customerId } })
Complaint.count({ where: { customerId: customerId, status: 'open' } })

// Contrats
MaintenanceContract.count({ where: { customerId: customerId } })
MaintenanceContract.count({ where: { customerId: customerId, status: 'active' } })

// Maintenances à venir
MaintenanceContract.count({ 
  where: { 
    customerId: customerId,
    status: 'active',
    nextMaintenanceDate: { [Op.lte]: +30 jours, [Op.gte]: aujourd'hui }
  }
})
```

---

### **2. Route Mise à Jour**

**Fichier :** `/src/routes/customerRoutes.js`

**Avant :**
```javascript
router.get('/dashboard/stats', async (req, res) => {
  // TODO: Remplacer par de vraies requêtes
  const stats = { ... }; // Valeurs en dur
  res.json({ success: true, data: stats });
});
```

**Après :**
```javascript
const dashboardController = require('../controllers/customer/dashboardController');

router.get('/dashboard/stats', dashboardController.getDashboardStats);
```

---

## 📊 Statistiques Retournées

**Format de réponse :**
```json
{
  "success": true,
  "data": {
    "totalInterventions": 2,
    "pendingInterventions": 1,
    "completedInterventions": 0,
    "totalQuotes": 3,
    "pendingQuotes": 1,
    "acceptedQuotes": 1,
    "totalOrders": 6,
    "totalComplaints": 1,
    "pendingComplaints": 1,
    "totalContracts": 1,
    "activeContracts": 1,
    "totalSpent": 45000.00,
    "upcomingMaintenances": 0
  },
  "message": "Statistiques récupérées avec succès"
}
```

---

## 🔄 Flux de Données

### **Mobile → Backend**

```
1. App mobile démarre
   ↓
2. CustomerMainScreen.initState()
   ↓
3. _loadDashboardData()
   ↓
4. ApiService.getDashboardStats()
   ↓
5. GET /api/customer/dashboard/stats
   ↓
6. dashboardController.getDashboardStats()
   ↓
7. Requêtes SQL vers la base de données
   ↓
8. Calcul des statistiques réelles
   ↓
9. Retour JSON
   ↓
10. DashboardStats.fromJson()
   ↓
11. setState() → Affichage
```

---

## 📱 Affichage dans l'App Mobile

**Écran :** `customer_main_screen.dart`

**Cartes de statistiques :**

```dart
_buildStatCard(
  icon: Icons.build_circle_outlined,
  title: 'Interventions',
  value: '${_stats!.totalInterventions}',  // ✅ Valeur réelle
  subtitle: '${_stats!.pendingInterventions} en cours',
  color: Colors.blue,
)

_buildStatCard(
  icon: Icons.description_outlined,
  title: 'Devis',
  value: '${_stats!.totalQuotes}',  // ✅ Valeur réelle
  subtitle: '${_stats!.pendingQuotes} en attente',
  color: Colors.green,
)

_buildStatCard(
  icon: Icons.shopping_bag_outlined,
  title: 'Commandes',
  value: '${_stats!.totalOrders}',  // ✅ Valeur réelle
  subtitle: 'Total',
  color: Colors.orange,
)

_buildStatCard(
  icon: Icons.attach_money,
  title: 'Dépenses',
  value: '${_stats!.totalSpent.toStringAsFixed(0)}',  // ✅ Valeur réelle
  subtitle: 'FCFA',
  color: Colors.purple,
)
```

---

## 🧪 Test

### **1. Redémarrer le Backend**

```bash
cd mct-maintenance-api
npm start
```

---

### **2. Tester l'Endpoint**

```bash
curl -X GET http://localhost:3000/api/customer/dashboard/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Réponse attendue :**
```json
{
  "success": true,
  "data": {
    "totalInterventions": 2,
    "pendingInterventions": 1,
    "completedInterventions": 0,
    "totalQuotes": 3,
    "pendingQuotes": 1,
    "acceptedQuotes": 1,
    "totalOrders": 6,
    "totalComplaints": 1,
    "pendingComplaints": 1,
    "totalContracts": 1,
    "activeContracts": 1,
    "totalSpent": 45000.00,
    "upcomingMaintenances": 0
  },
  "message": "Statistiques récupérées avec succès"
}
```

---

### **3. Tester sur Mobile**

1. **Relancer l'app Flutter :**
   ```bash
   flutter run
   ```

2. **Se connecter** avec un compte client

3. **Vérifier le dashboard :**
   - ✅ Les chiffres correspondent aux vraies données
   - ✅ Les statistiques se mettent à jour en temps réel

---

## 🔍 Logs de Débogage

**Backend (console) :**
```
📊 Récupération des statistiques pour user_id: 9
✅ Customer profile ID: 7
📊 Statistiques calculées: {
  totalInterventions: 2,
  pendingInterventions: 1,
  completedInterventions: 0,
  totalQuotes: 3,
  pendingQuotes: 1,
  acceptedQuotes: 1,
  totalOrders: 6,
  totalComplaints: 1,
  pendingComplaints: 1,
  totalContracts: 1,
  activeContracts: 1,
  totalSpent: 45000,
  upcomingMaintenances: 0
}
```

---

## 📝 Mapping des IDs

**Important :** Il y a 2 types d'IDs pour les clients :

1. **`user_id`** : ID dans la table `users`
2. **`customer_id`** : ID dans la table `customer_profiles`

**Mapping :**
- `InterventionRequest.customer_id` → `users.id`
- `Quote.customerId` → `customer_profiles.id`
- `Order.customerId` → `users.id`
- `Complaint.customerId` → `customer_profiles.id`
- `MaintenanceContract.customerId` → `customer_profiles.id`

**Le contrôleur gère automatiquement cette conversion.**

---

## ✅ Résultat

**Avant :**
- ❌ Statistiques en dur (12, 5, 8, etc.)
- ❌ Ne reflètent pas la réalité
- ❌ Pas de mise à jour

**Après :**
- ✅ Statistiques calculées en temps réel
- ✅ Basées sur les vraies données de la BDD
- ✅ Se mettent à jour automatiquement
- ✅ Précises et fiables

**Les statistiques de l'application mobile affichent maintenant les vraies données !** 🎉📊
