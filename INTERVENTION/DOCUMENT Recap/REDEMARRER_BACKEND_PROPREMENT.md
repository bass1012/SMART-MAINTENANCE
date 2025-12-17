# 🔄 Redémarrer le Backend Proprement

## ⚠️ Problème Actuel

Le champ `rejection_reason` a été ajouté au modèle Quote.js, mais Sequelize ne l'inclut pas dans les requêtes SELECT car le backend n'a pas été redémarré correctement.

**Requête SQL actuelle (incorrecte) :**
```sql
SELECT `Quote`.`id`, `Quote`.`reference`, ..., `Quote`.`notes`, `Quote`.`termsAndConditions`, ...
-- ❌ Pas de `rejection_reason` !
```

**Requête SQL attendue (correcte) :**
```sql
SELECT `Quote`.`id`, `Quote`.`reference`, ..., `Quote`.`notes`, `Quote`.`termsAndConditions`, `Quote`.`rejection_reason`, ...
-- ✅ Avec `rejection_reason` !
```

---

## ✅ Solution : Redémarrage Complet

### **1. Arrêter le Backend**

**Dans le terminal où le backend tourne :**
```
Ctrl+C
```

Ou **forcer l'arrêt :**
```bash
lsof -ti:3000 | xargs kill -9
```

### **2. Vider le Cache Node.js (Important !)**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
rm -rf node_modules/.cache
```

### **3. Redémarrer le Backend**

```bash
npm start
```

### **4. Vérifier les Logs**

**Chercher dans les logs :**
```
Executing (default): SELECT ... `Quote`.`rejection_reason` ...
```

Si tu vois `rejection_reason` dans la requête SQL → ✅ C'est bon !

---

## 🧪 Test Complet

### **1. Tester l'API Directement**

**Récupérer un devis :**
```bash
curl -X GET http://localhost:3000/api/quotes/5 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Vérifier la réponse :**
```json
{
  "success": true,
  "data": {
    "id": 5,
    "reference": "DEV-005",
    "status": "rejected",
    "rejection_reason": "Prix trop élevé",  // ← Doit être présent !
    "notes": "...",
    ...
  }
}
```

### **2. Refuser un Devis avec une Raison**

```bash
curl -X POST http://localhost:3000/api/customer/quotes/5/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_CLIENT_TOKEN" \
  -d '{"reason": "Prix trop élevé pour mon budget"}'
```

**Vérifier la réponse :**
```json
{
  "success": true,
  "message": "Devis refusé",
  "data": {
    "id": 5,
    "status": "rejected",
    "rejection_reason": "Prix trop élevé pour mon budget"  // ✅
  }
}
```

### **3. Vérifier dans la Base de Données**

```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite \
  "SELECT id, reference, status, rejection_reason FROM quotes WHERE id = 5;"
```

**Résultat attendu :**
```
5|DEV-005|rejected|Prix trop élevé pour mon budget
```

### **4. Vérifier dans le Dashboard Web**

1. Rafraîchis la page (Cmd+R)
2. Va dans "Devis" → Ouvre le devis #5
3. Vérifie que "Raison du refus: Prix trop élevé pour mon budget" s'affiche ✅

### **5. Vérifier dans Flutter Mobile**

1. Hot restart : `R`
2. Va dans "Devis et Contrat" → "Devis"
3. Ouvre le devis refusé
4. Vérifie que la raison s'affiche ✅

---

## 🔍 Debugging

### **Si `rejection_reason` n'apparaît toujours pas dans les requêtes SQL :**

**1. Vérifier que le modèle est correct :**
```bash
cat /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/src/models/Quote.js | grep rejection_reason
```

**Résultat attendu :**
```javascript
rejection_reason: { type: DataTypes.TEXT, field: 'rejection_reason' }
```

**2. Vérifier que la colonne existe :**
```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite \
  "PRAGMA table_info(quotes);" | grep rejection
```

**Résultat attendu :**
```
15|rejection_reason|TEXT|0||0
```

**3. Forcer le redémarrage complet :**
```bash
# Arrêter
lsof -ti:3000 | xargs kill -9

# Vider le cache
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
rm -rf node_modules/.cache

# Redémarrer
npm start
```

**4. Vérifier les logs au démarrage :**
```
Sequelize models loaded successfully
✓ Database connected
```

---

## 📝 Checklist de Redémarrage

- [ ] Arrêter le backend (Ctrl+C ou kill)
- [ ] Vider le cache Node.js (`rm -rf node_modules/.cache`)
- [ ] Redémarrer le backend (`npm start`)
- [ ] Vérifier les logs SQL (chercher `rejection_reason`)
- [ ] Tester l'API avec curl
- [ ] Vérifier dans la base de données
- [ ] Tester dans le dashboard web
- [ ] Tester dans Flutter mobile

---

## 🎯 Commandes Rapides

**Redémarrage complet :**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9
rm -rf node_modules/.cache
npm start
```

**Test API :**
```bash
# Récupérer un devis
curl http://localhost:3000/api/quotes/5 \
  -H "Authorization: Bearer TOKEN"

# Refuser un devis
curl -X POST http://localhost:3000/api/customer/quotes/5/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"reason": "Test raison"}'
```

**Vérifier la base :**
```bash
sqlite3 /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/database.sqlite \
  "SELECT id, reference, status, rejection_reason FROM quotes WHERE status = 'rejected';"
```

---

## ⚠️ Important

**Pourquoi le redémarrage est nécessaire ?**

1. **Sequelize charge les modèles au démarrage** : Les modifications du modèle ne sont pas prises en compte à chaud
2. **Cache Node.js** : Node.js peut mettre en cache les modules require()
3. **Requêtes SQL générées** : Sequelize génère les requêtes SQL basées sur les modèles chargés en mémoire

**Solution :** Toujours redémarrer le backend après avoir modifié un modèle Sequelize.

---

**Redémarre le backend maintenant et teste !** 🚀✅
