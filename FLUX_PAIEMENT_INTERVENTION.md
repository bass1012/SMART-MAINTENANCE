# 💳 Flux Complet : Paiement de Devis → Intervention Planifiée

## 📋 Vue d'ensemble

Après l'acceptation et le paiement d'un devis par le client, le système automatise complètement l'assignation du technicien et la planification de l'intervention.

---

## 🔄 Flux de Traitement

### 1️⃣ **Client accepte le devis**
- Le client consulte le devis dans l'application mobile
- Il clique sur "Accepter le devis"
- Navigation automatique vers l'écran de paiement CinetPay

### 2️⃣ **Paiement via CinetPay**
- Le client effectue le paiement (Mobile Money, Carte bancaire, etc.)
- CinetPay traite le paiement
- Webhook envoyé à l'API backend

### 3️⃣ **Traitement Backend (Automatique)** 🤖

#### **A. Mise à jour du devis**
```javascript
await quote.update({
  payment_status: 'paid',
  paid_at: new Date(),
  payment_method: 'CinetPay'
});
```

#### **B. Assignation du technicien**
- ✅ Le technicien qui a effectué le diagnostic est **automatiquement assigné** à l'intervention
- 📅 Date d'intervention planifiée : **2 jours ouvrés après le paiement**
- ⏰ Heure par défaut : **9h00 du matin**
- 🚫 Évite les week-ends (samedi → lundi, dimanche → lundi)

```javascript
const scheduledDate = new Date();
scheduledDate.setDate(scheduledDate.getDate() + 2);

// Éviter les week-ends
if (scheduledDate.getDay() === 6) {  // Samedi
  scheduledDate.setDate(scheduledDate.getDate() + 2);
} else if (scheduledDate.getDay() === 0) {  // Dimanche
  scheduledDate.setDate(scheduledDate.getDate() + 1);
}

scheduledDate.setHours(9, 0, 0, 0);

await quote.intervention.update({
  status: 'assigned',
  technician_id: technicianId,
  scheduled_date: scheduledDate
});
```

#### **C. Mise à jour du rapport de diagnostic**
```javascript
await quote.diagnosticReport.update({
  status: 'approved'
});
```

### 4️⃣ **Notifications envoyées** 📧

#### **🔔 Notification Technicien**
```json
{
  "type": "intervention_assigned",
  "title": "🔧 Nouvelle intervention assignée",
  "message": "M. Dupont a payé le devis de 50000 FCFA. Intervention planifiée le mercredi 8 février 2026 à 09:00.",
  "data": {
    "intervention_id": 123,
    "quote_id": 45,
    "amount": 50000,
    "customer_name": "Jean Dupont",
    "scheduled_date": "2026-02-08T09:00:00Z",
    "address": "123 Avenue de la République"
  },
  "priority": "high"
}
```

#### **📱 Notification Client**
```json
{
  "type": "payment_confirmed",
  "title": "✅ Paiement confirmé",
  "message": "Votre paiement de 50000 FCFA a été confirmé. Intervention planifiée le mercredi 8 février 2026 à 09:00.",
  "data": {
    "intervention_id": 123,
    "quote_id": 45,
    "amount": 50000,
    "scheduled_date": "2026-02-08T09:00:00Z",
    "technician_id": 7
  },
  "priority": "high"
}
```

---

## 📱 Affichage dans l'Application Mobile

### **Écran Technicien**

Le technicien reçoit une notification push et peut voir :
- 📅 **Date et heure** : Mercredi 8 février 2026 à 09:00
- 👤 **Client** : Jean Dupont
- 📍 **Adresse** : 123 Avenue de la République
- 💰 **Montant payé** : 50 000 FCFA
- 📋 **Type** : Intervention de réparation
- 🔧 **Pièces nécessaires** : Liste des pièces du diagnostic

### **Écran Client**

Le client peut voir dans "Mes Interventions" :
- ✅ **Statut** : Intervention planifiée
- 📅 **Date et heure** : Mercredi 8 février 2026 à 09:00
- 🔧 **Technicien** : Nom du technicien assigné
- 💳 **Paiement** : Confirmé (50 000 FCFA)
- 📄 **Devis** : Lien vers le devis payé

