# 🔧 Correction : Colonne is_custom manquante dans quote_items

**Date :** 31 Octobre 2025  
**Problème :** `SQLITE_ERROR: no such column: items.isCustom`

---

## 🐛 Erreur Complète

```
❌ Erreur lors de la récupération des devis: 
SQLITE_ERROR: no such column: items.isCustom

GET /api/quotes?search= 500
```

---

## 🔍 Cause du Problème

### Incohérence Modèle ↔ Base de Données

1. **Modèle QuoteItem.js** essayait d'accéder à `items.isCustom`
2. **Table quote_items** n'avait pas cette colonne
3. **Requête SQL** échouait lors du SELECT

### Pourquoi ?

La migration initiale utilisait une syntaxe **MySQL** incompatible avec **SQLite** :
```sql
ALTER TABLE quote_items 
ADD COLUMN isCustom TINYINT(1) DEFAULT 0 COMMENT '...';  -- ❌ MySQL only
```

SQLite ne supporte pas :
- `TINYINT(1)` → doit être `INTEGER`
- `COMMENT` → pas de commentaires dans les colonnes
- `ALTER TABLE ADD COLUMN` avec certaines contraintes

---

## ✅ Solution Appliquée

### 1. Migration SQLite Compatible

**Script créé :** `fix-quote-items-schema.js`

**Opérations :**
1. ✅ Sauvegarde de `quote_items` → `quote_items_backup`
2. ✅ Suppression de l'ancienne table
3. ✅ Recréation avec `is_custom INTEGER DEFAULT 0`
4. ✅ Restauration des données (is_custom = 0 pour anciennes lignes)
5. ✅ Création de l'index `idx_quote_items_is_custom`

**Résultat :**
```
📊 Structure finale de quote_items:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
id              INTEGER    NULL       
quoteId         INTEGER    NOT NULL   
productId       INTEGER    NOT NULL   
productName     TEXT       NOT NULL   
quantity        INTEGER    NOT NULL   
unitPrice       REAL       NOT NULL   
discount        REAL       NULL       DEFAULT 0
taxRate         REAL       NULL       DEFAULT 20
is_custom       INTEGER    NULL       DEFAULT 0    ← Nouveau !
created_at      TEXT       NULL       
updated_at      TEXT       NULL       
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 2. Correction du Modèle Sequelize

**Fichier :** `/src/models/QuoteItem.js`

**Changement :**
```javascript
// AVANT
isCustom: { 
  type: DataTypes.BOOLEAN, 
  defaultValue: false, 
  field: 'isCustom'  // ❌ Mauvais nom de colonne
}

// APRÈS
isCustom: { 
  type: DataTypes.BOOLEAN, 
  defaultValue: false, 
  field: 'is_custom'  // ✅ Correspond à la DB
}
```

**Pourquoi ?**
- Nom du champ dans le code : `isCustom` (camelCase)
- Nom de la colonne en DB : `is_custom` (snake_case)
- Le `field:` doit mapper correctement

---

## 🚀 Déploiement

### ✅ Étapes Complétées

1. **Migration de la base de données**
   ```bash
   node fix-quote-items-schema.js
   # ✅ Migration terminée avec succès!
   ```

2. **Correction du modèle**
   ```bash
   # Fichier modifié : src/models/QuoteItem.js
   # Ligne 14 : field: 'is_custom'
   ```

---

### ⏳ Action Requise : Redémarrer le Backend

**IMPORTANT :** Le serveur doit être redémarré pour charger le modèle corrigé.

```bash
# Arrêter le serveur actuel
lsof -ti:3000 | xargs kill -9

# Redémarrer
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

---

## 🧪 Tests de Validation

### Test 1 : Liste des Devis

```bash
# Après redémarrage du serveur
curl http://localhost:3000/api/quotes?search= \
  -H "Authorization: Bearer TOKEN"
```

**Résultat attendu :**
```json
{
  "success": true,
  "data": [
    {
      "id": 15,
      "reference": "DEVIS-2025-015",
      "items": [
        {
          "id": 1,
          "productId": -1,
          "productName": "Main d'œuvre",
          "isCustom": true  // ✅ Champ présent
        }
      ]
    }
  ]
}
```

**Status attendu :** `200 OK` (pas 500)

---

### Test 2 : Création de Devis avec Article Personnalisé

```bash
# Via dashboard web
http://localhost:3001/devis/nouveau

# Actions :
1. Cliquer "Article personnalisé"
2. Saisir "Installation + test"
3. Quantité : 1, Prix : 50000
4. Sauvegarder
```

**Résultat attendu :**
- ✅ Devis créé avec `is_custom = 1`
- ✅ Visible dans la liste des devis
- ✅ Éditable sans erreur

---

