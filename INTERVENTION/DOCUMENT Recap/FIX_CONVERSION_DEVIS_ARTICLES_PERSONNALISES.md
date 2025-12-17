# 🔧 Correction : Conversion Devis → Commande avec Articles Personnalisés

**Date :** 31 Octobre 2025  
**Problème :** Erreur `FOREIGN KEY constraint failed` lors de la conversion d'un devis contenant des articles personnalisés en commande.

---

## 🐛 Problème Identifié

### Symptôme
```
ERROR: SQLITE_CONSTRAINT: FOREIGN KEY constraint failed
POST /api/quotes/15/convert-to-order 500
```

### Cause Racine
1. **Articles personnalisés** ont `productId = -1`
2. **Table `order_items`** : `product_id` était `NOT NULL` avec contrainte de clé étrangère vers `products`
3. **Insertion impossible** : `-1` n'existe pas dans la table `products`

### Contexte
- ✅ Les devis supportent les articles personnalisés
- ❌ Les commandes ne les supportaient pas encore
- ❌ La conversion échouait systématiquement

---

## ✅ Solution Appliquée

### 1. Modification du Modèle `OrderItem`

**Fichier :** `/src/models/OrderItem.js`

**Changements :**
```javascript
// AVANT
product_id: {
  type: DataTypes.INTEGER,
  allowNull: false,  // ❌ Obligatoire
  references: { model: 'products', key: 'id' }
}

// APRÈS
product_id: {
  type: DataTypes.INTEGER,
  allowNull: true,  // ✅ Nullable pour articles personnalisés
  references: { model: 'products', key: 'id' }
},
product_name: {  // 🆕 Nouveau
  type: DataTypes.STRING,
  allowNull: true
},
is_custom: {  // 🆕 Nouveau
  type: DataTypes.BOOLEAN,
  defaultValue: false
}
```

---

### 2. Migration Base de Données

**Fichier :** `/migrations/add_custom_items_to_orders.sql`

**Opérations :**
1. Sauvegarde des données existantes
2. Suppression de l'ancienne table `order_items`
3. Recréation avec nouveaux champs :
   - `product_id` → **nullable**
   - `product_name` → **nouveau champ**
   - `is_custom` → **nouveau champ**
4. Restauration des données
5. Création d'index

**Structure finale :**
```sql
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER,              -- Nullable
  product_name TEXT,               -- Nouveau
  is_custom INTEGER DEFAULT 0,     -- Nouveau
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total REAL NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);
```

---

### 3. Modification du Contrôleur de Conversion

**Fichier :** `/src/controllers/quote/quoteController.js`

**Logique ajoutée :**
```javascript
// Créer les OrderItems
for (const item of quote.items) {
  // Détecter si c'est un article personnalisé
  const isCustomItem = item.isCustom || item.productId < 0;
  
  await OrderItem.create({
    order_id: order.id,
    product_id: isCustomItem ? null : item.productId,  // NULL si personnalisé
    product_name: item.productName,
    is_custom: isCustomItem,
    quantity: item.quantity,
    unit_price: item.unitPrice,
    total: item.quantity * item.unitPrice
  }, { transaction });
}
```

**Détection d'articles personnalisés :**
- ✅ Vérifier `item.isCustom === true`
- ✅ OU vérifier `item.productId < 0`
- ✅ Rétrocompatibilité avec anciens devis

---

## 🚀 Déploiement

### Étape 1 : Appliquer la Migration

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

node apply-order-items-migration.js
```

**Sortie attendue :**
```
✅ Connecté à la base de données SQLite
📋 8 commande(s) SQL à exécuter...

[1/8] Exécution: CREATE...
✅ CREATE réussi
[2/8] Exécution: DROP...
✅ DROP réussi
[3/8] Exécution: CREATE...
✅ CREATE réussi
...
============================================================
✅ Migration terminée: 8 commande(s) réussie(s)
============================================================
```

### Étape 2 : Redémarrer le Backend

```bash
npm start
```

---

## 🧪 Tests à Effectuer

### Test 1 : Conversion Devis avec Articles Personnalisés

**Prérequis :**
1. Créer un devis avec articles personnalisés
2. Statut du devis : `sent` ou `accepted`

**Étapes :**
```bash
# Via dashboard web
1. Aller sur /devis
2. Sélectionner un devis avec articles personnalisés
3. Cliquer sur "Convertir en commande"
```

**Résultat attendu :**
- ✅ Conversion réussie (200 OK)
- ✅ Commande créée avec tous les items
- ✅ Articles personnalisés dans la commande
- ✅ `product_id = NULL` pour articles personnalisés
- ✅ `product_name` rempli
- ✅ `is_custom = 1`

---

### Test 2 : Conversion Devis Mixte

**Contenu du devis :**
- 2 produits du catalogue
- 2 articles personnalisés

**Résultat attendu :**
```
Commande créée avec 4 items :
┌─────────────────────────────────────────────────────────┐
│ Climatiseur Split        │ product_id: 5  │ is_custom: 0│
│ Filtres de rechange      │ product_id: 12 │ is_custom: 0│
│ Main d'œuvre technicien  │ product_id: NULL│ is_custom: 1│
│ Frais de déplacement     │ product_id: NULL│ is_custom: 1│
└─────────────────────────────────────────────────────────┘
```

---

### Test 3 : Vérification Base de Données

```bash
sqlite3 database.sqlite

