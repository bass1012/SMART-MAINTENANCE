# 🔔 Correction : Notifications Devis pour les Clients

**Date :** 31 Octobre 2025  
**Problème :** Le client ne reçoit pas de notification lorsqu'un devis lui est envoyé

---

## 🐛 Symptôme

Lorsqu'un admin **crée et envoie un devis** à un client depuis le dashboard web :

1. ✅ Le devis est créé avec statut `draft`
2. ✅ L'admin change le statut à `sent` (envoyé)
3. ❌ **Le client ne reçoit AUCUNE notification**
4. ❌ Le client n'est pas informé qu'il a un nouveau devis à consulter

**Impact :**
- Le client ne sait pas qu'il a reçu un devis
- Il ne peut pas répondre rapidement
- Perte de conversion potentielle

---

## 🔍 Analyse du Problème

### Workflow Actuel

```
Admin Dashboard                    Backend                    Client
     │                                │                          │
     │ 1. Créer devis (draft)         │                          │
     │───────────────────────────────>│                          │
     │                                │ notifyNewQuote()         │
     │                                │────────────────────────> │
     │                                │ ✅ "Nouveau devis créé"  │
     │                                │                          │
     │ 2. Modifier statut → "sent"    │                          │
     │───────────────────────────────>│                          │
     │                                │ notifyQuoteUpdated()     │
     │                                │────────────────────────> │
     │                                │ ❌ "Devis modifié"       │ ← Pas clair !
```

### Problème Identifié

Quand le statut passe à `sent`, le système utilisait `notifyQuoteUpdated()` qui envoie :
- **Titre :** "Devis modifié"
- **Message :** "Votre devis de XXX FCFA a été mis à jour"

**Problèmes :**
1. ❌ Message générique, pas clair
2. ❌ Priorité identique aux autres modifications
3. ❌ Pas d'information sur la date d'expiration
4. ❌ Le client ne comprend pas qu'il doit **agir maintenant**

---

## ✅ Solution Implémentée

### 1. Nouvelle Notification Spécifique : `notifyQuoteSent`

**Fichier :** `/src/services/notificationHelpers.js`

```javascript
// Notification: Devis envoyé au client
const notifyQuoteSent = async (quote, customer) => {
  const userId = customer.user_id || customer.id;
  
  return await notificationService.create({
    userId: userId,
    type: 'quote_sent',
    title: 'Nouveau devis reçu',
    message: `Vous avez reçu un devis de ${quote.total} FCFA. Consultez-le et répondez avant expiration.`,
    data: {
      quoteId: quote.id,
      reference: quote.reference,
      amount: quote.total,
      expiryDate: quote.expiryDate
    },
    priority: 'high',
    actionUrl: `/quotes/${quote.id}`
  });
};
```

**Améliorations :**
- ✅ **Titre clair :** "Nouveau devis reçu"
- ✅ **Message incitatif :** "Consultez-le et répondez avant expiration"
- ✅ **Priorité haute :** `high` (au lieu de `medium`)
- ✅ **Données complètes :** référence + date d'expiration
- ✅ **Type distinct :** `quote_sent` (pour filtrage/stats)

---

### 2. Détection Intelligente du Changement de Statut

**Fichier :** `/src/controllers/quote/quoteController.js`

