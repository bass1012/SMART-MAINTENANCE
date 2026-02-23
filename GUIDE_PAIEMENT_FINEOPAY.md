# 🎯 Guide d'utilisation : Générateur de Lien FineoPay

## 📋 Vue d'ensemble

Le système de paiement FineoPay est maintenant intégré dans 3 interfaces :
1. **Application Mobile Flutter** (Client)
2. **Dashboard Admin** (Administrateur)
3. **API Backend** (Automatisation)

---

## 💻 Dashboard Admin - Comment générer un lien de paiement

### Étape 1 : Accéder à une commande

1. Connectez-vous au Dashboard : `http://localhost:3001`
2. Allez dans **"Commandes"** dans le menu
3. Cliquez sur une commande **non payée** (statut `EN ATTENTE` ou `EN COURS`)

### Étape 2 : Localiser le générateur

Dans la page de détails de la commande, **après la liste des articles et le total**, vous verrez une section :

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💳 Paiement en ligne FineoPay
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────┐
│ [🔗] Générer un lien de paiement    │
│       FineoPay                       │
└─────────────────────────────────────┘
```

### Étape 3 : Générer le lien

1. **Cliquez sur le bouton bleu** "Générer un lien de paiement FineoPay"
2. Attendez 1-2 secondes pendant la génération
3. Le lien apparaît dans un champ texte :

```
✅ Lien de paiement généré avec succès !
Copiez ce lien et envoyez-le au client pour qu'il effectue le paiement.

┌────────────────────────────────────────────────┬───┬───┐
│ https://demo.fineopay.com/smart_maintenance... │[📋]│[🔗]│
└────────────────────────────────────────────────┴───┴───┘
```

### Étape 4 : Envoyer le lien au client

**Option A : Copier-Coller**
- Cliquez sur l'icône **📋 (Copier)**
- Le lien est copié dans votre presse-papiers
- Collez-le dans WhatsApp, Email, SMS, etc.

**Option B : Aperçu**
- Cliquez sur l'icône **🔗 (Ouvrir)**
- Le lien s'ouvre dans une nouvelle fenêtre
- Vous pouvez tester le paiement ou montrer au client

**Option C : Partage direct**
```
Exemple de message à envoyer :

Bonjour M./Mme [NOM],

Votre commande #CMD-123456 d'un montant de 50 000 FCFA 
est prête. Veuillez effectuer le paiement via ce lien :

https://demo.fineopay.com/smart_maintenance_by_mct/xxxxx/checkout

Merci !
```

---

## 📱 Application Mobile - Flux automatique

Dans l'app mobile, **le lien se génère automatiquement** :

1. Client passe une commande
2. Clique sur "Payer maintenant"
3. Le navigateur s'ouvre avec la page FineoPay
4. Client effectue le paiement
5. ✅ Notification automatique à la fin

---

## 🔄 Suivi du paiement

### Côté Dashboard

Après que le client paie, vous verrez :

1. **Notification en temps réel** (si activée)
2. **Email de confirmation** automatique
3. **Statut mis à jour** : `En attente` → `Payée`
4. La section "Paiement FineoPay" **disparaît** (commande déjà payée)

### Côté Mobile

Le client reçoit :
1. **Notification push** : "✅ Paiement confirmé"
2. **Email de reçu** avec détails de la transaction
3. **Mise à jour automatique** du statut de la commande

---

## 🧪 Tests

### 1. Tester la génération de lien

```bash
# Terminal 1 : Backend
cd mct-maintenance-api
npm start

# Terminal 2 : Dashboard
cd mct-maintenance-dashboard
npm start

# Ouvrir : http://localhost:3001
```

### 2. Créer une commande de test

```bash
# Via SQL
sqlite3 mct-maintenance-api/database.sqlite

INSERT INTO orders (customer_id, total_amount, status, payment_status, reference, created_at, updated_at)
VALUES (1, 25000, 'PENDING', 'PENDING', 'TEST-' || datetime('now'), datetime('now'), datetime('now'));

# Vérifier
SELECT id, reference, total_amount, payment_status FROM orders ORDER BY id DESC LIMIT 1;
```

### 3. Générer le lien

1. Allez sur la commande créée
2. Cliquez sur "Générer lien"
3. **Vous devriez voir** : `https://demo.fineopay.com/smart_maintenance_by_mct/...`

---

## 🔍 Dépannage

### Erreur : "orderId, amount et title sont requis"
➡️ La commande n'a pas de montant ou référence valide

### Le bouton n'apparaît pas
➡️ Vérifiez que :
- `paymentStatus !== 'PAID'` (pas déjà payée)
- `status !== 'CANCELLED'` (pas annulée)

### Lien non généré
➡️ Vérifiez les logs backend :
```bash
# Dans le terminal backend
GET /api/fineopay/order-status/51 200
✅ Lien de paiement FineoPay créé pour commande #51
```

### Variables d'environnement manquantes
```bash
# Vérifier dans .env
cat mct-maintenance-api/.env | grep FINEOPAY

# Devrait afficher :
FINEOPAY_ENV=sandbox
FINEOPAY_BUSINESS_CODE=smart_maintenance_by_mct
FINEOPAY_API_KEY=fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923
```

---

## 🎬 Démonstration complète

**Scénario : Client commande un produit**

```
┌─────────────────────────────────────────────────────────┐
│ 1️⃣ CLIENT (Mobile)                                      │
│    └─ Ajoute produit au panier                          │
│    └─ Passe commande                                    │
│    └─ Clique "Payer avec FineoPay"                      │
│    └─ Navigateur s'ouvre → Page paiement                │
└─────────────────────────────────────────────────────────┘
                          ↓
                   [FineoPay traite]
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 2️⃣ BACKEND (API)                                        │
│    └─ Reçoit callback /api/fineopay/callback            │
│    └─ Vérifie transaction avec FineoPay                 │
│    └─ Met à jour : payment_status = 'paid'              │
│    └─ Envoie notification push au client                │
│    └─ Envoie email confirmation                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 3️⃣ ADMIN (Dashboard)                                    │
│    └─ Voit notification temps réel                      │
│    └─ Statut commande : EN ATTENTE → PAYÉE              │
│    └─ Peut télécharger facture PDF                      │
└─────────────────────────────────────────────────────────┘
```

---

## ✨ Fonctionnalités avancées

### Génération manuelle depuis le Dashboard

**Cas d'usage :**
- Client n'a pas smartphone
- Paiement par ordinateur
- Envoi par email/WhatsApp

**Processus :**
```
Admin génère lien → Envoie au client → Client paie sur PC/Mobile
```

### Vérification automatique du statut

L'écran de confirmation mobile vérifie automatiquement :
- ⏱️ Toutes les 3 secondes
- 🔄 Pendant 60 secondes maximum
- ✅ S'arrête dès que paiement confirmé

---

## 📊 Statistiques disponibles

Dans le Dashboard, vous pouvez voir :
- 💰 Total des paiements FineoPay
- 📈 Taux de conversion (commandes → paiements)
- ⏱️ Temps moyen de paiement
- 🔢 Nombre de liens générés

---

## 🔒 Sécurité

✅ **Toutes les communications sont sécurisées :**
- HTTPS uniquement
- Authentication Bearer Token
- Vérification serveur-à-serveur avec FineoPay
- Pas de données sensibles côté client

---

## 📞 Support

**En cas de problème :**
1. Vérifier les logs backend
2. Tester avec Postman/curl
3. Vérifier configuration `.env`
4. Contacter support FineoPay si nécessaire

---

## 🎉 C'est terminé !

Vous êtes maintenant prêt à accepter des paiements FineoPay ! 🚀
