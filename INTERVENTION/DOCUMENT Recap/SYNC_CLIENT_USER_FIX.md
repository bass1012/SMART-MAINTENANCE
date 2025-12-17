# 🔄 Synchronisation Client-Utilisateur - Dashboard Web

## ❌ Problème Identifié

Quand vous modifiez les informations d'un client dans l'onglet **"Utilisateurs"**, les changements **ne s'affichent pas** dans l'onglet **"Clients"**.

### Cause Racine

Le système utilise **deux tables séparées** :

1. **`users`** - Informations de connexion (email, phone, role, status)
2. **`customer_profiles`** - Informations client (first_name, last_name, address, etc.)

**Problème:** Les deux tables ont des colonnes `first_name` et `last_name` dupliquées !

```
Table users:
├─ id
├─ email
├─ phone
├─ first_name  ← Modifié dans "Utilisateurs"
├─ last_name   ← Modifié dans "Utilisateurs"
└─ role

Table customer_profiles:
├─ id
├─ user_id (FK → users.id)
├─ first_name  ← PAS mis à jour automatiquement ❌
├─ last_name   ← PAS mis à jour automatiquement ❌
└─ company_name
```

### Flux du Problème

```
Onglet "Utilisateurs"
    ↓
Modifier first_name/last_name
    ↓
PUT /api/users/:id
    ↓
✅ Table users mise à jour
❌ Table customer_profiles PAS mise à jour
    ↓
Onglet "Clients"
    ↓
GET /api/customers
    ↓
Lit depuis customer_profiles.first_name
    ↓
❌ Affiche les anciennes données
```

---

## ✅ Solution Appliquée

### **Synchronisation Automatique**

Quand un utilisateur de type "customer" est modifié, le système met à jour **automatiquement** le `CustomerProfile` correspondant.

**Fichier modifié:** `/src/controllers/user/userController.js`

```javascript
// PUT /api/users/:id
exports.updateUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    
    // Mise à jour des champs utilisateur
    const allowed = ['email', 'phone', 'role', 'status', 'preferences', 'first_name', 'last_name', 'profile_image'];
    for (const key of allowed) {
      if (req.body[key] !== undefined) user[key] = req.body[key];
    }
    
    // Gérer le mot de passe
    if (req.body.password) {
      user.password_hash = req.body.password;
    }
    
    await user.save();
    
    // ✅ SYNCHRONISER avec CustomerProfile si l'utilisateur est un client
    if (user.role === 'customer') {
      const { CustomerProfile } = require('../../models');
      const customerProfile = await CustomerProfile.findOne({ where: { user_id: user.id } });
      
      if (customerProfile) {
        // Mettre à jour first_name et last_name dans customer_profiles
        if (req.body.first_name !== undefined) {
          customerProfile.first_name = req.body.first_name;
        }
        if (req.body.last_name !== undefined) {
          customerProfile.last_name = req.body.last_name;
        }
        await customerProfile.save();
        console.log(`✅ CustomerProfile synchronisé pour user_id: ${user.id}`);
      }
    }
    
    return res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};
```

---

## 🔄 Nouveau Flux

```
Onglet "Utilisateurs"
    ↓
Modifier first_name/last_name
    ↓
PUT /api/users/:id
    ↓
✅ Table users mise à jour
    ↓
Vérifier si role === 'customer'
    ↓
✅ Table customer_profiles mise à jour automatiquement
    ↓
Onglet "Clients"
    ↓
GET /api/customers
    ↓
Lit depuis customer_profiles.first_name
    ↓
✅ Affiche les nouvelles données
```

---

## 📊 Comparaison Avant/Après

### **Avant**

| Action | Table users | Table customer_profiles | Résultat |
|--------|-------------|-------------------------|----------|
| Modifier nom dans "Utilisateurs" | ✅ Mis à jour | ❌ Pas mis à jour | ❌ Incohérence |
| Afficher dans "Clients" | - | ❌ Anciennes données | ❌ Erreur |

### **Après**

| Action | Table users | Table customer_profiles | Résultat |
|--------|-------------|-------------------------|----------|
| Modifier nom dans "Utilisateurs" | ✅ Mis à jour | ✅ Mis à jour automatiquement | ✅ Cohérence |
| Afficher dans "Clients" | - | ✅ Nouvelles données | ✅ Correct |

---

## 🧪 Tests

### **Test 1 : Modifier un Client depuis "Utilisateurs"**

1. **Ouvrir le dashboard web**
2. **Onglet "Utilisateurs"**
3. Trouver un utilisateur avec role "customer"
4. Cliquer sur "Modifier"
5. Changer `first_name` : "Jean" → "Pierre"
6. Changer `last_name` : "Dupont" → "Martin"
7. Sauvegarder

**Vérification Backend:**
```
✅ Table users mise à jour
✅ Table customer_profiles mise à jour
✅ Log: "CustomerProfile synchronisé pour user_id: X"
```

8. **Onglet "Clients"**
9. Chercher le client
10. ✅ Nom affiché : "Pierre Martin"

---

### **Test 2 : Modifier Email/Phone**

1. Onglet "Utilisateurs"
2. Modifier email et phone d'un client
3. Sauvegarder
4. Onglet "Clients"
5. ✅ Email et phone mis à jour (car lus depuis `user.email` et `user.phone`)

