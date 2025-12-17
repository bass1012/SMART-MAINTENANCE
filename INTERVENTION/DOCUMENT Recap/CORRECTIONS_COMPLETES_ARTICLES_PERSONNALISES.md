# ✅ Corrections Complètes : Articles Personnalisés dans Devis et Commandes

**Date :** 31 Octobre 2025  
**Statut :** Toutes les corrections appliquées, redémarrage serveur requis

---

## 📋 Résumé des 3 Problèmes Résolus

### 1. ✅ Affichage "-1" lors de l'édition de devis
**Fichier :** `/mct-maintenance-dashboard/src/pages/quotes/QuoteForm.tsx`
- Chargement corrigé avec définition de `isCustom`
- Double vérification : `isCustom || productId < 0`
- Type TypeScript ajouté pour éviter erreurs

### 2. ✅ Conversion devis → commande (Foreign Key)
**Fichiers :** 
- `/mct-maintenance-api/src/models/OrderItem.js`
- `/mct-maintenance-api/src/controllers/quote/quoteController.js`
- Migration : `fix-order-items-schema.js`
- Table `order_items` restructurée avec `product_id` nullable

### 3. ✅ Colonne is_custom manquante dans quote_items
**Fichiers :**
- Migration : `fix-quote-items-schema.js`
- `/mct-maintenance-api/src/models/QuoteItem.js`
- Table `quote_items` avec colonne `is_custom` ajoutée
- Mapping Sequelize corrigé

---

## 🗂️ Migrations Appliquées

### Migration 1 : Table `order_items`

```sql
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER,              -- ✅ Nullable
  product_name TEXT,               -- ✅ Nouveau
  is_custom INTEGER DEFAULT 0,     -- ✅ Nouveau
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total REAL NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);
```

**Script :** `fix-order-items-schema.js` ✅ Appliquée
**Statut :** ✅ Réussie

---

### Migration 2 : Table `quote_items`

```sql
CREATE TABLE quote_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quoteId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  productName TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  discount REAL DEFAULT 0,
  taxRate REAL DEFAULT 20,
  is_custom INTEGER DEFAULT 0,     -- ✅ Nouveau
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (quoteId) REFERENCES quotes(id) ON DELETE CASCADE
);
```

**Script :** `fix-quote-items-schema.js` ✅ Appliquée
**Statut :** ✅ Réussie

---

## 📊 Structures Finales

### Table `quote_items`
```
┌────────────────────────────────────────────────────┐
│ Champ       │ Type    │ Nullable │ Default       │
├────────────────────────────────────────────────────┤
│ id          │ INTEGER │ No       │ AUTOINCREMENT │
│ quoteId     │ INTEGER │ No       │ -             │
│ productId   │ INTEGER │ No       │ -             │
│ productName │ TEXT    │ No       │ -             │
│ quantity    │ INTEGER │ No       │ -             │
│ unitPrice   │ REAL    │ No       │ -             │
│ discount    │ REAL    │ Yes      │ 0             │
│ taxRate     │ REAL    │ Yes      │ 20            │
│ is_custom   │ INTEGER │ Yes      │ 0             │ ✅
│ created_at  │ TEXT    │ Yes      │ NULL          │
│ updated_at  │ TEXT    │ Yes      │ NULL          │
└────────────────────────────────────────────────────┘
```

### Table `order_items`
```
┌────────────────────────────────────────────────────┐
│ Champ        │ Type    │ Nullable │ Default       │
├────────────────────────────────────────────────────┤
│ id           │ INTEGER │ No       │ AUTOINCREMENT │
│ order_id     │ INTEGER │ No       │ -             │
│ product_id   │ INTEGER │ Yes      │ NULL          │ ✅
│ product_name │ TEXT    │ Yes      │ NULL          │ ✅
│ is_custom    │ INTEGER │ Yes      │ 0             │ ✅
│ quantity     │ INTEGER │ No       │ -             │
│ unit_price   │ REAL    │ No       │ -             │
│ total        │ REAL    │ No       │ -             │
└────────────────────────────────────────────────────┘
```

---

## 🔧 Modifications de Code

### Backend

#### 1. `/src/models/QuoteItem.js`
```javascript
isCustom: { 
  type: DataTypes.BOOLEAN, 
  defaultValue: false, 
  field: 'is_custom'  // ✅ Corrigé (était 'isCustom')
}
```

#### 2. `/src/models/OrderItem.js`
```javascript
product_id: {
  type: DataTypes.INTEGER,
  allowNull: true,  // ✅ Nullable
  references: { model: 'products', key: 'id' }
},
product_name: {  // ✅ Nouveau
  type: DataTypes.STRING,
  allowNull: true
},
is_custom: {  // ✅ Nouveau
  type: DataTypes.BOOLEAN,
  defaultValue: false
}
```

