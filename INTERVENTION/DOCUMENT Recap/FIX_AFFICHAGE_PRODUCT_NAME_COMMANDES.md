# 🔧 Correction : Affichage du Nom des Produits dans les Commandes

**Date :** 31 Octobre 2025  
**Problème :** Après conversion devis → commande, les noms des produits ne s'affichaient pas

---

## 🐛 Symptôme

Lorsqu'on convertit un devis en commande, les articles de la commande apparaissent sans nom dans le dashboard :

```
Détails de la Commande #9

Articles:
x 1 — 10000 CFA       ← Nom du produit manquant !
x 1 — 1200000 CFA      ← Nom du produit manquant !
```

**Attendu :**
```
Articles:
Main d'œuvre x 1 — 10000 CFA
Climatiseur Split x 1 — 1200000 CFA
```

---

## 🔍 Cause du Problème

### Incohérence Naming Frontend/Backend

**Backend (Sequelize/SQLite) :**
- Modèle `OrderItem` utilise `snake_case` : `product_name`
- Configuration : `underscored: true`
- Colonne DB : `product_name`

**Frontend (React/TypeScript) :**
- Code utilisait `camelCase` : `item.productName`
- Fonctionnait pour produits du catalogue : `item.product?.nom`
- **Échouait pour articles personnalisés** : `item.productName` n'existe pas

### Pourquoi ça échouait ?

```typescript
// OrderDetail.tsx (ligne 462)
{item.product?.nom || item.productName}
//                     ^^^^^^^^^^^^^^^^ undefined pour articles personnalisés !
```

**Pour les produits du catalogue :**
- `product_id` → valeur valide (ex: 5)
- Association `Product` → chargée
- `item.product?.nom` → ✅ Fonctionne