### Test 3 : Édition de Devis Existant

```bash
# Dashboard web
http://localhost:3001/devis

# Actions :
1. Cliquer "Modifier" sur un devis
2. Vérifier que les articles personnalisés s'affichent
3. Modifier une description
4. Sauvegarder
```

**Résultat attendu :**
- ✅ Pas d'erreur console
- ✅ Articles personnalisés affichent Input (pas Select)
- ✅ Modifications sauvegardées

---

## 📊 Vérification Base de Données

### Vérifier la Structure

```bash
sqlite3 database.sqlite

.schema quote_items
```

**Attendu :**
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
  is_custom INTEGER DEFAULT 0,  -- ✅ Présent
  ...
);
```

---

### Vérifier les Données

```sql
SELECT 
  id, 
  productId, 
  productName, 
  is_custom 
FROM quote_items 
LIMIT 5;
```

**Résultat attendu :**
```
id|productId|productName|is_custom
1 |5        |Climatiseur|0
2 |-1       |Main d'œuvre|1
3 |12       |Filtre     |0
```

---

## 🔗 Migrations Appliquées

### Résumé des Migrations

| Table | Migration | Statut | Fichier |
|-------|-----------|--------|---------|
| `quote_items` | Ajout `is_custom` | ✅ Appliquée | `fix-quote-items-schema.js` |
| `order_items` | Ajout `is_custom`, `product_name` | ✅ Appliquée | `fix-order-items-schema.js` |

---

## 📝 Modifications de Code

### Fichiers Modifiés

1. **Backend - Modèle**
   - `/src/models/QuoteItem.js` (ligne 14)
   - Mapping : `field: 'is_custom'`

2. **Backend - Migration**
   - `/fix-quote-items-schema.js` (nouveau)
   - Migration SQLite compatible

3. **Frontend** (précédemment)
   - `/src/pages/quotes/QuoteForm.tsx`
   - Support articles personnalisés

---

## 🎯 Checklist de Vérification

Avant de marquer comme résolu :

- [x] Migration de la table quote_items appliquée
- [x] Colonne `is_custom` ajoutée
- [x] Index créé
- [x] Modèle QuoteItem corrigé
- [x] Données existantes préservées
- [ ] Serveur backend redémarré
- [ ] Test GET /api/quotes réussi (200)
- [ ] Création de devis avec article personnalisé testée
- [ ] Édition de devis testée
- [ ] Conversion devis → commande testée

---

## 💡 Leçons Apprises

### 1. Syntaxe SQL Spécifique

**MySQL ≠ SQLite ≠ PostgreSQL**

```sql
-- ❌ MySQL
ALTER TABLE t ADD COLUMN col TINYINT(1) COMMENT 'text';

-- ✅ SQLite
-- Pas de ALTER ADD avec toutes les options
-- Solution: Recréer la table
```

### 2. Mapping Sequelize

**Toujours vérifier le mapping des champs :**
```javascript
{
  // Nom dans le code (camelCase)
  isCustom: {
    type: DataTypes.BOOLEAN,
    // Nom dans la DB (snake_case)
    field: 'is_custom'  // ← CRITIQUE
  }
}
```

### 3. Convention de Nommage

**Cohérence entre les tables :**
- `order_items.is_custom` ✅
- `quote_items.is_custom` ✅
- Même convention partout

---

## 🚨 Points d'Attention

### 1. Redémarrage Obligatoire

Le modèle Sequelize est chargé au démarrage du serveur.  
**Toute modification du modèle nécessite un redémarrage.**

### 2. Migration Non Réversible

Cette migration **recrée la table**.  
Les données sont préservées mais les contraintes peuvent changer.

### 3. Cohérence Frontend/Backend

S'assurer que :
- Frontend envoie `isCustom` (camelCase)
- Backend le mappe vers `is_custom` (snake_case)
- Pas de confusion entre les deux

---

## ✅ Statut Final

### Corrections Appliquées
- ✅ **Migration DB** : Colonne `is_custom` ajoutée
- ✅ **Modèle** : Mapping corrigé
- ✅ **Index** : Créé pour optimisation
- ✅ **Données** : Préservées

### En Attente
- ⏳ **Redémarrage du serveur** (ACTION UTILISATEUR)
- ⏳ **Tests de validation**

---

## 🔗 Commandes Rapides

```bash
# Redémarrer le backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9 && npm start

# Tester l'API
curl http://localhost:3000/api/quotes?search= \
  -H "Authorization: Bearer TOKEN"

# Vérifier la DB
sqlite3 database.sqlite "SELECT * FROM quote_items WHERE is_custom = 1;"
```

---

**Version :** 1.0  
**Date :** 31 Octobre 2025  
**Statut :** ✅ Migration appliquée, en attente de redémarrage
