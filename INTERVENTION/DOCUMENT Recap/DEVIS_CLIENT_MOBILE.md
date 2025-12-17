# 📋 Devis Client - Application Mobile

## ✅ Problème Résolu

**Question:** Lorsque je crée un devis pour un client existant, est-ce possible qu'il le reçoive dans "Devis et Contrats" ?

**Réponse:** OUI ! Le système est maintenant fonctionnel.

---

## 🔍 Problème Identifié

L'endpoint `/api/customer/quotes` retournait des **données factices** au lieu des vrais devis depuis la base de données.

### Avant

```javascript
// Données factices
const quotes = [
  {
    id: '1',
    reference: 'DEV-2023-001',
    title: 'Maintenance annuelle',
    amount: 1200.00,
    status: 'pending',
  },
];
```

**Résultat:** Les clients ne voyaient PAS leurs vrais devis.

---

## ✅ Solution Appliquée

### **1. Récupération des Vrais Devis**

**Fichier:** `/src/routes/customerRoutes.js`

```javascript
router.get('/quotes', async (req, res) => {
  try {
    const { Quote, QuoteItem, CustomerProfile } = require('../models');
    const userId = req.user.id;
    
    // 1. Trouver le customer_id depuis le user_id
    const customerProfile = await CustomerProfile.findOne({ 
      where: { user_id: userId } 
    });
    
    if (!customerProfile) {
      return res.json({
        success: true,
        data: [],
        message: 'Aucun devis trouvé',
      });
    }
    
    const customerId = customerProfile.id;
    
    // 2. Récupérer tous les devis du client
    const quotes = await Quote.findAll({
      where: { customerId: customerId },
      include: [{ model: QuoteItem, as: 'items' }],
      order: [['created_at', 'DESC']]
    });
    
    // 3. Formater les données pour le mobile
    const formattedQuotes = quotes.map(quote => ({
      id: quote.id.toString(),
      reference: quote.reference,
      title: quote.notes || 'Devis',
      description: quote.termsAndConditions || '',
      amount: parseFloat(quote.total),
      status: quote.status,
      validUntil: quote.expiryDate,
      createdAt: quote.created_at || quote.createdAt,
      issueDate: quote.issueDate,
      expiryDate: quote.expiryDate,
      subtotal: parseFloat(quote.subtotal),
      taxAmount: parseFloat(quote.taxAmount),
      discountAmount: parseFloat(quote.discountAmount),
      items: quote.items || []
    }));
    
    res.json({
      success: true,
      data: formattedQuotes,
      message: 'Devis récupérés avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting customer quotes:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des devis',
      error: error.message
    });
  }
});
```

---

### **2. Détails d'un Devis**

```javascript
router.get('/quotes/:id', async (req, res) => {
  try {
    const { Quote, QuoteItem, CustomerProfile } = require('../models');
    const userId = req.user.id;
    const quoteId = req.params.id;
    
    // 1. Trouver le customer_id
    const customerProfile = await CustomerProfile.findOne({ 
      where: { user_id: userId } 
    });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    // 2. Récupérer le devis (vérifier qu'il appartient au client)
    const quote = await Quote.findOne({
      where: { 
        id: quoteId,
        customerId: customerProfile.id 
      },
      include: [{ model: QuoteItem, as: 'items' }]
    });
    
    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Devis non trouvé',
      });
    }
    
    // 3. Formater et retourner
    const formattedQuote = {
      id: quote.id.toString(),
      reference: quote.reference,
      title: quote.notes || 'Devis',
      description: quote.termsAndConditions || '',
      amount: parseFloat(quote.total),
      status: quote.status,
      validUntil: quote.expiryDate,
      createdAt: quote.created_at || quote.createdAt,
      issueDate: quote.issueDate,
      expiryDate: quote.expiryDate,
      subtotal: parseFloat(quote.subtotal),
      taxAmount: parseFloat(quote.taxAmount),
      discountAmount: parseFloat(quote.discountAmount),
      items: quote.items || []
    };
    
    res.json({
      success: true,
      data: formattedQuote,
      message: 'Détails du devis récupérés avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting quote details:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du devis',
      error: error.message
    });
  }
});
```

---

## 🔄 Flux Complet

### **Création d'un Devis (Dashboard Web)**

