# 📝 Articles Personnalisés dans les Devis - Documentation

**Date d'implémentation :** 31 Octobre 2025  
**Fonctionnalité :** Ajout d'éléments personnalisés aux devis (en plus des produits catalogués)

---

## 🎯 Objectif

Permettre aux administrateurs d'ajouter des éléments personnalisés dans les devis, tels que :
- 💼 Main d'œuvre
- 🚗 Frais de déplacement
- 🔧 Services spécifiques non catalogués
- 📦 Articles ponctuels

---

## ✨ Fonctionnalités Ajoutées

### 1. **Deux Types d'Articles**

#### **Article du Catalogue** (existant)
- Sélection depuis une liste déroulante
- Prix pré-rempli automatiquement
- Référence produit
- Bouton : **"Produit du catalogue"** (gris)

#### **Article Personnalisé** (nouveau)
- Champ texte libre pour le nom/description
- Prix saisi manuellement
- Pas de référence produit
- Bouton : **"Article personnalisé"** (vert) ✎

### 2. **Interface Utilisateur**

#### Dans le Tableau des Devis
```
┌─────────────────────────────────────────────────────────┐
│  Produit / Description  │  Quantité  │  Prix  │  ...    │
├─────────────────────────────────────────────────────────┤
│  [Dropdown: Produits]   │     1      │ 1200   │  ...    │  ← Produit catalogue
│  ✎ Main d'œuvre 2h      │     1      │  800   │  ...    │  ← Article personnalisé
│  [Dropdown: Produits]   │     2      │ 3500   │  ...    │  ← Produit catalogue
└─────────────────────────────────────────────────────────┘
```

#### Boutons d'Ajout
```
┌──────────────────────────────────────────────────────────┐
│  [⊕ Produit du catalogue]  [⊕ Article personnalisé]     │
│     (Bouton gris)              (Bouton vert)            │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Implémentation Technique

### Frontend (React + TypeScript)

#### Interface QuoteItem Mise à Jour
```typescript
export interface QuoteItem {
  id?: number;
  productId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  discount: number;
  taxRate: number;
  isCustom?: boolean; // 🆕 Nouveau champ
}
```

#### Fichiers Modifiés
- `/mct-maintenance-dashboard/src/pages/quotes/QuoteForm.tsx`
  - Ajout de la fonction `addCustomItem()`
  - Modification de la colonne "Produit" (affichage conditionnel)
  - Ajout du bouton "Article personnalisé"
  - Validation des articles personnalisés (nom non vide)

- `/mct-maintenance-dashboard/src/services/quotesService.ts`
  - Ajout du champ `isCustom` à l'interface `QuoteItem`

### Backend (Node.js + Sequelize)

#### Modèle QuoteItem Mis à Jour
```javascript
QuoteItem.init({
  // ... champs existants
  isCustom: { 
    type: DataTypes.BOOLEAN, 
    defaultValue: false, 
    field: 'isCustom' 
  }
}, { /* ... */ });
```

#### Fichiers Modifiés
- `/mct-maintenance-api/src/models/QuoteItem.js`
  - Ajout du champ `isCustom` (BOOLEAN, défaut: false)

### Base de Données (SQLite)

#### Migration SQL
```sql
ALTER TABLE quote_items 
ADD COLUMN isCustom TINYINT(1) DEFAULT 0;

CREATE INDEX idx_quote_items_is_custom ON quote_items(isCustom);

UPDATE quote_items SET isCustom = 0 WHERE isCustom IS NULL;
```

#### Fichiers Créés
- `/mct-maintenance-api/migrations/add_is_custom_to_quote_items.sql`
- `/mct-maintenance-api/apply-quote-custom-items-migration.js`

---

## 🚀 Déploiement

### Étapes d'Installation

#### 1. Appliquer la Migration Backend

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Appliquer la migration
node apply-quote-custom-items-migration.js
```