---

### **Test 3 : Utilisateur Non-Client**

1. Modifier un utilisateur avec role "admin" ou "technician"
2. Sauvegarder
3. ✅ Pas de synchronisation avec customer_profiles (normal)
4. ✅ Pas d'erreur

---

## 📝 Fichiers Modifiés

### **Backend**

**Fichier:** `/src/controllers/user/userController.js`

**Changements:**
- ✅ Ajout de la synchronisation automatique avec `CustomerProfile`
- ✅ Vérification du role === 'customer'
- ✅ Mise à jour de `first_name` et `last_name` dans `customer_profiles`
- ✅ Log de confirmation

---

## 🔍 Détails Techniques

### **Champs Synchronisés**

| Champ | Table Source | Table Cible | Condition |
|-------|--------------|-------------|-----------|
| `first_name` | users | customer_profiles | role === 'customer' |
| `last_name` | users | customer_profiles | role === 'customer' |

### **Champs NON Synchronisés**

Ces champs restent indépendants :
- `email` - Uniquement dans `users`
- `phone` - Uniquement dans `users`
- `company_name` - Uniquement dans `customer_profiles`
- `address` - Uniquement dans `customer_profiles`
- `city` - Uniquement dans `customer_profiles`

### **Requête SQL Générée**

```sql
-- 1. Mise à jour de users
UPDATE users 
SET first_name = 'Pierre', last_name = 'Martin', updated_at = NOW()
WHERE id = 123;

-- 2. Synchronisation automatique
UPDATE customer_profiles 
SET first_name = 'Pierre', last_name = 'Martin', updated_at = NOW()
WHERE user_id = 123;
```

---

## 🚀 Déploiement

### **Étapes**

1. **Redémarrer le serveur API**
   ```bash
   cd mct-maintenance-api
   npm start
   ```

2. **Tester la modification**
   - Dashboard → Utilisateurs → Modifier un client
   - Vérifier dans Clients

3. **Vérifier les logs**
   ```
   ✅ CustomerProfile synchronisé pour user_id: 123
   ```

---

## ⚠️ Points Importants

### **1. Duplication de Données**

Le système a une **duplication intentionnelle** de `first_name` et `last_name` dans deux tables :
- `users.first_name` / `users.last_name`
- `customer_profiles.first_name` / `customer_profiles.last_name`

**Pourquoi ?**
- `users` : Informations de connexion et authentification
- `customer_profiles` : Informations métier du client

**Solution actuelle:** Synchronisation automatique lors de la modification

### **2. Source de Vérité**

Après cette modification, la **source de vérité** pour les noms est :
- **Table `users`** - Modifiée en premier
- **Table `customer_profiles`** - Synchronisée automatiquement

### **3. Performances**

La synchronisation ajoute une requête SQL supplémentaire, mais :
- ✅ Exécutée uniquement pour les clients (role === 'customer')
- ✅ Exécutée uniquement si first_name ou last_name est modifié
- ✅ Impact minimal sur les performances

---

## 🔮 Améliorations Futures

### **Option 1 : Supprimer la Duplication**

Modifier l'API `/customers` pour lire directement depuis `users` :

```javascript
const customers = rows.map(profile => {
  const user = profile.user || {};
  return {
    id: profile.id,
    // ✅ Lire depuis user au lieu de profile
    first_name: user.first_name || profile.first_name,
    last_name: user.last_name || profile.last_name,
    email: user.email,
    phone: user.phone,
    company: profile.company_name,
    // ...
  };
});
```

### **Option 2 : Trigger Base de Données**

Créer un trigger SQL pour synchroniser automatiquement :

```sql
CREATE TRIGGER sync_customer_profile_names
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
  IF NEW.role = 'customer' THEN
    UPDATE customer_profiles
    SET first_name = NEW.first_name,
        last_name = NEW.last_name,
        updated_at = NOW()
    WHERE user_id = NEW.id;
  END IF;
END;
```

### **Option 3 : Vue SQL**

Créer une vue qui joint automatiquement les deux tables :

```sql
CREATE VIEW customers_view AS
SELECT 
  cp.id,
  u.first_name,
  u.last_name,
  u.email,
  u.phone,
  cp.company_name,
  cp.city,
  cp.commune
FROM customer_profiles cp
JOIN users u ON cp.user_id = u.id;
```

---

## ✅ Résultat Final

Les modifications dans l'onglet **"Utilisateurs"** sont maintenant **automatiquement synchronisées** avec l'onglet **"Clients"**.

**Workflow complet:**

```
Dashboard Web
    ↓
Utilisateurs → Modifier un client
    ↓
✅ Table users mise à jour
✅ Table customer_profiles synchronisée
    ↓
Clients → Affichage
    ↓
✅ Données à jour affichées
```

**Le problème est résolu ! Les deux onglets affichent maintenant les mêmes informations.** 🎉✨

---

## 📞 Support

Si le problème persiste :

1. Vérifier les logs du serveur API
2. Vérifier que le role de l'utilisateur est bien "customer"
3. Vérifier que le `user_id` existe dans `customer_profiles`
4. Tester avec un nouveau client