```javascript
const updateQuote = async (req, res) => {
  const transaction = await Quote.sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { items, ...quoteData } = req.body;
    
    const quote = await Quote.findByPk(id, { transaction });
    
    // Sauvegarder l'ancien statut
    const oldStatus = quote.status;
    
    // Mettre à jour le devis
    await quote.update(quoteData, { transaction });
    
    // ... mise à jour des items ...
    
    await transaction.commit();
    
    const updatedQuote = await Quote.findByPk(id, { 
      include: [{ model: QuoteItem, as: 'items' }] 
    });
    
    // 📬 Notification intelligente selon le changement
    const newStatus = updatedQuote.status;
    const wasSent = oldStatus !== 'sent' && newStatus === 'sent';
    
    if (updatedQuote.customerId) {
      const customerProfile = await CustomerProfile.findByPk(
        updatedQuote.customerId, 
        { include: [{ model: User, as: 'user' }] }
      );
      
      if (customerProfile) {
        if (wasSent) {
          // Devis envoyé → notification spécifique
          await notifyQuoteSent(updatedQuote, customerProfile);
          console.log('✅ Notification "Devis envoyé" envoyée');
        } else {
          // Autre modification → notification standard
          await notifyQuoteUpdated(updatedQuote, customerProfile);
          console.log('✅ Notification "Devis modifié" envoyée');
        }
      }
    }
    
    res.status(200).json({ success: true, data: updatedQuote });
  } catch (error) {
    await transaction.rollback();
    res.status(500).json({ success: false, error: error.message });
  }
};
```

**Logique :**
1. **Sauvegarde** de l'ancien statut avant modification
2. **Comparaison** après mise à jour
3. **Détection** : si `old !== 'sent' && new === 'sent'`
4. **Notification adaptée** selon le cas

---

## 🔄 Workflow Corrigé

```
Admin Dashboard                    Backend                         Client
     │                                │                               │
     │ 1. Créer devis (draft)         │                               │
     │───────────────────────────────>│                               │
     │                                │ notifyNewQuote()              │
     │                                │──────────────────────────────>│
     │                                │ "Nouveau devis disponible"    │
     │                                │                               │
     │ 2. Modifier statut → "sent"    │                               │
     │───────────────────────────────>│                               │
     │                                │ Détection: wasSent = true     │
     │                                │ notifyQuoteSent()             │
     │                                │──────────────────────────────>│
     │                                │ ✅ "Nouveau devis reçu"       │
     │                                │ ✅ "Répondez avant expiration"│
     │                                │ ✅ Priority: HIGH             │
     │                                │ ✅ FCM Push + Socket.IO       │
```

---

## 📊 Comparaison Avant/Après

### ❌ AVANT

**Notification reçue :**
```
🔔 Devis modifié
Votre devis de 1250000 FCFA a été mis à jour
Priority: high
```

**Problèmes :**
- Pas clair qu'il s'agit d'un **nouveau** devis
- Pas d'incitation à agir
- Le client peut ignorer

---

### ✅ APRÈS

**Notification reçue :**
```
🔔 Nouveau devis reçu
Vous avez reçu un devis de 1250000 FCFA. 
Consultez-le et répondez avant expiration.
Priority: high
```

**Avantages :**
- ✅ Clair : "Nouveau devis **reçu**"
- ✅ Incitatif : "**Consultez-le et répondez**"
- ✅ Urgence : "**avant expiration**"
- ✅ Données complètes (référence, expiration)

---

## 🧪 Tests de Validation

### Test 1 : Création de Devis (Draft)

**Étapes :**
```bash
# Dashboard web admin
1. Aller sur /devis
2. Cliquer "Nouveau devis"
3. Sélectionner un client
4. Ajouter des produits
5. Sauvegarder (statut = draft)
```

**Résultat attendu :**
```
Client:
🔔 Nouveau devis disponible
Un devis de 1250000 FCFA a été créé pour vous
```

**Type notification :** `quote_created`

---

### Test 2 : Envoi du Devis (Draft → Sent)

**Étapes :**
```bash
# Dashboard web admin
1. Ouvrir le devis créé (statut = draft)
2. Cliquer "Modifier"
3. Changer statut → "Envoyé" (sent)
4. Sauvegarder
```

**Résultat attendu :**
```
Client:
🔔 Nouveau devis reçu
Vous avez reçu un devis de 1250000 FCFA. 
Consultez-le et répondez avant expiration.

Dashboard Web (si connecté):
- Badge notification apparaît
- Liste notifications mise à jour

App Mobile (si installée):
- Notification push FCM
- Badge sur l'icône
```

**Type notification :** `quote_sent` ✅

