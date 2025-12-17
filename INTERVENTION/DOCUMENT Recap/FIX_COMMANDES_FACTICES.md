# 🔧 Fix : Commandes Affichent des Données Factices

## ❌ Problème

L'application mobile affiche les commandes, mais **ce sont des données factices** (données de démo) au lieu des vraies commandes de la base de données.

---

## 🔍 Cause du Problème

### **Routes Backend Non Implémentées**

**Fichier :** `/src/routes/customerRoutes.js`

Les routes `/api/customer/orders` et `/api/customer/orders/:id` retournaient des données vides :

```javascript
// ❌ AVANT (Données factices)
router.get('/orders', (req, res) => {
  res.json({
    success: true,
    message: 'Customer orders retrieved successfully',
    data: [] // ← Tableau vide !
  });
});
```

**Résultat :**
- L'application mobile reçoit `data: []`
- En cas d'erreur ou de données vides, le code mobile affiche des données de démo
- Les vraies commandes de la base ne sont jamais récupérées

---

## ✅ Solution

### **Implémentation des Vraies Routes**

**Fichier :** `/src/routes/customerRoutes.js`

#### **1. Route GET `/api/customer/orders`**

Récupère toutes les commandes du client connecté :

```javascript
router.get('/orders', async (req, res) => {
  try {
    const { Order, OrderItem, Product, User } = require('../models');
    const userId = req.user.id;
    
    console.log(`📦 Récupération des commandes pour user_id: ${userId}`);
    
    // Récupérer toutes les commandes du client
    const orders = await Order.findAll({
      where: { customerId: userId },
      include: [
        { 
          model: OrderItem, 
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ],
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ ${orders.length} commandes trouvées`);
    
    // Formater les données pour le mobile
    const formattedOrders = orders.map(order => ({
      id: order.id,
      reference: order.reference,
      customerId: order.customerId,
      totalAmount: order.totalAmount,
      status: order.status,
      notes: order.notes,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items?.map(item => ({
        id: item.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unit_price || item.unitPrice,
        total: item.total,
        product: item.product ? {
          id: item.product.id,
          name: item.product.name,
          description: item.product.description,
          price: item.product.price,
          imageUrl: item.product.imageUrl
        } : null
      })) || []
    }));
    
    res.json({
      success: true,
      message: 'Commandes récupérées avec succès',
      data: formattedOrders
    });
  } catch (error) {
    console.error('❌ Error fetching orders:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message
    });
  }
});
```

**Fonctionnalités :**
- ✅ Récupère les commandes du client (`customerId = userId`)
- ✅ Inclut les articles de chaque commande (`OrderItem`)
- ✅ Inclut les détails des produits (`Product`)
- ✅ Trie par date décroissante (plus récentes en premier)
- ✅ Formate les données pour le mobile
- ✅ Gestion des erreurs

---

#### **2. Route GET `/api/customer/orders/:id`**

Récupère les détails d'une commande spécifique :

```javascript
router.get('/orders/:id', async (req, res) => {
  try {
    const { Order, OrderItem, Product, User } = require('../models');
    const userId = req.user.id;
    const orderId = req.params.id;
    
    console.log(`📦 Récupération de la commande ${orderId} pour user_id: ${userId}`);
    
    // Récupérer la commande avec ses items
    const order = await Order.findOne({
      where: { 
        id: orderId,
        customerId: userId 
      },
      include: [
        { 
          model: OrderItem, 
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        },
        { model: User, as: 'customer' }
      ]
    });
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }
    
    console.log(`✅ Commande ${orderId} trouvée`);
    
    // Formater les données
    const formattedOrder = {
      id: order.id,
      reference: order.reference,
      customerId: order.customerId,
      totalAmount: order.totalAmount,
      status: order.status,
      notes: order.notes,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      customer: order.customer ? {
        id: order.customer.id,
        firstName: order.customer.firstName,
        lastName: order.customer.lastName,
        email: order.customer.email
      } : null,
      items: order.items?.map(item => ({
        id: item.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unit_price || item.unitPrice,
        total: item.total,
        product: item.product ? {
          id: item.product.id,
          name: item.product.name,
          description: item.product.description,
          price: item.product.price,
          imageUrl: item.product.imageUrl
        } : null
      })) || []
    };
    
    res.json({
      success: true,
      message: 'Commande récupérée avec succès',
      data: formattedOrder
    });
  } catch (error) {
    console.error('❌ Error fetching order:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la commande',
      error: error.message
    });
  }
});
```

**Fonctionnalités :**
- ✅ Récupère une commande spécifique par ID
- ✅ Vérifie que la commande appartient au client
- ✅ Inclut les informations du client
- ✅ Inclut tous les articles et produits
- ✅ Retourne 404 si la commande n'existe pas
- ✅ Gestion des erreurs

---

## 📊 Données Retournées

### **Exemple de Réponse API**

```json
{
  "success": true,
  "message": "Commandes récupérées avec succès",
  "data": [
    {
      "id": 6,
      "reference": null,
      "customerId": 9,
      "totalAmount": 750000,
      "status": "pending",
      "notes": null,
      "shippingAddress": null,
      "paymentMethod": null,
      "createdAt": "2025-10-22T16:52:58.998Z",
      "updatedAt": "2025-10-22T16:52:58.998Z",
      "items": [
        {
          "id": 13,
          "productId": 1,
          "quantity": 1,
          "unitPrice": 350000,
          "total": 350000,
          "product": {
            "id": 1,
            "name": "Split Mural Inverter CARRIER",
            "description": "Le split Mural Inverter CARRIER...",
            "price": 350000,
            "imageUrl": "/uploads/products/carrier-split.jpg"
          }
        }
      ]
    },
    {
      "id": 4,
      "reference": "CMD-1761052570922",
      "customerId": 9,
      "totalAmount": 3020000,
      "status": "pending",
      "notes": "test modifier",
      "shippingAddress": "Cocody",
      "paymentMethod": "Carte",
      "createdAt": "2025-10-21T13:16:10.932Z",
      "updatedAt": "2025-10-22T11:21:48.378Z",
      "items": [
        {
          "id": 12,
          "productId": 2,
          "quantity": 1,
          "unitPrice": 755000,
          "total": 755000,
          "product": {
            "id": 2,
            "name": "Split Allège CARRIER",
            "description": "Les splits allège CARRIER...",
            "price": 755000,
            "imageUrl": "/uploads/products/carrier-allege.jpg"
          }
        },
        {
          "id": 11,
          "productId": 4,
          "quantity": 3,
          "unitPrice": 755000,
          "total": 2265000,
          "product": {
            "id": 4,
            "name": "Console CARRIER",
            "description": "La nouvelle gamme de console...",
            "price": 755000,
            "imageUrl": "/uploads/products/carrier-console.jpg"
          }
        }
      ]
    }
  ]
}
```

---

## 🔄 Flux Complet

### **Avant le Fix**

```
Application Mobile
    ↓
