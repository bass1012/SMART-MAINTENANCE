# ✅ Fix : Contrats Affichent le Bon Utilisateur

## 🐛 Problème Identifié

**Symptôme :**
Lors de la création d'un contrat avec "Bakary Madou CISSE", la récupération affiche "Zoumana Edouard OUATTARA" (un autre utilisateur).

**Cause :**
L'endpoint `/api/customer/contracts` retournait un **tableau vide** au lieu de récupérer les contrats filtrés par l'utilisateur connecté.

```javascript
// ❌ AVANT (code incorrect)
router.get('/contracts', (req, res) => {
  res.json({
    success: true,
    message: 'Customer contracts retrieved successfully',
    data: []  // ← Retourne toujours un tableau vide !
  });
});
```

---

## ✅ Solution Appliquée

### **1. Implémentation de la Logique de Filtrage**

**Fichier modifié :** `/src/routes/customerRoutes.js`

```javascript
// ✅ APRÈS (code correct)
router.get('/contracts', async (req, res) => {
  try {
    const userId = req.user.id;  // ← Récupère l'ID de l'utilisateur connecté
    
    const contracts = await Contract.findAll({
      where: { customer_id: userId },  // ← Filtre par customer_id
      include: [
        { 
          model: User, 
          as: 'customer', 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      message: 'Customer contracts retrieved successfully',
      data: contracts  // ← Retourne les vrais contrats
    });
  } catch (error) {
    console.error('Error fetching customer contracts:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
});
```

### **2. Sécurisation de l'Endpoint de Détails**

```javascript
router.get('/contracts/:id', async (req, res) => {
  try {
    const userId = req.user.id;
    const contractId = req.params.id;
    
    const contract = await Contract.findOne({
      where: { 
        id: contractId,
        customer_id: userId  // ← Vérifie que le contrat appartient à l'utilisateur
      },
      include: [
        { 
          model: User, 
          as: 'customer', 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        }
      ]
    });

    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    res.json({
      success: true,
      message: 'Contract details retrieved successfully',
      data: contract
    });
  } catch (error) {
    console.error('Error fetching contract details:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
});
```

### **3. Ajout des Imports Nécessaires**

```javascript
const { Contract, User } = require('../models');
```

---

## 🔒 Sécurité Renforcée

**Avant :**
- ❌ Retourne un tableau vide (aucune donnée)
- ❌ Pas de filtrage par utilisateur
- ❌ Risque de voir les contrats d'autres utilisateurs

**Après :**
- ✅ Filtre par `customer_id = req.user.id`
- ✅ Chaque utilisateur voit **uniquement ses propres contrats**
- ✅ Impossible d'accéder aux contrats d'un autre utilisateur
- ✅ Vérification de propriété sur l'endpoint de détails

---

## 📊 Associations Sequelize

Les associations sont déjà correctement définies dans `/src/models/index.js` :

```javascript
// Associations contracts
Contract.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });
User.hasMany(Contract, { foreignKey: 'customer_id', as: 'contracts' });
```

**Cela permet :**
- `Contract.findAll({ include: [{ model: User, as: 'customer' }] })`
- Récupérer les informations du client (first_name, last_name, email)

---

## 🎯 Résultat

### **Avant (Problème) :**
```
1. Bakary crée un contrat → customer_id = 9
2. API retourne [] (vide)
3. Flutter affiche "Aucun contrat"
```

### **Après (Corrigé) :**
```
1. Bakary crée un contrat → customer_id = 9
2. API filtre : WHERE customer_id = 9
3. API retourne le contrat avec les infos de Bakary
4. Flutter affiche : "Bakary Madou CISSE"
```

---

## 🔧 Fichiers Modifiés

1. **`/src/routes/customerRoutes.js`**
   - Ajout de l'import `{ Contract, User }`
   - Implémentation de `GET /api/customer/contracts`
   - Implémentation de `GET /api/customer/contracts/:id`
   - Filtrage par `customer_id = req.user.id`

---

## 📱 Test dans Flutter

### **1. Redémarrer le Backend**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9 && npm start
```

### **2. Hot Restart Flutter**

```
R
```

### **3. Vérifier**

**Navigation :**
```
Dashboard → Services → "Devis et Contrat" → Onglet "Contrats"
```

**Vérifier :**
- ✅ Les contrats s'affichent
- ✅ Le nom affiché est celui de l'utilisateur connecté
- ✅ Pas de contrats d'autres utilisateurs
- ✅ Pull-to-refresh fonctionne

---

## 🧪 Test API Direct

### **Test 1 : Récupérer les Contrats**

```bash
curl -X GET http://localhost:3000/api/customer/contracts \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Réponse attendue :**
```json
{
  "success": true,
  "message": "Customer contracts retrieved successfully",
  "data": [
    {
      "id": 1,
      "reference": "CONT-2025-001",
      "title": "Contrat maintenance annuel",
      "customer_id": 9,
      "status": "active",
      "customer": {
        "id": 9,
        "first_name": "Bakary Madou",
        "last_name": "CISSE",
        "email": "cisse.bakary@gmail.com"
      }
    }
  ]
}
```

### **Test 2 : Récupérer un Contrat Spécifique**

```bash
curl -X GET http://localhost:3000/api/customer/contracts/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Réponse attendue :**
```json
{
  "success": true,
  "message": "Contract details retrieved successfully",
  "data": {
    "id": 1,
    "reference": "CONT-2025-001",
    "customer": {
      "first_name": "Bakary Madou",
      "last_name": "CISSE"
    }
  }
}
```

---

## 🔍 Logs Backend Attendus

```
GET /api/customer/contracts
Executing: SELECT * FROM `contracts` WHERE `customer_id` = 9;
Executing: SELECT * FROM `users` WHERE `id` = 9;
✅ 1 contrat(s) trouvé(s) pour user_id: 9
GET /api/customer/contracts 200 ✅
```

---

## ⚠️ Problème Similaire sur les Commandes

**Note :** Le même problème existe probablement sur les commandes. Il faudra vérifier et corriger de la même manière :

```javascript
// À vérifier dans customerRoutes.js
router.get('/orders', async (req, res) => {
  const userId = req.user.id;
  const orders = await Order.findAll({
    where: { customerId: userId }  // ← Filtrer par utilisateur
  });
});
```

---

## ✅ Checklist de Vérification

- [x] Import des modèles Contract et User
- [x] Filtrage par customer_id dans GET /contracts
- [x] Filtrage par customer_id dans GET /contracts/:id
- [x] Associations Sequelize définies
- [x] Gestion des erreurs
- [x] Vérification de propriété (sécurité)
- [ ] Redémarrer le backend
- [ ] Tester dans Flutter
- [ ] Vérifier les logs

---

## 🎉 Résumé

**Problème :** Endpoint retournait un tableau vide, pas de filtrage par utilisateur.

**Solution :** Implémentation de la logique de filtrage avec `where: { customer_id: req.user.id }`.

**Résultat :** Chaque utilisateur voit uniquement ses propres contrats avec les bonnes informations.

---

**Redémarre le backend et teste !** 🚀✅