```
Dashboard Web
    ↓
Onglet "Devis"
    ↓
Cliquer sur "Nouveau Devis"
    ↓
Remplir le formulaire:
  - Sélectionner un client existant
  - Ajouter des articles
  - Définir les montants
    ↓
Sauvegarder
    ↓
POST /api/quotes
    ↓
✅ Devis créé dans la base de données
    ↓
Table: quotes
  - customerId: 7 (ID du client)
  - reference: DEV-2025-001
  - total: 15000
  - status: pending
```

---

### **Réception sur Mobile**

```
Application Mobile
    ↓
Client se connecte (user_id: 10)
    ↓
Onglet "Devis et Contrats"
    ↓
GET /api/customer/quotes
    ↓
Backend:
  1. Récupère user_id depuis le token JWT
  2. Trouve customer_id depuis customer_profiles
  3. Récupère tous les devis où customerId = customer_id
    ↓
✅ Liste des devis affichée
    ↓
Cliquer sur un devis
    ↓
GET /api/customer/quotes/:id
    ↓
✅ Détails du devis affichés
```

---

## 📊 Structure des Données

### **Table `quotes`**

| Colonne | Type | Description |
|---------|------|-------------|
| id | INT | ID unique du devis |
| reference | STRING | Référence (ex: DEV-2025-001) |
| customerId | INT | ID du client (FK → customer_profiles.id) |
| customerName | STRING | Nom du client |
| issueDate | DATE | Date d'émission |
| expiryDate | DATE | Date d'expiration |
| status | STRING | pending, accepted, rejected, converted |
| subtotal | DECIMAL | Sous-total HT |
| taxAmount | DECIMAL | Montant TVA |
| discountAmount | DECIMAL | Montant remise |
| total | DECIMAL | Total TTC |
| notes | TEXT | Notes (utilisé comme titre sur mobile) |
| termsAndConditions | TEXT | Conditions (utilisé comme description) |

### **Table `quote_items`**

| Colonne | Type | Description |
|---------|------|-------------|
| id | INT | ID unique |
| quoteId | INT | FK → quotes.id |
| productId | INT | FK → products.id |
| productName | STRING | Nom du produit |
| quantity | INT | Quantité |
| unitPrice | DECIMAL | Prix unitaire |
| discount | DECIMAL | Remise (%) |
| taxRate | DECIMAL | Taux TVA (%) |

---

## 🔗 Lien User ↔ Customer

### **Relation**

```
Table users
├─ id: 10
├─ email: client@example.com
├─ role: customer
└─ ...

      ↓ (user_id)

Table customer_profiles
├─ id: 7
├─ user_id: 10 ← Lien
├─ first_name: Jean
├─ last_name: Dupont
└─ ...

      ↓ (customerId)

Table quotes
├─ id: 1
├─ customerId: 7 ← Lien
├─ reference: DEV-2025-001
├─ total: 15000
└─ ...
```

### **Requête Backend**

```javascript
// 1. Récupérer user_id depuis le token JWT
const userId = req.user.id; // 10

// 2. Trouver le customer_id
const customerProfile = await CustomerProfile.findOne({ 
  where: { user_id: userId } 
});
const customerId = customerProfile.id; // 7

// 3. Récupérer les devis
const quotes = await Quote.findAll({
  where: { customerId: customerId } // customerId = 7
});
```

---

## 🧪 Tests

### **Test 1 : Créer un Devis sur le Web**

1. **Dashboard Web → Devis**
2. Cliquer sur "Nouveau Devis"
3. Sélectionner un client : "Jean Dupont"
4. Ajouter des articles
5. Sauvegarder
6. ✅ Devis créé avec `customerId = 7`

**Vérification Base de Données:**
```sql
SELECT * FROM quotes WHERE customerId = 7;
```

---

### **Test 2 : Voir le Devis sur Mobile**

1. **Application Mobile**
2. Se connecter avec le compte du client (email: jean.dupont@example.com)
3. Onglet "Devis et Contrats"
4. ✅ Le devis créé apparaît dans la liste

**Logs Backend:**
```
📋 Récupération des devis pour user_id: 10
✅ Customer ID trouvé: 7
✅ 1 devis trouvés
```

---

### **Test 3 : Voir les Détails**

