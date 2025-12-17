# ✅ Fix : Raison du Refus de Devis Non Enregistrée

## 🐛 Problème

**Symptôme :**
Quand un client refuse un devis et saisit une raison, celle-ci n'est pas récupérée. Le système affiche toujours "Raison du refus: Refusé par le client" sur mobile et web.

**Cause :**
Le backend enregistrait la raison dans le champ `notes` au lieu d'un champ dédié `rejection_reason`, et le frontend n'affichait pas cette information.

---

## ✅ Solution Appliquée

### **1. Ajout de la Colonne `rejection_reason` dans la Base de Données**

```sql
ALTER TABLE quotes ADD COLUMN rejection_reason TEXT;
```

### **2. Mise à Jour du Modèle Backend (Quote.js)**

```javascript
rejection_reason: { type: DataTypes.TEXT, field: 'rejection_reason' }
```

### **3. Mise à Jour des Contrôleurs Backend**

**`customerRoutes.js` (ligne 110) :**
```javascript
// Avant
const updateData = { status: 'rejected' };
if (reason) {
  updateData.notes = quote.notes ? `${quote.notes}\n\nRaison du refus: ${reason}` : `Raison du refus: ${reason}`;
}

// Après
const updateData = { 
  status: 'rejected',
  rejection_reason: reason || 'Refusé par le client'
};
```

**`quoteController.js` (ligne 307) :**
```javascript
// Avant
await quote.update({ 
  status: 'rejected', 
  notes: reason ? `Raison du rejet : ${reason}` : quote.notes 
});

// Après
await quote.update({ 
  status: 'rejected', 
  rejection_reason: reason || 'Refusé par le client'
});
```

### **4. Mise à Jour du Modèle Flutter (quote_contract_model.dart)**

```dart
class QuoteContract {
  // ...
  final String? rejectionReason; // Nouveau champ
  
  QuoteContract({
    // ...
    this.rejectionReason,
  });
  
  factory QuoteContract.fromJson(Map<String, dynamic> json) {
    return QuoteContract(
      // ...
      rejectionReason: json['rejection_reason'],
    );
  }
}
```

### **5. Mise à Jour de l'Affichage Flutter (quote_detail_screen.dart)**

**Avant :**
```dart
const Text('Vous avez refusé ce devis')
```

**Après :**
```dart
Column(
  children: [
    const Text('Vous avez refusé ce devis'),
    if (_quote.rejectionReason != null && _quote.rejectionReason!.isNotEmpty) ...[
      const Divider(),
      Text('Raison du refus:', style: TextStyle(fontWeight: FontWeight.w600)),
      Text(_quote.rejectionReason!),
    ],
  ],
)
```

### **6. Mise à Jour du Dashboard Web**

**Interface TypeScript (quotesService.ts) :**
```typescript
export interface Quote {
  // ...
  rejection_reason?: string;
}
```

**Affichage (QuoteDetail.tsx) :**
```tsx
{quote.rejection_reason && (
  <Descriptions.Item label="Raison du refus" span={3}>
    <Text type="danger">{quote.rejection_reason}</Text>
  </Descriptions.Item>
)}
```

---

## 🎯 Résultat

### **Avant :**
```
Client refuse un devis avec raison: "Prix trop élevé"
→ Backend enregistre dans notes: "Raison du refus: Prix trop élevé"
→ Mobile affiche: "Vous avez refusé ce devis" (pas de raison)
→ Web affiche: "Notes: Raison du refus: Prix trop élevé" (dans notes)
```

### **Après :**
```
Client refuse un devis avec raison: "Prix trop élevé"
→ Backend enregistre dans rejection_reason: "Prix trop élevé"
→ Mobile affiche: 
   "Vous avez refusé ce devis
    Raison du refus: Prix trop élevé" ✅
→ Web affiche: 
   "Raison du refus: Prix trop élevé" (champ dédié) ✅
```

---

## 📊 Fichiers Modifiés

### **Backend :**
1. **Base de données** : Ajout de la colonne `rejection_reason`
2. **`/src/models/Quote.js`** : Ajout du champ `rejection_reason`
3. **`/src/routes/customerRoutes.js`** : Utilisation de `rejection_reason`
4. **`/src/controllers/quote/quoteController.js`** : Utilisation de `rejection_reason`

### **Mobile (Flutter) :**
1. **`/lib/models/quote_contract_model.dart`** : Ajout du champ `rejectionReason`
2. **`/lib/screens/customer/quote_detail_screen.dart`** : Affichage de la raison

### **Web (Dashboard) :**
1. **`/src/services/quotesService.ts`** : Ajout du champ `rejection_reason`
2. **`/src/pages/quotes/QuoteDetail.tsx`** : Affichage de la raison

---

## 🧪 Test

### **1. Redémarrer le Backend**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9 && npm start
```

### **2. Tester depuis le Mobile**

1. Connecte-toi avec un client
2. Va dans "Devis et Contrat" → Onglet "Devis"
3. Ouvre un devis en statut "sent"
4. Clique sur "Refuser"
5. Saisis une raison : "Prix trop élevé"
6. Valide
7. Vérifie que la raison s'affiche dans les détails

### **3. Vérifier dans la Base de Données**

```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite \
  "SELECT id, reference, status, rejection_reason FROM quotes WHERE status = 'rejected';"
```

**Résultat attendu :**
```
1|DEV-001|rejected|Prix trop élevé
```

### **4. Vérifier dans le Dashboard Web**

1. Va dans "Devis"
2. Ouvre le devis refusé
3. Vérifie que "Raison du refus: Prix trop élevé" s'affiche ✅

### **5. Hot Restart Flutter**

```
R
```

---

## 🔍 Vérification API

**Test de refus de devis :**

```bash
curl -X POST http://localhost:3000/api/customer/quotes/1/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"reason": "Prix trop élevé pour mon budget"}'
```

**Réponse attendue :**
```json
{
  "success": true,
  "message": "Devis refusé",
  "data": {
    "id": 1,
    "status": "rejected",
    "rejection_reason": "Prix trop élevé pour mon budget"
  }
}
```

---

## 📝 Différences Importantes

### **Champ `notes` vs `rejection_reason` :**

**`notes` :**
- Champ générique pour toutes les notes
- Peut contenir plusieurs informations
- Affiché dans une section "Notes"

**`rejection_reason` :**
- Champ dédié pour la raison du refus
- Utilisé uniquement quand `status = 'rejected'`
- Affiché dans une section "Raison du refus" avec style rouge/danger

---

## ✅ Checklist

- [x] Ajouter la colonne `rejection_reason` dans la base
- [x] Mettre à jour le modèle Quote backend
- [x] Mettre à jour les contrôleurs backend
- [x] Mettre à jour le modèle Flutter
- [x] Mettre à jour l'affichage Flutter
- [x] Mettre à jour l'interface TypeScript
- [x] Mettre à jour l'affichage web
- [ ] Redémarrer le backend
- [ ] Hot restart Flutter
- [ ] Tester le refus d'un devis
- [ ] Vérifier l'affichage mobile
- [ ] Vérifier l'affichage web

---

## 🎉 Résumé

**Problème :**
La raison du refus saisie par le client n'était pas enregistrée dans un champ dédié et n'était pas affichée correctement.

**Solution :**
- Ajout d'un champ `rejection_reason` dans la base de données
- Mise à jour des modèles backend et frontend
- Affichage dédié de la raison du refus sur mobile et web

**Résultat :**
La raison du refus est maintenant correctement enregistrée et affichée sur mobile et web avec un style approprié.

---

**Redémarre le backend et teste le refus d'un devis !** 🎯✅