**Sortie attendue :**
```
✅ Connecté à la base de données SQLite
📋 3 commande(s) SQL à exécuter...

[1/3] Exécution: ALTER...
✅ ALTER réussi
[2/3] Exécution: CREATE...
✅ CREATE réussi
[3/3] Exécution: UPDATE...
✅ UPDATE réussi

============================================================
✅ Migration terminée: 3 commande(s) réussie(s)
============================================================
```

#### 2. Redémarrer le Backend

```bash
npm start
```

#### 3. Tester le Frontend

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard
npm start
```

Ouvrir : `http://localhost:3001/devis/nouveau`

---

## 📖 Guide d'Utilisation

### Pour Créer un Devis avec Articles Personnalisés

1. **Accéder à la page des devis**
   - Menu : "Devis" → "Nouveau devis"

2. **Sélectionner un client**
   - Champ "Client" obligatoire

3. **Ajouter des produits du catalogue**
   - Cliquer sur **"Produit du catalogue"**
   - Sélectionner le produit dans la liste déroulante
   - Le prix se remplit automatiquement

4. **Ajouter des articles personnalisés**
   - Cliquer sur **"Article personnalisé"** (bouton vert)
   - Saisir la description : *Ex: "Main d'œuvre 2h", "Frais de déplacement", "Diagnostic approfondi"*
   - Saisir le prix manuellement
   - Ajuster la quantité si nécessaire

5. **Configurer les détails**
   - Quantité
   - Remise (%)
   - TVA (%) - par défaut 20%

6. **Enregistrer**
   - **"Enregistrer en brouillon"** : Sauvegarde sans envoyer
   - **"Enregistrer et envoyer"** : Envoie au client

---

## 💡 Exemples d'Utilisation

### Exemple 1 : Devis Installation Climatisation
```
┌──────────────────────────────────────────────────────────────┐
│  Climatiseur Split 12000 BTU   │  1  │  1,200,000 F  │  ...  │
│  ✎ Installation + mise en route│  1  │    150,000 F  │  ...  │
│  ✎ Frais de déplacement         │  1  │     25,000 F  │  ...  │
└──────────────────────────────────────────────────────────────┘
Total : 1,375,000 F CFA TTC
```

### Exemple 2 : Devis Maintenance Préventive
```
┌──────────────────────────────────────────────────────────────┐
│  Maintenance préventive        │  1  │    150,000 F  │  ...  │
│  ✎ Main d'œuvre technicien (4h)│  1  │    120,000 F  │  ...  │
│  ✎ Produits de nettoyage       │  1  │     15,000 F  │  ...  │
│  Filtres de rechange           │  3  │     12,000 F  │  ...  │
└──────────────────────────────────────────────────────────────┘
Total : 321,000 F CFA TTC
```

### Exemple 3 : Devis Dépannage Urgent
```
┌──────────────────────────────────────────────────────────────┐
│  ✎ Diagnostic panne             │  1  │     50,000 F  │  ...  │
│  ✎ Main d'œuvre urgente (2h)    │  1  │    100,000 F  │  ...  │
│  Compresseur de rechange        │  1  │    450,000 F  │  ...  │
│  ✎ Déplacement en urgence       │  1  │     40,000 F  │  ...  │
└──────────────────────────────────────────────────────────────┘
Total : 640,000 F CFA TTC
```

---

## 🔒 Validation et Règles

### Articles du Catalogue
- ✅ Un produit doit être sélectionné
- ✅ Le prix est automatique (modifiable)
- ✅ `productId` > 0

### Articles Personnalisés
- ✅ Le nom/description est obligatoire
- ✅ Le prix doit être saisi manuellement
- ✅ `productId` = -1 (convention)
- ✅ `isCustom` = true

### Validation Globale
```javascript
items.filter(item => {
  // Garder les produits catalogue avec ID valide
  if (!item.isCustom && item.productId > 0) return true;
  
  // Garder les articles personnalisés avec nom
  if (item.isCustom && item.productName.trim() !== '') return true;
  
  return false;
})
```

---

## 🧪 Tests

### Tests à Effectuer