**Logs backend attendus :**
```
📬 Notification devis: old=draft, new=sent, changed=true, sent=true
📤 Envoi notification au client user_id: 14
✅ Notification "Devis envoyé" envoyée au client
```

---

### Test 3 : Modification Simple (Sent → Sent)

**Étapes :**
```bash
# Dashboard web admin
1. Ouvrir un devis déjà envoyé (statut = sent)
2. Modifier le montant ou les items
3. Sauvegarder (statut reste = sent)
```

**Résultat attendu :**
```
Client:
🔔 Devis modifié
Votre devis de 1300000 FCFA a été mis à jour
```

**Type notification :** `quote_updated`

**Logs backend :**
```
📬 Notification devis: old=sent, new=sent, changed=false, sent=false
✅ Notification "Devis modifié" envoyée au client
```

---

### Test 4 : Application Mobile

**Prérequis :**
- App mobile installée
- Client connecté
- Token FCM enregistré

**Étapes :**
```bash
1. Admin envoie un devis (draft → sent)
2. Vérifier sur le mobile du client
```

**Résultat attendu :**

**App en foreground :**
```
🔔 Notification apparaît en haut
Titre: Nouveau devis reçu
Message: Vous avez reçu un devis...
Tap → Ouvre l'écran des devis
```

**App en background :**
```
📱 Notification push Android/iOS
Badge sur l'icône de l'app
Son/vibration
Tap → Ouvre l'app sur les devis
```

**App fermée :**
```
📱 Notification système
Stockée dans le centre de notifications
Ouvre l'app au tap
```

---

### Test 5 : Dashboard Web

**Prérequis :**
- Client connecté sur le dashboard web

**Étapes :**
```bash
1. Client connecté sur http://localhost:3001
2. Admin envoie un devis
3. Vérifier sur le dashboard client
```

**Résultat attendu :**

**Cloche de notification 🔔 :**
```
Badge rouge avec compteur (1)
Clic → Liste des notifications
┌────────────────────────────────────────┐
│ 🔔 Nouveau devis reçu             2min │
│ Vous avez reçu un devis de...          │
│ [Voir] [Marquer lu] [×]                │
└────────────────────────────────────────┘
```

**Toast en bas à droite :**
```
✅ Nouveau devis reçu
Vous avez reçu un devis de 1250000 FCFA
```

---

## 🔧 Déploiement

### Étapes de Déploiement

1. **Arrêter le serveur backend :**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
   lsof -ti:3000 | xargs kill -9
   ```

2. **Redémarrer le serveur :**
   ```bash
   npm start
   ```

3. **Vérifier les logs au démarrage :**
   ```
   ✅ Serveur démarré sur le port 3000
   ✅ Base de données connectée
   ✅ Socket.IO initialisé
   ```

4. **Tester immédiatement :**
   - Créer un devis (draft)
   - L'envoyer (sent)
   - Vérifier la notification client

---

## 📝 Logs de Débogage

### Logs Backend (Succès)

```
📋 Mise à jour du devis: 15
🔄 Ancien statut: draft
🔄 Nouveau statut: sent
📬 Notification devis: old=draft, new=sent, changed=true, sent=true
✅ CustomerProfile trouvé, user_id: 14
📤 Envoi notification au client user_id: 14
📧 Création notification: type=quote_sent, userId=14
✅ Notification créée en DB (id: 42)
🌐 Envoi Socket.IO au user 14
✅ Socket envoyé à 1 client(s)
📱 Envoi FCM push au token: fMCF...
✅ FCM envoyé avec succès
✅ Notification "Devis envoyé" envoyée au client
PUT /api/quotes/15 200 245ms
```

---

### Logs Backend (Erreur)

```
📬 Notification devis: old=draft, new=sent, changed=true, sent=true
❌ CustomerProfile non trouvé pour customerId: 99
⚠️  Notification ignorée
```

**Solution :** Vérifier que le `customerId` du devis existe dans `customer_profiles`.

---

### Vérification Base de Données

```sql
-- Vérifier la dernière notification
SELECT 
  id, 
  user_id, 
  type, 
  title, 
  message, 
  priority,
  read,
  created_at 