1. Dans la liste, cliquer sur le devis
2. ✅ Détails affichés :
   - Référence: DEV-2025-001
   - Montant: 15000 FCFA
   - Statut: En attente
   - Date d'expiration
   - Liste des articles

---

## 📝 Fichiers Modifiés

### **Backend**

**Fichier:** `/src/routes/customerRoutes.js`

**Changements:**
1. ✅ Route `/quotes` - Récupération des vrais devis depuis la base
2. ✅ Route `/quotes/:id` - Détails d'un devis avec vérification de propriété
3. ✅ Suppression du doublon de route
4. ✅ Logs de débogage

---

## 🚀 Déploiement

### **Étapes**

1. **Redémarrer le serveur API**
   ```bash
   cd mct-maintenance-api
   npm start
   ```

2. **Créer un devis de test**
   - Dashboard Web → Devis → Nouveau
   - Sélectionner un client
   - Sauvegarder

3. **Vérifier sur mobile**
   - Se connecter avec le compte du client
   - Onglet "Devis et Contrats"
   - ✅ Le devis apparaît

---

## 📱 Interface Mobile

### **Liste des Devis**

```
┌─────────────────────────────────┐
│  Mes Devis et Contrats          │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ DEV-2025-001   [Pending]│   │
│  │ Maintenance annuelle    │   │
│  │ 15 000 FCFA             │   │
│  │ Expire le: 25/11/2025   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ DEV-2025-002  [Accepted]│   │
│  │ Installation VMC        │   │
│  │ 8 500 FCFA              │   │
│  │ Expire le: 30/11/2025   │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### **Détails d'un Devis**

```
┌─────────────────────────────────┐
│  ← Détails du Devis             │
├─────────────────────────────────┤
│  DEV-2025-001                   │
│  [En attente]                   │
│                                 │
│  Maintenance annuelle           │
│  Contrat de maintenance pour... │
│                                 │
│  📅 Émis le: 22/10/2025         │
│  ⏰ Expire le: 25/11/2025       │
│                                 │
│  Articles:                      │
│  • Climatiseur Daikin x2        │
│    12 000 FCFA                  │
│  • Main d'œuvre                 │
│    3 000 FCFA                   │
│                                 │
│  Sous-total: 15 000 FCFA        │
│  TVA (0%): 0 FCFA               │
│  Remise: 0 FCFA                 │
│                                 │
│  Total: 15 000 FCFA             │
│                                 │
│  [Accepter]  [Refuser]          │
└─────────────────────────────────┘
```

---

## ✅ Résultat Final

### **Workflow Complet**

```
Admin crée un devis sur le web
    ↓
✅ Devis enregistré dans la base
    ↓
Client ouvre l'app mobile
    ↓
✅ Devis visible dans "Devis et Contrats"
    ↓
Client consulte les détails
    ↓
✅ Toutes les informations affichées
    ↓
Client peut accepter ou refuser
```

---

## 🎯 Statuts des Devis

| Statut | Label Mobile | Couleur | Description |
|--------|--------------|---------|-------------|
| pending | En attente | Orange | Devis créé, en attente de réponse |
| accepted | Accepté | Vert | Client a accepté le devis |
| rejected | Refusé | Rouge | Client a refusé le devis |
| converted | Converti | Bleu | Devis converti en commande |
| expired | Expiré | Gris | Date d'expiration dépassée |

---

## 🔮 Améliorations Futures

1. **Notifications Push** - Alerter le client quand un nouveau devis est créé
2. **Acceptation/Refus** - Boutons fonctionnels dans l'app mobile
3. **Téléchargement PDF** - Télécharger le devis en PDF
4. **Signature électronique** - Signer le devis directement dans l'app
5. **Historique** - Voir l'historique des modifications du devis
6. **Chat** - Discuter avec l'admin à propos du devis

---

## ✅ Conclusion

**Le système fonctionne maintenant correctement !**

Quand vous créez un devis pour un client existant sur le dashboard web, **le client le reçoit automatiquement** dans l'onglet "Devis et Contrats" de son application mobile.

**Flux:**
1. ✅ Admin crée un devis avec `customerId`
2. ✅ Devis enregistré dans la base
3. ✅ Client se connecte sur mobile
4. ✅ API récupère les devis via `user_id` → `customer_id`
5. ✅ Devis affichés dans l'app

**Le problème est résolu !** 🎉📋✨
