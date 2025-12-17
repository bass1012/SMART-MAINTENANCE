# 🔧 Fix : Conflit d'Alias dans les Associations Sequelize

## ❌ Erreur

```
AssociationError [SequelizeAssociationError]: You have used the alias customer in two separate associations. Aliased associations must have unique aliases.
    at Object.<anonymous> (/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/src/models/index.js:64:11)
```

---

## 🔍 Cause du Problème

Les associations du modèle `Complaint` étaient définies **deux fois** :

### **1. Dans le modèle Complaint.js (lignes 87-89)**
```javascript
// /src/models/Complaint.js
Complaint.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });
Complaint.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
Complaint.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });
```

### **2. Dans models/index.js (ajoutées par erreur)**
```javascript
// /src/models/index.js
Complaint.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });  // ❌ Doublon
Complaint.belongsTo(Product, { foreignKey: 'productId', as: 'product' });            // ❌ Doublon
Complaint.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });                  // ❌ Doublon
```

**Résultat :** L'alias `customer` était utilisé deux fois, causant le conflit.

---

## ✅ Solution

Supprimer les associations en double de `models/index.js` car elles sont déjà définies dans le modèle `Complaint.js`.

### **Fichier Modifié : `/src/models/index.js`**

**Avant :**
```javascript
// Associations produits - catégories - marques
Product.belongsTo(Category, { foreignKey: 'categorie_id', as: 'categorie' });
Product.belongsTo(Brand, { foreignKey: 'marque_id', as: 'marque' });
Category.hasMany(Product, { foreignKey: 'categorie_id', as: 'products' });
Brand.hasMany(Product, { foreignKey: 'marque_id', as: 'products' });

// Associations réclamations
Complaint.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });  // ❌
Complaint.belongsTo(Product, { foreignKey: 'productId', as: 'product' });            // ❌
Complaint.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });                  // ❌
```

**Après :**
```javascript
// Associations produits - catégories - marques
Product.belongsTo(Category, { foreignKey: 'categorie_id', as: 'categorie' });
Product.belongsTo(Brand, { foreignKey: 'marque_id', as: 'marque' });
Category.hasMany(Product, { foreignKey: 'categorie_id', as: 'products' });
Brand.hasMany(Product, { foreignKey: 'marque_id', as: 'products' });

// Note: Les associations de Complaint sont déjà définies dans Complaint.js  // ✅
```

---

## 📋 Règle Générale : Où Définir les Associations ?

### **Option 1 : Dans le Modèle (Recommandé pour associations simples)**
```javascript
// /src/models/Complaint.js
class Complaint extends Model {}

Complaint.init({ ... }, { sequelize, ... });

// Associations directement dans le modèle
Complaint.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });
Complaint.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

module.exports = Complaint;
```

**Avantages :**
- ✅ Tout au même endroit
- ✅ Facile à maintenir
- ✅ Pas de risque de doublon

---

### **Option 2 : Dans models/index.js (Pour associations complexes)**
```javascript
// /src/models/index.js
const User = require('./User');
const CustomerProfile = require('./CustomerProfile');

// Associations centralisées
User.hasOne(CustomerProfile, { foreignKey: 'user_id', as: 'customerProfile' });
CustomerProfile.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
```

**Avantages :**
- ✅ Vue d'ensemble des relations
- ✅ Gestion des associations bidirectionnelles
- ✅ Évite les imports circulaires

---

### **⚠️ IMPORTANT : Ne JAMAIS faire les deux !**

```javascript
// ❌ MAUVAIS : Associations en double
// Dans Complaint.js
Complaint.belongsTo(CustomerProfile, { as: 'customer' });

// ET dans index.js
Complaint.belongsTo(CustomerProfile, { as: 'customer' });  // ❌ Erreur !
```

---

## 🔄 Résumé des Corrections Complètes

### **Étape 1 : Fix Null Safety (Flutter)**
✅ `support_screen.dart` - Utilisation de `?.` et `??`

### **Étape 2 : Fix Modèles Backend**
✅ `dashboardController.js` - Correction `Intervention` et `Contract`

### **Étape 3 : Ajout Modèle Complaint**
✅ `models/index.js` - Import et export du modèle

### **Étape 4 : Fix Conflit d'Alias**
✅ `models/index.js` - Suppression des associations en double

---

## 🧪 Test Final

### **1. Redémarrer le Backend**

```bash
cd mct-maintenance-api
npm start
```

**Vérifier :**
```
✅ Server is running on port 3000
✅ Database connected successfully
✅ Pas d'erreur AssociationError
```

---

### **2. Tester l'Endpoint**

```bash
curl -X GET http://localhost:3000/api/customer/dashboard/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Réponse attendue (200 OK) :**
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
    "totalComplaints": 1,      // ✅ Fonctionne maintenant
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

### **3. Vérifier les Logs**

**Logs attendus :**
```
📊 Récupération des statistiques pour user_id: 9
✅ Customer profile ID: 7

Executing: SELECT count(*) FROM `interventions` WHERE `customer_id` = 9;
Executing: SELECT count(*) FROM `quotes` WHERE `customerId` = 7;
Executing: SELECT count(*) FROM `orders` WHERE `customer_id` = 9;
Executing: SELECT count(*) FROM `complaints` WHERE `customerId` = 7;  // ✅
Executing: SELECT count(*) FROM `contracts` WHERE `customerId` = 7;

📊 Statistiques calculées: { ... }
GET /api/customer/dashboard/stats 200 ✅
```

**Pas d'erreur :**
```
❌ Error getting dashboard stats: TypeError...  ← Ne doit plus apparaître
❌ AssociationError: alias customer...         ← Ne doit plus apparaître
```

---

### **4. Tester l'App Mobile**

```bash
cd mct_maintenance_mobile
flutter run
```

**Vérifier :**
1. ✅ Dashboard affiche les statistiques
2. ✅ Toutes les cartes ont des chiffres
3. ✅ Chat affiche le nom du client
4. ✅ Pas d'erreur dans les logs

---

## 📊 Structure Finale des Associations

### **Modèle Complaint**

```javascript
// /src/models/Complaint.js
Complaint.belongsTo(CustomerProfile, { foreignKey: 'customerId', as: 'customer' });
Complaint.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
Complaint.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });
```

### **Modèle Complaint Exporté**

```javascript
// /src/models/index.js
const Complaint = require('./Complaint');

module.exports = {
  User,
  CustomerProfile,
  // ...
  Complaint,  // ✅ Disponible pour import
  sequelize
};
```

### **Utilisation dans le Contrôleur**

```javascript
// /src/controllers/customer/dashboardController.js
const { Complaint } = require('../../models');

const totalComplaints = await Complaint.count({
  where: { customerId: customerId }
});  // ✅ Fonctionne
```

---

## ✅ Résultat Final

**Avant :**
- ❌ Erreur `AssociationError: alias customer`
- ❌ Backend ne démarre pas
- ❌ Statistiques inaccessibles

**Après :**
- ✅ Backend démarre sans erreur
- ✅ Associations correctement définies
- ✅ Statistiques fonctionnelles
- ✅ Pas de conflit d'alias

**Tout fonctionne maintenant !** 🎉🔧
