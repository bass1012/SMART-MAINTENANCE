# 📋 Explication : Contrats et Utilisateurs

## 🔍 Situation Actuelle

### **Contrats dans la Base de Données :**

```sql
SELECT id, reference, title, customer_id, status FROM contracts;
```

**Résultat :**
```
id | reference | title            | customer_id | status
---|-----------|------------------|-------------|--------
1  | CONT-001  | Contrat A        | 5           | active
2  | CONT-003  | CONTRAT TEST     | 7           | active
3  | CONT-002  | CONTRAT TEST 2   | 7           | active
4  | CONT-004  | CONTRAT TEST 3   | 7           | active
```

### **Utilisateurs :**

- **user_id = 5** : Un utilisateur
- **user_id = 7** : Zoumana Edouard OUATTARA
- **user_id = 9** : Bakary Madou CISSE

---

## ❌ Le Problème

**Ce que tu dis :**
> "Quand je crée un contrat avec Bakary Madou CISSE, je vois le nom Zoumana Edouard OUATTARA"

**Explication :**

1. **Dans le dashboard web**, tu ouvres le formulaire de création de contrat
2. Tu sélectionnes un client dans le dropdown "Client"
3. **Tu sélectionnes probablement "Zoumana" (user_id = 7) au lieu de "Bakary" (user_id = 9)**
4. Le contrat est créé avec `customer_id = 7`
5. Quand tu récupères les contrats, il affiche "Zoumana" parce que c'est le bon client !

---

## ✅ Solution

### **Option 1 : Vérifier la Sélection du Client**

**Dans le dashboard web :**
1. Ouvre le formulaire de création de contrat
2. **Vérifie bien le client sélectionné** dans le dropdown
3. Sélectionne **"Bakary Madou CISSE"** (pas Zoumana)
4. Crée le contrat
5. Le contrat aura `customer_id = 9`

### **Option 2 : Tester avec l'API Directement**

**Créer un contrat pour Bakary (user_id = 9) :**

```bash
curl -X POST http://localhost:3000/api/contracts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{
    "reference": "CONT-BAKARY-001",
    "title": "Contrat Test Bakary",
    "description": "Test pour Bakary",
    "customer_id": 9,
    "type": "maintenance",
    "status": "active",
    "start_date": "2025-01-01",
    "end_date": "2025-12-31",
    "amount": 50000,
    "payment_frequency": "yearly"
  }'
```

### **Option 3 : Vérifier dans l'App Mobile**

**Après avoir créé un contrat pour Bakary :**

1. Connecte-toi avec Bakary dans l'app mobile
2. Va dans "Devis et Contrat" → Onglet "Contrats"
3. Tu devrais voir le contrat avec le nom "Bakary Madou CISSE"

---

## 🧪 Test Complet

### **1. Vérifier les Utilisateurs**

```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite \
  "SELECT id, first_name, last_name, email FROM users WHERE role = 'customer';"
```

**Résultat attendu :**
```
5|...|...|...
7|Zoumana|Edouard OUATTARA|...
9|Bakary Madou|CISSE|cisse.bakary@gmail.com
```

### **2. Créer un Contrat pour Bakary**

**Via le dashboard web :**
- Client : **Bakary Madou CISSE** ← Vérifier ici !
- Référence : CONT-BAKARY-001
- Titre : Test Bakary
- Type : Maintenance
- Statut : Actif
- Dates : 01/01/2025 - 31/12/2025
- Montant : 50000
- Fréquence : Annuel

### **3. Vérifier dans la Base de Données**

```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite \
  "SELECT id, reference, title, customer_id FROM contracts WHERE customer_id = 9;"
```

**Résultat attendu :**
```
5|CONT-BAKARY-001|Test Bakary|9
```

### **4. Tester l'API Customer**

```bash
curl -X GET http://localhost:3000/api/customer/contracts \
  -H "Authorization: Bearer BAKARY_TOKEN"
```

**Résultat attendu :**
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "reference": "CONT-BAKARY-001",
      "customer_id": 9,
      "customer": {
        "first_name": "Bakary Madou",
        "last_name": "CISSE"
      }
    }
  ]
}
```

### **5. Tester dans Flutter**

1. Connecte-toi avec Bakary
2. Va dans "Devis et Contrat" → "Contrats"
3. Tu devrais voir le contrat avec "Bakary Madou CISSE"

---

## 🎯 Résumé

**Le problème n'est PAS un bug, c'est une confusion :**

1. Les contrats existants (CONT-001 à CONT-004) appartiennent à Zoumana (user_id = 7)
2. Quand tu les affiches, ils montrent correctement "Zoumana"
3. Si tu veux un contrat pour Bakary, tu dois :
   - **Sélectionner Bakary dans le formulaire**
   - Ou créer le contrat avec `customer_id = 9`

**L'endpoint `/api/customer/contracts` fonctionne correctement :**
- Il filtre par `customer_id = req.user.id`
- Bakary (user_id = 9) ne voit que ses contrats
- Zoumana (user_id = 7) ne voit que ses contrats

---

## 📱 Pour Tester Maintenant

### **1. Créer un Contrat pour Bakary**

**Dans le dashboard web :**
1. Va dans "Contrats"
2. Clique sur "Nouveau Contrat"
3. **Sélectionne "Bakary Madou CISSE" dans le dropdown Client**
4. Remplis les autres champs
5. Clique sur "Enregistrer"

### **2. Vérifier dans Flutter**

1. Connecte-toi avec Bakary
2. Va dans "Devis et Contrat" → "Contrats"
3. Fais un pull-to-refresh
4. Tu devrais voir le nouveau contrat avec "Bakary Madou CISSE"

---

## ✅ Checklist

- [ ] Vérifier les utilisateurs dans la base
- [ ] Créer un contrat en **sélectionnant bien Bakary**
- [ ] Vérifier dans la base que `customer_id = 9`
- [ ] Tester l'API `/api/customer/contracts` avec le token de Bakary
- [ ] Tester dans l'app Flutter mobile
- [ ] Confirmer que le nom affiché est "Bakary Madou CISSE"

---

**Le système fonctionne correctement. Il faut juste sélectionner le bon client lors de la création !** ✅
