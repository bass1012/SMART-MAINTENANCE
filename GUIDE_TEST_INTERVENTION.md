# 🧪 Guide de Test : Assignation Intervention après Paiement

## 📋 Situation Actuelle

Vous avez **la commande #34** qui est liée à **un devis #29** provenant d'**une intervention #43**.

Le flux est maintenant configuré pour :
1. ✅ Mettre à jour le devis comme payé
2. ✅ Assigner le technicien du diagnostic à l'intervention
3. ✅ Planifier la date d'intervention (2 jours ouvrés)
4. ✅ Notifier le technicien avec tous les détails

---

## 🚀 Comment Tester

### Option 1 : Via l'Interface Admin (Dashboard Web)

1. **Démarrer le backend**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
   npm start
   ```

2. **Ouvrir le dashboard admin**
   - URL : http://localhost:5000 (ou votre URL de dashboard)
   - Se connecter avec un compte admin

3. **Aller dans la section "Commandes"**
   - Trouver la commande #34 (CMD-1770369229200-29)
   - Cliquer sur "Marquer comme payé" ou changer le statut à "Paid"

4. **Vérifier dans les logs backend**
   Vous devriez voir :
   ```
   ✅ Order 34 payment status updated: pending → paid
   🔍 Commande liée à un devis (quote_id: 29), traitement intervention...
   ✅ Devis trouvé (ID: 29), mise à jour...
   ✅ Technicien 15 assigné à l'intervention 43
   📅 Date planifiée: [date dans 2 jours]
   ✅ Notification envoyée au technicien (ID: 15)
   ```

5. **Vérifier l'intervention dans l'app mobile technicien**
   - Se connecter avec le compte du technicien ID 15
   - Aller dans "Mes Interventions"
   - Vous devriez voir l'intervention #43 avec le statut "Assignée"
   - Date planifiée visible

### Option 2 : Via Script de Test

1. **Démarrer le backend**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
   npm start
   ```

2. **Dans un autre terminal, exécuter le script**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE
   ./TEST/test-order-payment-quick.sh
   ```

Le script va :
- Se connecter comme admin
- Marquer la commande #34 comme payée
- Afficher l'état avant/après
- Lister les notifications créées

### Option 3 : Via API directe (avec votre token)

Si vous avez déjà un token admin valide :

```bash
# Remplacer YOUR_TOKEN par votre vrai token
curl -X PATCH http://localhost:5000/api/orders/34/payment-status \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paymentStatus": "paid"}'
```

### Option 4 : Simuler un paiement réel CinetPay

Si vous voulez tester le flux complet depuis l'app mobile :

1. **Dans l'app mobile client** :
   - Consulter les devis (section Devis/Contrats)
   - Cliquer sur le devis #29
   - Cliquer sur "Accepter et Payer"
   - Compléter le paiement CinetPay (en mode simulation)

2. **CinetPay envoie un webhook** au backend
   - Endpoint : `/api/payments/cinetpay/notify-quote`
   - Le même flux d'assignation se déclenche

---

## 🔍 Vérification en Base de Données

Après le test, vérifiez que tout s'est bien passé :

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Vérifier l'intervention
sqlite3 database.sqlite "
SELECT 
  i.id,
  i.status,
  i.technician_id,
  datetime(i.scheduled_date, 'localtime') as date_planifiee,
  q.payment_status as devis_status,
  dr.technician_id as tech_diagnostic
FROM interventions i
JOIN quotes q ON i.id = q.intervention_id
JOIN diagnostic_reports dr ON q.diagnostic_report_id = dr.id
WHERE i.id = 43;
"
```

**Résultats attendus :**
```
id  | status   | technician_id | date_planifiee        | devis_status | tech_diagnostic
----+----------+---------------+-----------------------+--------------+----------------
43  | assigned | 15            | 2026-02-08 09:00:00   | paid         | 15
```

```bash
# Vérifier les notifications
sqlite3 database.sqlite "
SELECT 
  user_id,
  type,
  title,
  message,
  priority,
  created_at
FROM notifications
WHERE type IN ('intervention_assigned', 'payment_confirmed')
AND created_at > datetime('now', '-10 minutes')
ORDER BY created_at DESC;
"
```

**Résultats attendus :**
- 1 notification `intervention_assigned` pour le technicien (user_id = 15)
- 1 notification `payment_confirmed` pour le client (user_id = 66)

---

## 📱 Vérification dans l'App Mobile

### Côté Technicien (User ID 15)

1. **Ouvrir l'app mobile**
2. **Se connecter comme technicien**
3. **Vérifier les notifications** :
   - Notification "🔧 Nouvelle intervention assignée"
   - Message avec nom du client, montant, date et heure

4. **Aller dans "Mes Interventions"** :
   - Voir l'intervention #43
   - Statut : "Assignée"
   - Date : Environ 2 jours après aujourd'hui à 9h00
   - Client visible
   - Adresse visible

5. **Vérifier le calendrier** :
   - L'intervention doit apparaître dans le calendrier
   - À la date planifiée

### Côté Client (User ID 66)

1. **Se connecter comme client**
2. **Vérifier les notifications** :
   - Notification "✅ Paiement confirmé"
   - Message avec date et heure de l'intervention

3. **Aller dans "Mes Interventions"** :
   - Voir l'intervention #43
   - Statut mis à jour
   - Date planifiée visible

---

## ⚠️ Problèmes Courants

### Le technicien ne reçoit pas de notification

**Cause :** Le token FCM n'est pas enregistré ou expiré

**Solution :**
1. Ouvrir l'app mobile technicien
2. Se déconnecter puis se reconnecter
3. Accepter les notifications quand demandé
4. Retester

### L'intervention n'apparaît pas

**Cause :** Le cache de l'app n'est pas rafraîchi

**Solution :**
1. Pull-to-refresh sur la liste des interventions
2. Ou fermer/rouvrir l'app

### Le devis reste en "pending"

**Cause :** L'endpoint `/api/orders/payment-status` n'a pas été appelé correctement

**Solution :**
1. Vérifier les logs backend
2. Vérifier que le backend tourne
3. Vérifier le token d'authentification

---

## 📊 Données de Test

Voici les données actuelles pour vos tests :

| Élément | ID | Valeur |
|---------|-----|--------|
| Commande | 34 | CMD-1770369229200-29 |
| Devis | 29 | Lié à l'intervention 43 |
| Intervention | 43 | Status: quote_pending → assigned |
| Technicien Diagnostic | 15 | Doit être assigné |
| Client | 66 | bassirou2010@gmail.com |
| Montant | - | 30000 FCFA |

---

## ✅ Checklist de Test

- [ ] Backend démarré
- [ ] Commande marquée comme payée
- [ ] Logs backend affichent l'assignation
- [ ] Devis en statut "paid" en DB
- [ ] Intervention en statut "assigned" en DB
- [ ] Technicien assigné = technicien du diagnostic
- [ ] Date planifiée dans ~2 jours à 9h
- [ ] Notification technicien créée en DB
- [ ] Notification client créée en DB
- [ ] App mobile technicien : intervention visible
- [ ] App mobile technicien : notification reçue
- [ ] App mobile client : notification reçue

---

**Prochaine étape :** Démarrez le backend et testez avec l'une des options ci-dessus ! 🚀