**Pour les articles personnalisés :**
- `product_id` → `NULL`
- Association `Product` → `null`
- `item.product?.nom` → `undefined`
- `item.productName` → `undefined` (n'existe pas)
- `item.product_name` → ✅ **Existe mais non utilisé !**

---

## ✅ Solution Appliquée

### Ajout du Fallback vers `product_name`

**Fichier :** `/mct-maintenance-dashboard/src/pages/orders/OrderDetail.tsx`

#### 1. Initialisation des editItems (ligne 261)

```typescript
// AVANT
productName: item.product?.nom || item.productName,

// APRÈS
productName: item.product?.nom || item.product_name || item.productName,
//                                 ^^^^^^^^^^^^^^^^^ Ajouté
```

**Ordre de priorité :**
1. `item.product?.nom` → Produit du catalogue
2. `item.product_name` → Article personnalisé (nouveau)
3. `item.productName` → Fallback legacy

---

#### 2. Affichage des articles (ligne 462)

```typescript
// AVANT
<Text>
  {item.product?.nom || item.productName} x {item.quantity} — {item.total} CFA
</Text>

// APRÈS
<Text>
  {item.product?.nom || item.product_name || item.productName} x {item.quantity} — {item.total} CFA
//                     ^^^^^^^^^^^^^^^^^ Ajouté
</Text>
```

---

## 🎯 Logique d'Affichage Complète

```typescript
const displayName = 
  item.product?.nom ||      // 1. Produit catalogue (association)
  item.product_name ||      // 2. Article personnalisé (colonne directe)
  item.productName ||       // 3. Legacy fallback
  'Produit inconnu';        // 4. Défaut si tout échoue
```

---

## 📊 Exemples de Données

### Commande avec Produit Catalogue

**Backend renvoie :**
```json
{
  "id": 1,
  "order_id": 9,
  "product_id": 5,
  "product_name": "Climatiseur Split 12000 BTU",
  "is_custom": 0,
  "quantity": 1,
  "unit_price": 1200000,
  "total": 1200000,
  "product": {
    "id": 5,
    "nom": "Climatiseur Split 12000 BTU",
    "prix": 1200000
  }
}
```

**Affichage Frontend :**
```
Climatiseur Split 12000 BTU x 1 — 1200000 CFA
```

**Source du nom :** `item.product.nom` ✅

---

### Commande avec Article Personnalisé

**Backend renvoie :**
```json
{
  "id": 2,
  "order_id": 9,
  "product_id": null,
  "product_name": "Main d'œuvre technicien 4h",
  "is_custom": 1,
  "quantity": 1,
  "unit_price": 80000,
  "total": 80000,
  "product": null
}
```

**Affichage Frontend :**
```
Main d'œuvre technicien 4h x 1 — 80000 CFA
```

**Source du nom :** `item.product_name` ✅

---

## 🧪 Tests de Validation

### Test 1 : Conversion Devis → Commande

**Prérequis :**
- Créer un devis avec 1 produit catalogue + 1 article personnalisé

**Étapes :**
```bash
1. Dashboard web → /devis
2. Créer nouveau devis :
   - Ajouter "Climatiseur Split" (catalogue)
   - Ajouter "Installation + test" (personnalisé)
3. Sauvegarder le devis
4. Cliquer "Convertir en commande"
5. Aller sur /commandes
6. Voir les détails de la commande
```

**Résultat attendu :**
```
Articles:
✅ Climatiseur Split x 1 — 1200000 CFA
✅ Installation + test x 1 — 50000 CFA
```

---

### Test 2 : Affichage Commande Existante

**Étapes :**
```bash
1. Dashboard web → /commandes
2. Cliquer sur une commande avec articles personnalisés
3. Vérifier l'affichage
```

**Résultat attendu :**
- ✅ Tous les noms de produits s'affichent
- ✅ Aucun article vide

---

### Test 3 : Édition de Commande

**Étapes :**
```bash
1. Dashboard web → /commandes → Détail commande
2. Cliquer "Modifier"
3. Vérifier que les noms s'affichent dans editItems
4. Sauvegarder
```

**Résultat attendu :**
- ✅ Les noms restent visibles en mode édition
- ✅ Les modifications sont sauvegardées

---

## 🔄 Flux Complet

```
┌─────────────────────────────────────────────────────┐
│  DEVIS                                              │
│                                                     │
│  Items:                                             │
│    - Climatiseur (productId: 5)                    │
│    - Main d'œuvre (productId: -1, isCustom: true)  │
└─────────────────────────────────────────────────────┘
                      │
                      │ Conversion
                      ▼
┌─────────────────────────────────────────────────────┐
│  COMMANDE (Backend)                                 │
│                                                     │
│  OrderItems:                                        │
│    1. product_id: 5                                │
│       product_name: "Climatiseur..."               │
│       is_custom: 0                                  │
│       product: { nom: "Climatiseur..." }           │
│                                                     │
│    2. product_id: NULL                             │
│       product_name: "Main d'œuvre..."              │
│       is_custom: 1                                  │
│       product: null                                 │
└─────────────────────────────────────────────────────┘
                      │
                      │ GET /api/orders/:id
                      ▼
┌─────────────────────────────────────────────────────┐
│  FRONTEND (Affichage)                               │
│                                                     │
│  Item 1:                                            │
│    displayName = item.product?.nom                 │
│                = "Climatiseur..." ✅               │
│                                                     │
│  Item 2:                                            │
│    displayName = item.product?.nom || item.product_name
│                = null || "Main d'œuvre..." ✅       │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Checklist de Vérification

- [x] Correction ligne 261 (editItems)
- [x] Correction ligne 462 (affichage)
- [ ] Test conversion devis → commande
- [ ] Test affichage commandes existantes
- [ ] Test édition de commande
- [ ] Vérification console (pas d'erreurs)

---

## 💡 Leçons Apprises

### 1. Cohérence Naming

**Toujours vérifier le mapping entre frontend et backend :**

| Backend (Sequelize) | Frontend (React) | Solution |
|---------------------|------------------|----------|
| `product_name` | `productName` | Utiliser les deux ! |
| `snake_case` | `camelCase` | Fallback multiple |

### 2. Gestion des Articles Personnalisés

**Toujours prévoir un fallback pour les associations NULL :**

```typescript
// ❌ Mauvais
const name = item.product.nom;  // Crash si product === null

// ✅ Bon
const name = item.product?.nom || item.product_name || 'Inconnu';
```

### 3. Underscored dans Sequelize

Quand `underscored: true` :
- Les champs du modèle sont en `camelCase`
- Les colonnes DB sont en `snake_case`
- Les réponses JSON utilisent `snake_case` par défaut

---

## 🔗 Fichiers Modifiés

### Frontend
- ✅ `/mct-maintenance-dashboard/src/pages/orders/OrderDetail.tsx`
  - Ligne 261 : Initialisation editItems
  - Ligne 462 : Affichage articles

### Backend (Aucun changement requis)
- ✅ `/src/models/OrderItem.js` (déjà correct)
- ✅ `/src/controllers/quote/quoteController.js` (déjà correct)

---

## 🚀 Déploiement

### Pas de Redémarrage Requis

Cette correction est **purement frontend**. Aucune modification backend nécessaire.

**Étapes :**
1. ✅ Modifications appliquées dans `OrderDetail.tsx`
2. 🔄 Le dashboard se recharge automatiquement (hot reload)
3. ✅ Tester immédiatement

---

## 🎯 Prochaines Améliorations

### Court Terme
- [ ] Ajouter un indicateur visuel pour les articles personnalisés (icône ✎)
- [ ] Badge "Personnalisé" vs "Catalogue"

### Moyen Terme
- [ ] Interface TypeScript pour normaliser les types
```typescript
interface OrderItemDisplay {
  id: number;
  displayName: string;  // Nom unifié
  quantity: number;
  unitPrice: number;
  total: number;
  isCustom: boolean;
}
```

---

## 🔗 Commandes Rapides

```bash
# Tester conversion
# 1. Dashboard web
open http://localhost:3001/devis

# 2. Créer devis mixte
# 3. Convertir en commande
# 4. Vérifier /commandes

# Vérifier les données en DB
sqlite3 database.sqlite "
SELECT 
  id, 
  order_id,
  product_id,
  product_name,
  is_custom
FROM order_items 
WHERE order_id = 9;
"
```

---

**Version :** 1.0  
**Date :** 31 Octobre 2025  
**Statut :** ✅ Corrigé et prêt à tester  
**Impact :** Frontend uniquement (pas de redémarrage requis)
