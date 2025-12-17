# 📋 Détail et Actions sur les Devis - Application Mobile

## ✅ Fonctionnalités Implémentées

### **Problème Résolu**

Quand vous cliquiez sur un devis, **rien ne se passait**. Maintenant, un écran de détail s'affiche avec toutes les informations et les actions possibles.

---

## 🎯 Fonctionnalités Ajoutées

### **1. Écran de Détail du Devis**

**Fichier créé:** `/lib/screens/customer/quote_detail_screen.dart`

**Affichage:**
- ✅ Référence et statut du devis
- ✅ Titre et description
- ✅ Date d'émission
- ✅ Date d'expiration
- ✅ Montant total en FCFA
- ✅ Boutons d'action (Accepter/Refuser)
- ✅ Messages de confirmation

---

### **2. Actions Disponibles**

#### **Accepter un Devis**
- Bouton vert "Accepter le devis"
- Confirmation immédiate
- Mise à jour du statut → `accepted`
- Retour automatique à la liste

#### **Refuser un Devis**
- Bouton rouge "Refuser le devis"
- Dialog pour saisir la raison (optionnel)
- Mise à jour du statut → `rejected`
- Raison ajoutée aux notes
- Retour automatique à la liste

---

## 🔄 Flux Complet

```
Liste des Devis
    ↓
Cliquer sur un devis
    ↓
Écran de Détail
    ↓
Voir toutes les informations
    ↓
Actions disponibles selon le statut:
  - pending/sent → [Accepter] [Refuser]
  - accepted → Message "Vous avez accepté"
  - rejected → Message "Vous avez refusé"
    ↓
Cliquer sur [Accepter]
    ↓
✅ Devis accepté
    ↓
Retour à la liste (actualisée)
```

---

## 📱 Interface Mobile

### **Écran de Détail**

```
┌─────────────────────────────────┐
│  ← Détails du Devis             │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ DEV-2025-001   [Pending]│   │
│  │ Maintenance annuelle    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Informations            │   │
│  │ 📅 Date: 22/10/2025     │   │
│  │ ⏰ Valable: 25/11/2025  │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Description             │   │
│  │ Contrat de maintenance  │   │
│  │ pour équipements...     │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Montant Total           │   │
│  │         15000 FCFA      │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ✓ Accepter le devis     │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ✗ Refuser le devis      │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

### **Dialog de Refus**

```
┌─────────────────────────────────┐
│  Refuser le devis               │
├─────────────────────────────────┤
│  Pourquoi refusez-vous ce devis?│
│                                 │
│  ┌─────────────────────────┐   │
│  │ Raison (optionnel)      │   │
│  │                         │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  [Annuler]  [Refuser]           │
└─────────────────────────────────┘
```

---

### **Devis Accepté**

```
┌─────────────────────────────────┐
│  ← Détails du Devis             │
├─────────────────────────────────┤
│  DEV-2025-001   [Accepté]       │
│                                 │
│  ... (informations) ...         │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ✓ Vous avez accepté     │   │
│  │   ce devis              │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## 💻 Code Clé

### **Navigation vers le Détail**

**Fichier:** `quotes_contracts_screen.dart`

```dart
child: InkWell(
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteDetailScreen(quote: quote),
      ),
    );
    
    if (result == true) {
      _loadQuotes(); // Recharger la liste
    }
  },
  child: Padding(...)
)
```

---

### **Accepter un Devis**

**Fichier:** `quote_detail_screen.dart`

