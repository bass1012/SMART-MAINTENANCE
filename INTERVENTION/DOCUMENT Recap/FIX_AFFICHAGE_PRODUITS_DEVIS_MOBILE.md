# 🔧 Correction : Affichage des Produits dans les Devis (App Mobile)

**Date :** 31 Octobre 2025  
**Problème :** Les noms des produits n'apparaissent pas dans les devis sur l'application mobile client

---

## 🐛 Symptôme

Dans l'application mobile client, lorsqu'on consulte un devis, seules les informations générales s'affichent :
- ✅ Référence du devis
- ✅ Titre
- ✅ Description
- ✅ Montant total
- ❌ **Liste des articles/produits manquante**

**Résultat :** Le client ne peut pas voir les détails des produits inclus dans le devis.

---

## 🔍 Cause du Problème

### 1. Modèle Incomplet

Le modèle `QuoteContract` ne contenait pas de liste d'items :

```dart
class QuoteContract {
  final String id;
  final String reference;
  final String title;
  final String description;
  final double amount;
  // ❌ Pas de liste d'items !
}
```

### 2. Écran Incomplet

L'écran `quote_detail_screen.dart` n'affichait pas de section pour les articles.

### 3. Backend Correct

Le backend renvoyait pourtant bien les items dans l'API :

```javascript
// Route: GET /api/customer/quotes
const quotes = await Quote.findAll({
  where: { customerId: customerId },
  include: [{ model: QuoteItem, as: 'items' }], // ✅ Items inclus
  order: [['created_at', 'DESC']]
});

// Réponse
items: quote.items || []  // ✅ Items dans la réponse
```

**Problème :** Le modèle Flutter ne parsait pas les items !

---

## ✅ Solution Appliquée

### 1. Création du Modèle `QuoteItem`

**Fichier créé :** `/lib/models/quote_item_model.dart`

```dart
class QuoteItem {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final bool isCustom;

  QuoteItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.taxRate = 20.0,
    this.isCustom = false,
  });

  // Calculs
  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get total => taxableAmount + taxAmount;

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      productId: json['productId'] ?? json['product_id'] ?? -1,
      productName: json['productName'] ?? json['product_name'] ?? 
                   json['product']?['nom'] ?? 'Article',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? json['unit_price'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      taxRate: (json['taxRate'] ?? json['tax_rate'] ?? 20.0).toDouble(),
      isCustom: json['isCustom'] ?? json['is_custom'] ?? false,
    );
  }
}
```

**Fonctionnalités :**
- ✅ Support snake_case et camelCase
- ✅ Calculs automatiques (subtotal, discount, tax, total)
- ✅ Gestion des articles personnalisés (`isCustom`)
- ✅ Fallback vers `product.nom` si `productName` absent

---

### 2. Mise à Jour du Modèle `QuoteContract`

**Fichier modifié :** `/lib/models/quote_contract_model.dart`

**Ajouts :**
```dart
import 'quote_item_model.dart';

class QuoteContract {
  // ... champs existants ...
  final List<QuoteItem> items; // ✅ Nouveau

  QuoteContract({
    // ... paramètres existants ...
    this.items = const [],
  });

  factory QuoteContract.fromJson(Map<String, dynamic> json) {
    // Parser les items
    List<QuoteItem> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((item) => QuoteItem.fromJson(item))
          .toList();
    }

    return QuoteContract(
      // ... autres champs ...
      items: itemsList, // ✅ Inclus
    );
  }
}
```

---

### 3. Mise à Jour de l'Écran de Détail

**Fichier modifié :** `/lib/screens/customer/quote_detail_screen.dart`

**Ajout de la section Articles (entre Description et Montant) :**

```dart
// Articles/Produits
if (_quote.items.isNotEmpty)
  Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Articles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Liste des items
          ...(_quote.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge "Personnalisé" si custom
                    if (item.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ),
                    if (item.isCustom) const SizedBox(width: 8),
                    
                    // Nom et détails
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (item.discount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Remise: ${item.discount}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Total de la ligne
                    Text(
                      '${item.total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0a543d),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }).toList()),
        ],
      ),
    ),
  ),
```