#### 3. `/src/controllers/quote/quoteController.js`
```javascript
// Créer les OrderItems
for (const item of quote.items) {
  const isCustomItem = item.isCustom || item.productId < 0;
  
  await OrderItem.create({
    order_id: order.id,
    product_id: isCustomItem ? null : item.productId,  // ✅
    product_name: item.productName,  // ✅
    is_custom: isCustomItem,  // ✅
    quantity: item.quantity,
    unit_price: item.unitPrice,
    total: item.quantity * item.unitPrice
  }, { transaction });
}
```

---

### Frontend

#### `/src/pages/quotes/QuoteForm.tsx`

**Chargement des items :**
```typescript
const loadedItems = (quoteData.items || []).map((item: QuoteItem) => ({
  ...item,
  isCustom: item.isCustom || item.productId === -1 || item.productId < 0
}));
```

**Rendu conditionnel :**
```typescript
if (record.isCustom || record.productId < 0) {
  return <Input ... />;  // Article personnalisé
}
return <Select ... />;   // Produit catalogue
```

---

## ⚡ Action Immédiate Requise

### REDÉMARRER LE SERVEUR BACKEND

Les modèles Sequelize ont été modifiés et doivent être rechargés.

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Arrêter le serveur
lsof -ti:3000 | xargs kill -9

# Redémarrer
npm start
```

**Attendez ce message :**
```
✅ Serveur démarré sur le port 3000
✅ Base de données connectée
```

---

## 🧪 Plan de Tests Complet

### Test 1 : Liste des Devis (GET /api/quotes)

```bash
curl http://localhost:3000/api/quotes?search= \
  -H "Authorization: Bearer TOKEN"
```

**Avant :** ❌ 500 - `no such column: items.isCustom`  
**Après :** ✅ 200 - Liste des devis avec items

---

### Test 2 : Création de Devis avec Articles Personnalisés

**Dashboard Web : http://localhost:3001/devis/nouveau**

```
Actions :
1. ✅ Ajouter "Produit du catalogue" → Climatiseur
2. ✅ Ajouter "Article personnalisé" → "Main d'œuvre 4h"
3. ✅ Quantité : 1, Prix : 80000
4. ✅ Sauvegarder

Résultat attendu :
- Devis créé avec 2 items
- Article personnalisé : productId = -1, is_custom = 1
```

---

### Test 3 : Édition de Devis

**Dashboard Web : http://localhost:3001/devis**

```
Actions :
1. ✅ Cliquer "Modifier" sur un devis existant
2. ✅ Vérifier affichage des articles personnalisés (Input, pas "-1")
3. ✅ Modifier description
4. ✅ Sauvegarder

Résultat attendu :
- Pas d'erreur console
- Articles personnalisés modifiables
- Modifications persistées
```

---

### Test 4 : Conversion Devis → Commande

**Dashboard Web : http://localhost:3001/devis**

```
Actions :
1. ✅ Sélectionner un devis avec articles personnalisés
2. ✅ Cliquer "Convertir en commande"
3. ✅ Attendre confirmation
4. ✅ Vérifier la commande créée

Résultat attendu :
- Status : 200 OK (pas 500)
- Commande créée avec tous les items
- Articles personnalisés : product_id = NULL, product_name rempli
```

---

### Test 5 : Vérification Base de Données

```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite
```

```sql
-- Vérifier quote_items
SELECT id, productId, productName, is_custom 
FROM quote_items 
WHERE is_custom = 1 
LIMIT 3;

-- Vérifier order_items
SELECT id, product_id, product_name, is_custom 
FROM order_items 
WHERE is_custom = 1 
LIMIT 3;
```

**Résultat attendu :**
```
-- quote_items
id|productId|productName|is_custom
1 |-1       |Main d'œuvre|1

-- order_items
id|product_id|product_name|is_custom
1 |NULL      |Main d'œuvre|1
```

---

## 📈 Flux Complet : Devis → Commande

### Étape 1 : Création du Devis
```
Frontend envoie :
{
  items: [
    { productId: 5, productName: "Climatiseur", isCustom: false },
    { productId: -1, productName: "Installation", isCustom: true }
  ]
}

↓

Backend insère dans quote_items :
| id | productId | productName  | is_custom |
|----|-----------|--------------|-----------|
| 1  | 5         | Climatiseur  | 0         |
| 2  | -1        | Installation | 1         |
```

---

### Étape 2 : Conversion en Commande
```
Backend lit quote_items :
[
  { productId: 5, productName: "Climatiseur", isCustom: false },
  { productId: -1, productName: "Installation", isCustom: true }
]

↓