---

## 🔧 Fichiers Modifiés

### Backend
**Fichier :** `mct-maintenance-api/src/controllers/payment/cinetpayController.js`

**Fonction modifiée :** `handleQuoteNotification`

**Lignes :** 702-830

**Changements :**
1. ✅ Assignation automatique du technicien du diagnostic
2. 📅 Planification de la date d'intervention (2 jours ouvrés)
3. ⏰ Définition de l'heure à 9h00
4. 🚫 Gestion des week-ends
5. 📧 Notifications enrichies avec date/heure/adresse

---

## 🧪 Test du Flux

### Étape 1 : Créer une intervention avec diagnostic
```bash
# Se connecter comme technicien
# Créer une demande d'intervention
# Soumettre un rapport de diagnostic avec pièces et coûts
```

### Étape 2 : Envoyer le devis au client
```bash
# Se connecter comme admin/technicien
# Créer le devis depuis le diagnostic
# Envoyer le devis au client
```

### Étape 3 : Accepter et payer le devis
```bash
# Se connecter comme client dans l'app mobile
# Consulter le devis
# Cliquer sur "Accepter et Payer"
# Effectuer le paiement via CinetPay (simulation)
```

### Étape 4 : Vérifier les notifications
```bash
# Vérifier la notification du technicien (app mobile)
# Vérifier la notification du client (app mobile)
# Vérifier dans le calendrier du technicien
```

### Étape 5 : Vérifier en base de données
```sql
-- Vérifier l'intervention
SELECT 
  id,
  status,
  technician_id,
  scheduled_date,
  payment_date
FROM interventions
WHERE id = <intervention_id>;

-- Vérifier le devis
SELECT 
  id,
  payment_status,
  paid_at,
  intervention_id
FROM quotes
WHERE id = <quote_id>;

-- Vérifier les notifications
SELECT 
  user_id,
  type,
  title,
  message,
  created_at
FROM notifications
WHERE type IN ('intervention_assigned', 'payment_confirmed')
ORDER BY created_at DESC
LIMIT 5;
```

---

## ⚙️ Configuration

### Variables d'environnement
Aucune nouvelle variable requise. Le système utilise :
- `CINETPAY_API_KEY` : Clé API CinetPay
- `CINETPAY_SITE_ID` : ID du site CinetPay
- `CINETPAY_NOTIFY_URL` : URL du webhook

### Paramètres de planification
Modifiables dans le code (`cinetpayController.js` ligne ~715) :
```javascript
// Nombre de jours après le paiement
scheduledDate.setDate(scheduledDate.getDate() + 2); // 2 jours

// Heure de début d'intervention
scheduledDate.setHours(9, 0, 0, 0); // 9h00
```

---

## 📊 Statuts de l'Intervention

| Statut | Description |
|--------|-------------|
| `pending` | En attente de diagnostic |
| `assigned` | **Assignée au technicien après paiement** |
| `accepted` | Technicien a accepté l'intervention |
| `on_the_way` | Technicien en route |
| `arrived` | Technicien arrivé sur place |
| `in_progress` | Intervention en cours |
| `completed` | Intervention terminée |
| `cancelled` | Intervention annulée |

---

## 🚀 Prochaines Améliorations

1. **Proposer plusieurs créneaux horaires** au client
2. **Notification SMS** en plus de la notification push
3. **Rappel 1 jour avant** l'intervention
4. **Possibilité de reporter** la date par le client
5. **Estimation du temps de trajet** pour le technicien
6. **Optimisation des tournées** pour les techniciens

---

## 📞 Support

Pour toute question sur ce flux :
- Backend : `mct-maintenance-api/src/controllers/payment/cinetpayController.js`
- Documentation CinetPay : `PAIEMENT_MOBILE.md`
- Tests : Utiliser le mode simulation CinetPay

---

**Dernière mise à jour :** 6 février 2026