**Fonctionnalités de l'affichage :**
- ✅ Nom du produit en gras
- ✅ Quantité × Prix unitaire
- ✅ Total de la ligne
- ✅ Badge orange pour articles personnalisés (icône ✎)
- ✅ Affichage de la remise si > 0
- ✅ Séparateur entre les items
- ✅ Couleur MCT (#0a543d) pour les totaux

---

## 📊 Résultat Visuel

### Avant
```
┌─────────────────────────────────────┐
│ Devis DEVIS-2025-015                │
│ Statut: En attente                  │
├─────────────────────────────────────┤
│ Informations                        │
│ Date: 31/10/2025                    │
│                                     │
│ Description                         │
│ Climatisation bureau                │
│                                     │
│ Montant Total                       │
│ 1 280 000 FCFA                      │
└─────────────────────────────────────┘
```

### Après
```
┌─────────────────────────────────────┐
│ Devis DEVIS-2025-015                │
│ Statut: En attente                  │
├─────────────────────────────────────┤
│ Informations                        │
│ Date: 31/10/2025                    │
│                                     │
│ Description                         │
│ Climatisation bureau                │
│                                     │
│ ✅ Articles                         │
│ ┌─────────────────────────────────┐ │
│ │ Climatiseur Split 12000 BTU     │ │
│ │ 1 × 1200000 FCFA   1 200 000 ₣│ │
│ ├─────────────────────────────────┤ │
│ │ [✎] Installation + test         │ │
│ │ 1 × 80000 FCFA        80 000 ₣│ │
│ └─────────────────────────────────┘ │
│                                     │
│ Montant Total                       │
│ 1 280 000 FCFA                      │
└─────────────────────────────────────┘
```

---

## 🔄 Flux de Données

```
Backend                          Mobile Flutter
   │                                 │
   │ GET /api/customer/quotes        │
   │◄────────────────────────────────│
   │                                 │
   │ Quote.findAll({                 │
   │   include: [{                   │
   │     model: QuoteItem,           │
   │     as: 'items'                 │
   │   }]                            │
   │ })                              │
   │                                 │
   │ Response:                       │
   │ {                               │
   │   data: [{                      │
   │     id: "15",                   │
   │     reference: "DEVIS-...",     │
   │     items: [                    │
   │       {                         │
   │         productId: 5,           │
   │         productName: "Clim",    │
   │         quantity: 1,            │
   │         unitPrice: 1200000      │
   │       },                        │
   │       {                         │
   │         productId: -1,          │
   │         productName: "Install", │
   │         is_custom: true,        │
   │         quantity: 1,            │
   │         unitPrice: 80000        │
   │       }                         │
   │     ]                           │
   │   }]                            │
   │ }                               │
   │─────────────────────────────────►
   │                                 │
   │                    QuoteContract.fromJson()
   │                    ├─ Parse items array
   │                    └─ QuoteItem.fromJson()
   │                                 │
   │                    QuoteDetailScreen
   │                    └─ Affiche _quote.items
```

---

## 🧪 Tests de Validation

### Test 1 : Devis avec Produit Catalogue

**Prérequis :**
- Devis existant avec produit du catalogue

**Étapes :**
```bash
# App mobile
1. Ouvrir l'app
2. Se connecter
3. Onglet "Devis"
4. Cliquer sur un devis
```

**Résultat attendu :**
```
Articles
┌───────────────────────────────────┐
│ Climatiseur Split 12000 BTU      │
│ 1 × 1200000 FCFA   1 200 000 FCFA│
└───────────────────────────────────┘
```

---

### Test 2 : Devis avec Article Personnalisé

**Prérequis :**
- Devis avec article personnalisé (productId = -1)

**Résultat attendu :**
```
Articles
┌───────────────────────────────────┐
│ [✎] Main d'œuvre technicien 4h   │
│ 1 × 80000 FCFA         80 000 FCFA│
└───────────────────────────────────┘
```

**Badge orange visible :** ✎ icône "edit" pour identifier les articles personnalisés

---

### Test 3 : Devis Mixte

**Contenu :**
- 1 produit du catalogue
- 1 article personnalisé

**Résultat attendu :**
```
Articles
┌───────────────────────────────────┐
│ Climatiseur Split               │
│ 1 × 1200000 FCFA  1 200 000 FCFA│
├───────────────────────────────────┤
│ [✎] Installation + test         │
│ 1 × 50000 FCFA       50 000 FCFA│
└───────────────────────────────────┘

Montant Total
1 250 000 FCFA
```

---

### Test 4 : Devis avec Remise

**Résultat attendu :**
```
Articles
┌───────────────────────────────────┐
│ Climatiseur Split               │
│ 1 × 1200000 FCFA                │
│ Remise: 10%                     │
│ Total ligne:        1 080 000 FCFA│
└───────────────────────────────────┘
```

---

## 📋 Checklist de Vérification

### Développement
- [x] Modèle `QuoteItem` créé
- [x] Modèle `QuoteContract` mis à jour
- [x] Écran de détail mis à jour
- [x] Support snake_case et camelCase
- [x] Badge pour articles personnalisés
- [x] Affichage des remises

### Backend (Déjà Correct)
- [x] API inclut les items (`include: QuoteItem`)
- [x] Réponse contient `items: quote.items`
- [ ] Serveur backend redémarré (si nécessaire)

### Tests
- [ ] Test devis produit catalogue
- [ ] Test devis article personnalisé
- [ ] Test devis mixte
- [ ] Test devis avec remise
- [ ] Test sur iOS
- [ ] Test sur Android

---

## 🚀 Déploiement

### Étapes

1. **Installer les dépendances (si nécessaire) :**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
   flutter pub get
   ```

2. **Lancer l'application :**
   ```bash
   flutter run
   ```

3. **Tester immédiatement :**
   - Se connecter
   - Aller sur "Devis"
   - Ouvrir un devis
   - ✅ Vérifier que les articles s'affichent

---

### Pas de Redémarrage Backend Requis

Le backend n'a pas été modifié. Il renvoyait déjà les items correctement.

**Si les items ne s'affichent toujours pas :**
- Vérifier les logs backend : `npm start` dans `/mct-maintenance-api`
- Vérifier la réponse API : logs de `getCustomerQuotes()`

---

## 💡 Améliorations Futures

### Court Terme
- [ ] Ajouter un compteur "X articles" dans la carte
- [ ] Animation d'expansion pour la liste des items
- [ ] Bouton "Voir les détails" pour chaque article

### Moyen Terme
- [ ] Icônes spécifiques par catégorie de produit
- [ ] Photos des produits (miniatures)
- [ ] Comparaison de devis (si plusieurs)

### Long Terme
- [ ] Export PDF du devis depuis l'app
- [ ] Signature électronique du devis
- [ ] Négociation des prix (chat)

---

## 🔗 Fichiers Modifiés/Créés

### Nouveaux Fichiers
- ✅ `/lib/models/quote_item_model.dart` (142 lignes)

### Fichiers Modifiés
- ✅ `/lib/models/quote_contract_model.dart` (+15 lignes)
- ✅ `/lib/screens/customer/quote_detail_screen.dart` (+101 lignes)

### Backend (Inchangé)
- ✅ `/src/routes/customerRoutes.js` (déjà correct)
- ✅ `/src/models/QuoteItem.js` (déjà correct)

---

## 🔗 Commandes Rapides

```bash
# Tester l'app mobile
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter run

# Vérifier les logs backend (optionnel)
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Vérifier l'API directement
curl http://localhost:3000/api/customer/quotes \
  -H "Authorization: Bearer TOKEN"
```

---

**Version :** 1.0  
**Date :** 31 Octobre 2025  
**Statut :** ✅ Corrigé et prêt à tester  
**Impact :** Frontend mobile uniquement (Flutter)  
**Redémarrage requis :** Aucun (hot reload Flutter)