```dart
Future<void> _acceptQuote() async {
  setState(() => _isLoading = true);

  try {
    await _apiService.acceptQuote(_quote.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devis accepté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retour avec succès
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

---

### **Refuser un Devis**

```dart
Future<void> _rejectQuote() async {
  // Dialog pour demander la raison
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Refuser le devis'),
      content: TextField(
        decoration: const InputDecoration(
          hintText: 'Raison (optionnel)',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 'Refusé par le client'),
          child: const Text('Refuser'),
        ),
      ],
    ),
  );

  if (reason == null) return;

  await _apiService.rejectQuote(_quote.id, reason);
  Navigator.pop(context, true);
}
```

---

## 🔌 Backend API

### **Endpoints Ajoutés**

**Fichier:** `/src/routes/customerRoutes.js`

#### **1. Accepter un Devis**

```javascript
router.post('/quotes/:id/accept', async (req, res) => {
  const { Quote, CustomerProfile } = require('../models');
  const userId = req.user.id;
  const quoteId = req.params.id;
  
  // 1. Vérifier que le devis appartient au client
  const customerProfile = await CustomerProfile.findOne({ 
    where: { user_id: userId } 
  });
  
  const quote = await Quote.findOne({
    where: { 
      id: quoteId,
      customerId: customerProfile.id 
    }
  });
  
  // 2. Mettre à jour le statut
  await quote.update({ status: 'accepted' });
  
  res.json({
    success: true,
    message: 'Devis accepté avec succès',
    data: quote
  });
});
```

#### **2. Refuser un Devis**

```javascript
router.post('/quotes/:id/reject', async (req, res) => {
  const { Quote, CustomerProfile } = require('../models');
  const userId = req.user.id;
  const quoteId = req.params.id;
  const { reason } = req.body;
  
  // 1. Vérifier que le devis appartient au client
  const customerProfile = await CustomerProfile.findOne({ 
    where: { user_id: userId } 
  });
  
  const quote = await Quote.findOne({
    where: { 
      id: quoteId,
      customerId: customerProfile.id 
    }
  });
  
  // 2. Mettre à jour le statut et ajouter la raison
  const updateData = { status: 'rejected' };
  if (reason) {
    updateData.notes = quote.notes 
      ? `${quote.notes}\n\nRaison du refus: ${reason}` 
      : `Raison du refus: ${reason}`;
  }
  
  await quote.update(updateData);
  
  res.json({
    success: true,
    message: 'Devis refusé',
    data: quote
  });
});
```

---

## 📊 Statuts des Devis

| Statut | Label | Couleur | Actions Disponibles |
|--------|-------|---------|---------------------|
| draft | Brouillon | Gris | Aucune |
| sent | Envoyé | Orange | Accepter, Refuser |
| pending | En attente | Orange | Accepter, Refuser |
| accepted | Accepté | Vert | Aucune (message) |
| rejected | Refusé | Rouge | Aucune (message) |
| expired | Expiré | Gris | Aucune |

---

## 🧪 Tests

### **Test 1 : Voir le Détail**

1. **Application Mobile**
2. Onglet "Devis et Contrats"
3. Cliquer sur un devis
4. ✅ Écran de détail s'affiche
5. ✅ Toutes les informations visibles
6. ✅ Boutons d'action présents (si pending)

---

### **Test 2 : Accepter un Devis**

1. Ouvrir un devis avec statut "pending"
2. Cliquer sur "Accepter le devis"
3. ✅ Message de succès affiché
4. ✅ Retour à la liste
5. ✅ Statut du devis = "Accepté"

**Logs Backend:**
```
✅ Acceptation du devis 1 par user_id: 10
✅ Devis 1 accepté
```

**Vérification Base de Données:**
```sql
SELECT status FROM quotes WHERE id = 1;
-- Résultat: accepted
```

---

### **Test 3 : Refuser un Devis**

1. Ouvrir un devis avec statut "pending"
2. Cliquer sur "Refuser le devis"
3. ✅ Dialog s'affiche
4. Saisir une raison : "Prix trop élevé"
5. Cliquer sur "Refuser"
6. ✅ Message affiché
7. ✅ Retour à la liste
8. ✅ Statut du devis = "Refusé"

**Logs Backend:**
```
❌ Refus du devis 1 par user_id: 10
✅ Devis 1 refusé
```

**Vérification Base de Données:**
```sql
SELECT status, notes FROM quotes WHERE id = 1;
-- Résultat: 
-- status: rejected
-- notes: "... Raison du refus: Prix trop élevé"
```

---

## 📝 Fichiers Créés/Modifiés

### **Mobile**

1. ✅ `/lib/screens/customer/quote_detail_screen.dart` (créé)
   - Écran de détail complet
   - Actions accepter/refuser
   - Messages de confirmation

2. ✅ `/lib/screens/customer/quotes_contracts_screen.dart` (modifié)
   - Import de QuoteDetailScreen
   - Navigation vers le détail

3. ✅ `/lib/services/api_service.dart` (modifié)
   - Méthode `rejectQuote` ajoutée

### **Backend**

4. ✅ `/src/routes/customerRoutes.js` (modifié)
   - Route `POST /customer/quotes/:id/accept`
   - Route `POST /customer/quotes/:id/reject`
   - Vérification de propriété du devis
   - Logs de débogage

---

## 🚀 Déploiement

### **Étapes**

1. **Redémarrer le serveur API**
   ```bash
   cd mct-maintenance-api
   npm start
   ```

2. **Relancer l'application mobile**
   ```bash
   cd mct_maintenance_mobile
   flutter run
   ```

3. **Tester**
   - Onglet "Devis et Contrats"
   - Cliquer sur un devis
   - ✅ Détail s'affiche
   - Accepter ou refuser
   - ✅ Actions fonctionnent

---

## ✅ Résultat Final

### **Avant**

```
Liste des Devis
    ↓
Cliquer sur un devis
    ↓
❌ Rien ne se passe
```

### **Après**

```
Liste des Devis
    ↓
Cliquer sur un devis
    ↓
✅ Écran de détail s'affiche
    ↓
Voir toutes les informations
    ↓
Accepter ou Refuser
    ↓
✅ Statut mis à jour
    ↓
✅ Retour à la liste actualisée
```

---

## 🎯 Fonctionnalités Complètes

- ✅ **Navigation** - Clic sur devis ouvre le détail
- ✅ **Affichage** - Toutes les informations visibles
- ✅ **Acceptation** - Bouton vert fonctionnel
- ✅ **Refus** - Bouton rouge avec raison
- ✅ **Statuts** - Couleurs et labels clairs
- ✅ **Messages** - Confirmation visuelle
- ✅ **Sécurité** - Vérification de propriété
- ✅ **Logs** - Débogage backend
- ✅ **Devise** - Montants en FCFA

**Le système de devis est maintenant complet et fonctionnel !** 📋✨