1. **Créer un devis avec produit catalogue uniquement**
   - ✅ Produit sélectionné
   - ✅ Prix auto-rempli
   - ✅ Sauvegarde réussie

2. **Créer un devis avec article personnalisé uniquement**
   - ✅ Nom saisi manuellement
   - ✅ Prix saisi manuellement
   - ✅ Sauvegarde réussie

3. **Créer un devis mixte**
   - ✅ Produits + Articles personnalisés
   - ✅ Calculs corrects (sous-total, TVA, total)
   - ✅ Sauvegarde réussie

4. **Validation des erreurs**
   - ❌ Article personnalisé sans nom → Erreur
   - ❌ Produit catalogue sans sélection → Ignoré
   - ✅ Message d'erreur clair

5. **Édition d'un devis existant**
   - ✅ Articles chargés correctement
   - ✅ Type d'article préservé (catalogue vs personnalisé)
   - ✅ Modification réussie

---

## 📊 Impact Base de Données

### Structure Avant
```sql
CREATE TABLE quote_items (
  id INTEGER PRIMARY KEY,
  quoteId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  productName TEXT,
  quantity INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  discount REAL DEFAULT 0,
  taxRate REAL DEFAULT 20,
  created_at DATETIME,
  updated_at DATETIME
);
```

### Structure Après
```sql
CREATE TABLE quote_items (
  id INTEGER PRIMARY KEY,
  quoteId INTEGER NOT NULL,
  productId INTEGER NOT NULL,
  productName TEXT,
  quantity INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  discount REAL DEFAULT 0,
  taxRate REAL DEFAULT 20,
  isCustom TINYINT(1) DEFAULT 0,  -- 🆕 NOUVEAU
  created_at DATETIME,
  updated_at DATETIME
);

CREATE INDEX idx_quote_items_is_custom ON quote_items(isCustom);
```

---

## 🐛 Dépannage

### Problème : La migration échoue

**Solution :**
```bash
# Vérifier que la BDD existe
ls -l database.sqlite

# Vérifier les permissions
chmod 644 database.sqlite

# Relancer la migration
node apply-quote-custom-items-migration.js
```

### Problème : Le bouton "Article personnalisé" n'apparaît pas

**Solution :**
```bash
# Recompiler le frontend
npm run build

# Ou redémarrer le serveur dev
npm start
```

### Problème : Erreur TypeScript "isCustom does not exist"

**Solution :**
Vérifier que `/src/services/quotesService.ts` contient :
```typescript
export interface QuoteItem {
  // ...
  isCustom?: boolean;
}
```

---

## 📈 Améliorations Futures

### Phase 2 (Optionnel)
- [ ] Templates d'articles personnalisés fréquents
- [ ] Historique des articles personnalisés utilisés
- [ ] Auto-complétion des noms d'articles
- [ ] Catégories pour articles personnalisés
- [ ] Import/Export de listes d'articles

### Phase 3 (Optionnel)
- [ ] Conversion article personnalisé → produit catalogue
- [ ] Statistiques sur les articles personnalisés les plus utilisés
- [ ] Suggestions de prix basées sur l'historique

---

## ✅ Checklist de Déploiement

### Backend
- [x] Modèle QuoteItem mis à jour
- [x] Migration SQL créée
- [x] Script de migration créé
- [ ] Migration appliquée en production
- [ ] Backend redémarré

### Frontend
- [x] Interface QuoteItem mise à jour
- [x] Formulaire QuoteForm modifié
- [x] Bouton "Article personnalisé" ajouté
- [x] Validation implémentée
- [ ] Tests UI effectués
- [ ] Déployé en production

### Documentation
- [x] Documentation technique
- [x] Guide utilisateur
- [x] Exemples d'utilisation
- [x] Guide de dépannage

---

## 📞 Support

Pour toute question ou problème :
1. Consulter ce document
2. Vérifier les logs backend et frontend
3. Tester avec les exemples fournis

---

**Version :** 1.0  
**Dernière mise à jour :** 31 Octobre 2025  
**Auteur :** Équipe MCT Maintenance