Appel API: GET /api/customer/orders
    ↓
Backend retourne: { data: [] }
    ↓
Mobile reçoit un tableau vide
    ↓
En cas d'erreur → Affiche données de démo
    ↓
❌ Utilisateur voit des commandes factices
```

### **Après le Fix**

```
Application Mobile
    ↓
Appel API: GET /api/customer/orders
    ↓
Backend interroge la base de données
    ↓
Récupère les commandes du client (user_id = 9)
    ↓
Inclut les articles et produits
    ↓
Formate et retourne les données
    ↓
Mobile reçoit les vraies commandes
    ↓
✅ Utilisateur voit ses vraies commandes
```

---

## 🧪 Test

### **1. Tester l'API Backend**

```bash
# Se connecter et récupérer le token JWT
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Récupérer toutes les commandes
curl -X GET http://localhost:3000/api/customer/orders \
  -H "Authorization: Bearer $TOKEN"

# Résultat attendu
{
  "success": true,
  "message": "Commandes récupérées avec succès",
  "data": [
    {
      "id": 6,
      "reference": null,
      "totalAmount": 750000,
      "status": "pending",
      ...
    }
  ]
}
```

**Logs Backend :**
```
📦 Récupération des commandes pour user_id: 9
✅ 5 commandes trouvées
```

---

### **2. Tester l'Application Mobile**

1. **Relancer l'app mobile**
   ```bash
   cd mct_maintenance_mobile
   flutter run
   ```

2. **Se connecter**
   - Email : `cisse.bakary@gmail.com`
   - Mot de passe : [votre mot de passe]

3. **Accéder aux commandes**
   - Cliquer sur la carte "Commandes" dans le dashboard
   - OU Menu ☰ → "Historique" → Onglet "Commandes"

4. **Vérifier**
   - ✅ Les vraies commandes s'affichent
   - ✅ Références correctes (CMD-XXX)
   - ✅ Montants corrects en FCFA
   - ✅ Statuts corrects
   - ✅ Dates correctes

5. **Tester le détail**
   - Cliquer sur une commande
   - ✅ Détails complets affichés
   - ✅ Liste des articles visible
   - ✅ Noms des produits corrects
   - ✅ Quantités et prix corrects

---

## 📝 Fichiers Modifiés

### **Backend**

**Fichier :** `/src/routes/customerRoutes.js`

**Changements :**
1. ✅ Route `GET /orders` - Implémentation complète
2. ✅ Route `GET /orders/:id` - Implémentation complète
3. ✅ Requêtes Sequelize avec `include` pour les relations
4. ✅ Formatage des données pour le mobile
5. ✅ Gestion des erreurs avec try/catch
6. ✅ Logs de débogage

**Lignes modifiées :** 381-526

---

## 📊 Comparaison

### **Avant**

| Élément | Valeur |
|---------|--------|
| **Endpoint** | `GET /api/customer/orders` |
| **Données retournées** | `[]` (vide) |
| **Commandes affichées** | Données de démo factices |
| **Articles** | Aucun |
| **Produits** | Aucun |

### **Après**

| Élément | Valeur |
|---------|--------|
| **Endpoint** | `GET /api/customer/orders` |
| **Données retournées** | Vraies commandes de la BDD |
| **Commandes affichées** | 5 commandes réelles |
| **Articles** | Tous les articles de chaque commande |
| **Produits** | Détails complets (nom, prix, description) |

---

## 🎯 Résultat

### **Données Affichées**

**Commande #6 :**
- Référence : (null)
- Montant : 750 000 FCFA
- Statut : En attente
- Articles : 1 × Split Mural Inverter CARRIER

**Commande #4 :**
- Référence : CMD-1761052570922
- Montant : 3 020 000 FCFA
- Statut : En attente
- Adresse : Cocody
- Paiement : Carte
- Articles :
  - 1 × Split Allège CARRIER (755 000 FCFA)
  - 3 × Console CARRIER (2 265 000 FCFA)

**Commande #3 :**
- Référence : CMD-1761047914086
- Montant : 1 185 000 FCFA
- Statut : En attente
- Articles :
  - 1 × Split Allège CARRIER (755 000 FCFA)
  - 1 × Climatiseur LK ELECTRONICS (430 000 FCFA)

**Commande #1 :**
- Référence : CMD-1760650389056
- Montant : 7 550 000 FCFA
- Statut : En attente
- Adresse : Yopougon
- Paiement : Espèce
- Articles : 10 × Split Allège CARRIER (7 550 000 FCFA)

---

## ✅ Checklist

- ✅ Routes backend implémentées
- ✅ Requêtes à la base de données fonctionnelles
- ✅ Relations (OrderItem, Product) incluses
- ✅ Formatage des données correct
- ✅ Gestion des erreurs
- ✅ Logs de débogage
- ✅ Serveur redémarré
- ✅ API testée avec curl
- ✅ Application mobile affiche les vraies données
- ✅ Détails des commandes complets
- ✅ Articles et produits visibles

---

## 🚀 Déploiement

### **Étapes Appliquées**

1. ✅ Modification de `customerRoutes.js`
2. ✅ Redémarrage du serveur
   ```bash
   lsof -ti:3000 | xargs kill -9
   npm start
   ```
3. ✅ Test de l'API avec curl
4. ✅ Vérification dans l'application mobile

---

## 🎉 Résultat Final

**Avant :**
- ❌ Commandes factices (données de démo)
- ❌ Aucune vraie donnée de la base
- ❌ Articles vides

**Après :**
- ✅ Vraies commandes de la base de données
- ✅ Toutes les informations correctes
- ✅ Articles et produits complets
- ✅ Références, montants, statuts corrects
- ✅ Navigation et détails fonctionnels

**Le problème est résolu !** 🎉 Les commandes affichent maintenant les vraies données de la base de données.