Backend insère dans order_items :
| id | product_id | product_name | is_custom |
|----|------------|--------------|-----------|
| 1  | 5          | Climatiseur  | 0         |
| 2  | NULL       | Installation | 1         | ← productId devient NULL
```

---

## ✅ Checklist Complète

### Migrations Base de Données
- [x] Migration `quote_items` appliquée
- [x] Migration `order_items` appliquée
- [x] Données existantes préservées
- [x] Index créés

### Modifications Backend
- [x] Modèle `QuoteItem` corrigé
- [x] Modèle `OrderItem` corrigé
- [x] Contrôleur de conversion modifié
- [ ] Serveur redémarré (ACTION UTILISATEUR)

### Modifications Frontend
- [x] `QuoteForm.tsx` corrigé (chargement)
- [x] `QuoteForm.tsx` corrigé (rendu)
- [x] Type TypeScript ajouté
- [x] Interface `QuoteItem` mise à jour

### Tests
- [ ] GET /api/quotes (200 OK)
- [ ] Création devis avec articles personnalisés
- [ ] Édition devis
- [ ] Conversion devis → commande
- [ ] Vérification DB

---

## 📚 Documentation Créée

### Guides Techniques
1. **`ARTICLES_PERSONNALISES_DEVIS.md`**
   - Guide complet fonctionnalité
   - Exemples d'utilisation
   - Documentation utilisateur

2. **`FIX_DEVIS_EDITION.md`**
   - Correction affichage "-1"
   - Explication technique détaillée

3. **`FIX_CONVERSION_DEVIS_ARTICLES_PERSONNALISES.md`**
   - Migration `order_items`
   - Correction conversion

4. **`FIX_QUOTE_ITEMS_IS_CUSTOM.md`**
   - Migration `quote_items`
   - Correction modèle Sequelize

5. **`CORRECTIONS_COMPLETES_ARTICLES_PERSONNALISES.md`** (ce fichier)
   - Vue d'ensemble complète
   - Plan de tests
   - Checklist finale

---

## 🎯 Prochaines Actions (Par Ordre de Priorité)

### Immédiat (CRITIQUE)
1. **Redémarrer le serveur backend**
   ```bash
   cd mct-maintenance-api && npm start
   ```

2. **Tester GET /api/quotes**
   - Doit retourner 200 OK
   - Liste des devis avec items

---

### Court Terme (Aujourd'hui)
3. **Tester création/édition de devis**
   - Articles personnalisés fonctionnels
   - Pas d'erreur console

4. **Tester conversion devis → commande**
   - Avec articles personnalisés
   - Vérifier commande créée

---

### Moyen Terme (Cette Semaine)
5. **Améliorer l'affichage des commandes**
   - Indicateur visuel pour articles personnalisés
   - Icône ✎ ou badge "Personnalisé"

6. **Statistiques séparées**
   - Produits catalogue vs personnalisés
   - Rapport sur les plus vendus

---

## 🔗 Commandes Utiles

```bash
# Redémarrer backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9 && npm start

# Tester API
curl http://localhost:3000/api/quotes?search=

# Vérifier DB
sqlite3 database.sqlite "PRAGMA table_info(quote_items);"
sqlite3 database.sqlite "PRAGMA table_info(order_items);"

# Voir articles personnalisés
sqlite3 database.sqlite "SELECT * FROM quote_items WHERE is_custom = 1;"
sqlite3 database.sqlite "SELECT * FROM order_items WHERE is_custom = 1;"
```

---

## 📊 Résumé Visuel

```
┌─────────────────────────────────────────────────────────────┐
│                   ARTICLES PERSONNALISÉS                    │
│                   Système Complet ✅                        │
└─────────────────────────────────────────────────────────────┘

Frontend (React)                Backend (Node.js)
     │                               │
     │  1. Création Devis            │
     │─────────────────────────────>│
     │  { isCustom: true }           │
     │                               │──> quote_items
     │                               │    (is_custom = 1)
     │                               │
     │  2. Édition Devis             │
     │<─────────────────────────────│
     │  Affiche Input (pas -1) ✅    │<── quote_items
     │                               │    (charge is_custom)
     │                               │
     │  3. Conversion                │
     │─────────────────────────────>│
     │                               │
     │                               │──> order_items
     │                               │    (product_id = NULL)
     │                               │    (is_custom = 1)
     │                               │
     │  4. Commande Créée ✅         │
     │<─────────────────────────────│
     │                               │

┌─────────────────────────────────────────────────────────────┐
│  Base de Données SQLite                                     │
├─────────────────────────────────────────────────────────────┤
│  ✅ quote_items.is_custom (INTEGER DEFAULT 0)               │
│  ✅ order_items.is_custom (INTEGER DEFAULT 0)               │
│  ✅ order_items.product_id (INTEGER NULL)                   │
│  ✅ order_items.product_name (TEXT NULL)                    │
└─────────────────────────────────────────────────────────────┘
```

---

**Version :** 1.0  
**Date :** 31 Octobre 2025 08:54 UTC  
**Statut :** ✅ Toutes migrations appliquées, redémarrage serveur requis  
**Prochaine action :** `npm start` dans `/mct-maintenance-api`