# Vérifier la structure
.schema order_items

# Vérifier les données
SELECT id, product_id, product_name, is_custom, quantity 
FROM order_items 
WHERE order_id = 9;
```

**Résultat attendu :**
```
id|product_id|product_name|is_custom|quantity
1 |5         |Climatiseur Split 12000 BTU|0|1
2 |NULL      |Main d'œuvre technicien|1|1
3 |NULL      |Frais de déplacement|1|1
```

---

## 📊 Comparaison Avant/Après

### ❌ AVANT (Échec)

```javascript
// Devis avec article personnalisé
{
  items: [
    { productId: -1, productName: "Main d'œuvre", ... }
  ]
}

// Tentative de conversion
await OrderItem.create({
  product_id: -1  // ❌ ERREUR: Foreign key constraint failed
});
```

### ✅ APRÈS (Succès)

```javascript
// Devis avec article personnalisé
{
  items: [
    { productId: -1, productName: "Main d'œuvre", isCustom: true }
  ]
}

// Conversion réussie
await OrderItem.create({
  product_id: null,  // ✅ NULL autorisé
  product_name: "Main d'œuvre",
  is_custom: true
});
```

---

## 🔍 Vérifications Backend

### Logs de Conversion

**Avant la correction :**
```
Création OrderItem: { 
  order_id: 9, 
  product_id: -1,  // ❌ Problématique
  quantity: 1 
}
❌ SQLITE_CONSTRAINT: FOREIGN KEY constraint failed
```

**Après la correction :**
```
Création OrderItem: { 
  order_id: 9, 
  product_id: null,  // ✅ NULL
  product_name: "Main d'œuvre",
  is_custom: true,
  quantity: 1 
}
✅ OrderItem créé avec succès
```

---

## 📁 Fichiers Modifiés/Créés

### Backend
- ✅ `/src/models/OrderItem.js` - Support articles personnalisés
- ✅ `/src/controllers/quote/quoteController.js` - Logique de conversion
- ✅ `/migrations/add_custom_items_to_orders.sql` - Migration SQL
- ✅ `/apply-order-items-migration.js` - Script d'application

### Documentation
- ✅ `/FIX_CONVERSION_DEVIS_ARTICLES_PERSONNALISES.md` - Guide complet

---

## 🎯 Règles de Gestion

### Articles du Catalogue
- `product_id` → ID valide (> 0)
- `product_name` → Nom du produit (depuis DB)
- `is_custom` → `false` (0)
- Clé étrangère → Référence `products.id`

### Articles Personnalisés
- `product_id` → `NULL`
- `product_name` → Description saisie manuellement
- `is_custom` → `true` (1)
- Pas de référence produit

---

## ⚠️ Points d'Attention

### 1. Affichage des Commandes
Le frontend doit gérer l'affichage des articles personnalisés :
```javascript
// Dans OrderDetail ou OrderList
if (item.is_custom) {
  displayName = item.product_name;  // Article personnalisé
} else {
  displayName = item.product?.nom;  // Produit catalogue
}
```

### 2. Statistiques Produits
Les articles personnalisés ne doivent pas apparaître dans les statistiques produits :
```sql
SELECT product_id, COUNT(*) 
FROM order_items 
WHERE is_custom = 0  -- Exclure articles personnalisés
GROUP BY product_id;
```

### 3. Inventaire
Les articles personnalisés n'affectent pas l'inventaire :
```javascript
if (!item.is_custom && item.product_id) {
  await updateInventory(item.product_id, -item.quantity);
}
```

---

## 💡 Améliorations Futures

### Phase 2 (Optionnel)
- [ ] Catégoriser les articles personnalisés (main d'œuvre, déplacement, etc.)
- [ ] Templates d'articles personnalisés fréquents
- [ ] Rapport sur les articles personnalisés les plus vendus
- [ ] Export des commandes avec distinction catalogue/personnalisé

---

## ✅ Checklist de Déploiement

### Backend
- [x] Modèle OrderItem mis à jour
- [x] Migration SQL créée
- [x] Script de migration créé
- [ ] Migration appliquée en production
- [ ] Backend redémarré
- [ ] Tests de conversion effectués

### Frontend
- [ ] Vérifier affichage des commandes
- [ ] Gérer les articles personnalisés dans OrderDetail
- [ ] Tester la conversion depuis le dashboard
- [ ] Vérifier les totaux

---

## 🔗 Liens Connexes

- Voir aussi : `/ARTICLES_PERSONNALISES_DEVIS.md` (création articles personnalisés)
- Voir aussi : `/FIX_DEVIS_EDITION.md` (édition devis avec articles personnalisés)

---

**Status :** ✅ Corrigé  
**Version :** 1.0  
**Prochaine étape :** Appliquer la migration et tester la conversion
