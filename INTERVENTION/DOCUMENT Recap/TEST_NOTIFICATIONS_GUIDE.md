# 🧪 Guide de Test - Système de Notifications

## ✅ Prérequis

- ✅ Backend démarré sur `http://localhost:3000`
- ✅ Dashboard démarré sur `http://localhost:3001`

## 🚀 Méthode 1 : Test via l'App Mobile Flutter

### **C'est la méthode la plus simple !**

1. **Ouvrir l'app mobile Flutter**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
   flutter run
   ```

2. **Se connecter avec un compte client**

3. **Créer une demande d'intervention :**
   - Aller dans l'onglet "Interventions"
   - Cliquer sur le bouton "+"
   - Remplir le formulaire
   - Soumettre

4. **Vérifier le dashboard web :**
   - Ouvrir `http://localhost:3001` dans le navigateur
   - Se connecter avec un compte admin
   - **Regarder l'icône de cloche 🔔 dans le header**
   - Le badge devrait afficher "1"
   - Un toast devrait apparaître : "Nouvelle demande d'intervention"

5. **Cliquer sur la cloche :**
   - Le dropdown s'ouvre
   - La notification apparaît avec :
     - Titre : "Nouvelle demande d'intervention"
     - Message avec le nom du client
     - Bordure bleue (non lue)
     - Fond coloré selon la priorité

---

## 🚀 Méthode 2 : Test via Postman/cURL

### **Étape 1 : Obtenir un token d'authentification**

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "VOTRE_EMAIL",
    "password": "VOTRE_PASSWORD"
  }'
```

**Copier le token** de la réponse.

### **Étape 2 : Créer une intervention de test**

```bash
curl -X POST http://localhost:3000/api/interventions \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification - Climatiseur en panne",
    "description": "Test du système de notifications",
    "customer_id": 1,
    "scheduled_date": "2025-01-26T10:00:00Z",
    "priority": "high"
  }'
```

### **Étape 3 : Vérifier sur le dashboard**

1. Ouvrir `http://localhost:3001`
2. Se connecter avec un compte admin
3. **Regarder la cloche 🔔** → Badge devrait afficher "1"
4. **Cliquer sur la cloche** → Notification visible

---

## 🚀 Méthode 3 : Test via Postman (Interface graphique)

### **Test 1 : Nouvelle Intervention**

**POST** `http://localhost:3000/api/interventions`

**Headers:**
```
Authorization: Bearer VOTRE_TOKEN
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "title": "Test Notification - Réparation urgente",
  "description": "Test du système de notifications en temps réel",
  "customer_id": 1,
  "scheduled_date": "2025-01-26T10:00:00Z",
  "priority": "high"
}
```

**Résultat attendu :**
- ✅ Réponse 201 Created
- ✅ Badge apparaît sur le dashboard
- ✅ Toast "Nouvelle demande d'intervention"

---

### **Test 2 : Nouvelle Réclamation**

**POST** `http://localhost:3000/api/complaints`

**Body (JSON):**
```json
{
  "customerId": 1,
  "subject": "Test Notification - Produit défectueux",
  "description": "Test du système de notifications",
  "priority": "high",
  "category": "product_quality"
}
```

**Résultat attendu :**
- ✅ Badge s'incrémente
- ✅ Toast "Nouvelle réclamation"

---

### **Test 3 : Nouvelle Commande**

**POST** `http://localhost:3000/api/orders`

**Body (JSON):**
```json
{
  "items": [
    {
      "product_id": 1,
      "quantity": 1
    }
  ],
  "shipping_address": "123 Test Street, Abidjan",
  "payment_method": "card",
  "notes": "Test notification"
}
```

**Résultat attendu :**
- ✅ Badge s'incrémente
- ✅ Toast "Nouvelle commande"

---

### **Test 4 : Changement de statut commande**

**PATCH** `http://localhost:3000/api/orders/1`

**Body (JSON):**
```json
{
  "status": "shipped"
}
```

**Résultat attendu :**
- ✅ Client reçoit notification "Commande expédiée"

---

## 📊 Vérifications sur le Dashboard

### **1. Badge de notifications**
- Icône de cloche 🔔 dans le header
- Badge rouge avec le nombre de notifications non lues
- Animation pulse du badge

### **2. Dropdown de notifications**
- Cliquer sur la cloche
- Liste des notifications
- Bouton "Tout marquer comme lu"
- Scroll si plus de 5 notifications

### **3. Notification individuelle**
- Icône selon la priorité :
  - 🔴 Urgent (rouge)
  - ⚠️ High (orange)
  - 🔵 Medium (bleu)
  - ✅ Low (vert)
- Titre en gras si non lue
- Message descriptif
- Date relative ("Il y a 2 min")
- Bordure bleue si non lue
- Fond coloré selon priorité

### **4. Actions**
- ✓ Marquer comme lue
- 🗑️ Supprimer
- Clic sur la notification → Navigation vers l'action

### **5. Toast**
- Apparaît en haut à droite
- Icône selon priorité
- Titre de la notification
- Disparaît après 4 secondes

---

## 🐛 Dépannage

### **Problème : Badge ne s'affiche pas**

**Vérifications :**
1. Backend démarré ? → `curl http://localhost:3000/health`
2. Dashboard démarré ? → Ouvrir `http://localhost:3001`
3. Socket.IO connecté ? → Ouvrir la console du navigateur
   - Devrait voir : `✅ Socket.IO connecté`
   - Devrait voir : `🔐 Authentification envoyée pour user: X`

### **Problème : Pas de toast**

**Vérifications :**
1. Ouvrir la console du navigateur (F12)
2. Chercher : `🔔 Nouvelle notification reçue`
3. Si absent → Socket.IO non connecté

### **Problème : Notification non enregistrée en DB**

**Vérifications :**
1. Logs backend → Chercher : `✅ Notification créée pour user X`
2. Vérifier la table : 
   ```bash
   sqlite3 database.sqlite "SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;"
   ```

---

## 📝 Logs à surveiller

### **Backend (Terminal 1):**
```
✅ Socket.IO initialisé
🔌 Socket.IO ready for real-time notifications
🔔 Notification créée pour user 1: Nouvelle demande d'intervention
🔔 Notification envoyée en temps réel à user 1
✅ Notification envoyée aux admins
```

### **Dashboard (Console navigateur):**
```
🔌 Connexion Socket.IO à http://localhost:3000
✅ Socket.IO connecté: abc123
🔐 Authentification envoyée pour user: 1
🔔 Nouvelle notification reçue: {...}
```

---

## ✅ Checklist de test

- [ ] Backend démarré
- [ ] Dashboard démarré
- [ ] Connexion au dashboard avec compte admin
- [ ] Icône de cloche visible
- [ ] Test 1 : Créer intervention → Badge apparaît
- [ ] Test 2 : Cliquer sur cloche → Dropdown s'ouvre
- [ ] Test 3 : Notification visible avec détails
- [ ] Test 4 : Marquer comme lue → Devient grise
- [ ] Test 5 : Toast apparaît pour nouvelle notification
- [ ] Test 6 : Créer réclamation → Badge s'incrémente
- [ ] Test 7 : Créer commande → Badge s'incrémente
- [ ] Test 8 : Tout marquer comme lu → Badge disparaît

---

**Le système est prêt ! Bon test ! 🎉**