FROM notifications 
WHERE type = 'quote_sent' 
ORDER BY created_at DESC 
LIMIT 5;
```

**Résultat attendu :**
```
id|user_id|type      |title             |message                        |priority|read|created_at
42|14     |quote_sent|Nouveau devis reçu|Vous avez reçu un devis de...|high    |0   |2025-10-31 10:15:32
```

---

## 📋 Checklist Complète

### Backend
- [x] Fonction `notifyQuoteSent` créée
- [x] Import ajouté dans `quoteController.js`
- [x] Détection du changement de statut
- [x] Logique conditionnelle (sent vs updated)
- [x] Export du module mis à jour
- [ ] Serveur redémarré

### Tests Fonctionnels
- [ ] Test création devis (draft)
- [ ] Test envoi devis (draft → sent)
- [ ] Test modification devis (sent → sent)
- [ ] Test notification dashboard web
- [ ] Test notification app mobile (foreground)
- [ ] Test notification app mobile (background)
- [ ] Test notification app mobile (fermée)

### Vérifications
- [ ] Logs backend corrects
- [ ] Notification enregistrée en DB
- [ ] Socket.IO envoyé
- [ ] FCM push envoyé
- [ ] Client reçoit la notification
- [ ] Clic notification → Bon écran

---

## 🎯 Types de Notifications Devis

### Récapitulatif Complet

| Action | Statut | Notification | Priority | Type |
|--------|--------|--------------|----------|------|
| Création | `draft` | "Nouveau devis disponible" | high | `quote_created` |
| **Envoi** | `draft → sent` | **"Nouveau devis reçu"** | **high** | **`quote_sent`** ✅ |
| Modification | `sent → sent` | "Devis modifié" | high | `quote_updated` |
| Acceptation | `sent → accepted` | Notif admin | high | `quote_accepted` |
| Rejet | `sent → rejected` | Notif admin | medium | `quote_rejected` |

---

## 💡 Améliorations Futures

### Court Terme
- [ ] Ajouter date d'expiration dans le message
- [ ] Lien direct vers le devis dans la notification
- [ ] Compteur de jours restants

### Moyen Terme
- [ ] Notification de rappel 24h avant expiration
- [ ] Notification si devis expiré sans réponse
- [ ] Historique des notifications par devis

### Long Terme
- [ ] Préférences de notification par client
- [ ] Canal préféré (email, SMS, push)
- [ ] Résumé hebdomadaire des devis en attente

---

## 🔗 Fichiers Modifiés

### Backend
- ✅ `/src/services/notificationHelpers.js` (+21 lignes)
  - Nouvelle fonction `notifyQuoteSent`
  - Export mis à jour

- ✅ `/src/controllers/quote/quoteController.js` (+15 lignes)
  - Import de `notifyQuoteSent`
  - Sauvegarde de `oldStatus`
  - Logique conditionnelle de notification

### Documentation
- ✅ `/FIX_NOTIFICATIONS_DEVIS_CLIENT.md` (ce fichier)

---

## 🔗 Commandes Utiles

```bash
# Redémarrer le backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Voir les logs en temps réel
tail -f logs/app.log | grep notification

# Vérifier les notifications en DB
sqlite3 database.sqlite "
SELECT * FROM notifications 
WHERE type = 'quote_sent' 
ORDER BY created_at DESC 
LIMIT 5;
"

# Tester l'envoi d'un devis
curl -X PUT http://localhost:3000/api/quotes/15 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"status": "sent"}'
```

---

**Version :** 1.0  
**Date :** 31 Octobre 2025  
**Statut :** ✅ Corrigé, nécessite redémarrage backend  
**Impact :** Backend uniquement  
**Prochaine action :** Redémarrer le serveur et tester
