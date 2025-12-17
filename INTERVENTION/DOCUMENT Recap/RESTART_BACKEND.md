# 🔄 Comment Redémarrer le Backend Correctement

## ❌ Problème

Après avoir modifié le code backend, les changements ne sont pas pris en compte car :
1. Node.js met en cache les modules `require()`
2. Le serveur continue d'utiliser l'ancienne version du code
3. Un simple Ctrl+C peut ne pas tuer complètement le processus

## ✅ Solution : Redémarrage Complet

### **Méthode 1 : Tuer le processus sur le port 3000**

```bash
# 1. Trouver et tuer le processus sur le port 3000
lsof -ti:3000 | xargs kill -9

# 2. Redémarrer le serveur
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

### **Méthode 2 : Ctrl+C puis redémarrer**

```bash
# 1. Dans le terminal du serveur, appuyer sur Ctrl+C
^C

# 2. Attendre le message "SIGINT received, shutting down gracefully"

# 3. Redémarrer
npm start
```

### **Méthode 3 : Utiliser nodemon (recommandé pour le développement)**

```bash
# 1. Installer nodemon globalement
npm install -g nodemon

# 2. Lancer avec nodemon (redémarre automatiquement)
nodemon src/app.js
```

---

## 🔍 Vérifier que le Serveur Utilise le Nouveau Code

### **1. Vérifier les logs au démarrage**

```
✅ Server is running on port 3000
✅ Database connected successfully
```

### **2. Tester l'endpoint problématique**

```bash
curl -X GET http://localhost:3000/api/customer/dashboard/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Vérifier les logs SQL :**
```sql
-- ✅ BON (après correction)
SELECT count(*) FROM `contracts` WHERE `customer_id` = 9;

-- ❌ MAUVAIS (ancien code)
SELECT count(*) FROM `contracts` WHERE `customerId` = 9;
```

---

## 🐛 Erreur Persistante : "no such column: Contract.customerId"

### **Cause**

Le serveur utilise encore l'ancien code malgré le redémarrage.

### **Solutions**

#### **Solution 1 : Vider le cache Node.js**

```bash
# 1. Arrêter le serveur
^C

# 2. Supprimer le cache npm
rm -rf node_modules/.cache

# 3. Redémarrer
npm start
```

#### **Solution 2 : Forcer le rechargement**

```bash
# 1. Tuer tous les processus Node
killall node

# 2. Vérifier qu'aucun processus n'écoute sur le port 3000
lsof -i:3000
# (ne doit rien retourner)

# 3. Redémarrer
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

#### **Solution 3 : Redémarrer avec --no-cache**

```bash
node --no-warnings src/app.js
```

---

## 📱 Erreur Flutter : "Erreur lors de chargement: Exception: Erreur inconnu"

### **Cause**

L'app Flutter reçoit une erreur 500 du backend car :
1. Le backend utilise encore l'ancien code
2. La requête SQL échoue avec "no such column"

### **Solution**

1. **Redémarrer le backend correctement** (voir ci-dessus)
2. **Vérifier les logs backend** pour confirmer que la requête SQL est correcte
3. **Relancer l'app Flutter** (hot restart avec `R`)

```bash
# Dans le terminal Flutter
R  # Hot restart
```

---

## 🧪 Test Complet

### **1. Arrêter le Backend**

```bash
# Méthode 1 : Ctrl+C dans le terminal
^C

# Méthode 2 : Tuer le processus
lsof -ti:3000 | xargs kill -9
```

### **2. Vérifier que le Port est Libre**

```bash
lsof -i:3000
# Ne doit rien retourner
```

### **3. Redémarrer le Backend**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

### **4. Vérifier les Logs**

**Logs attendus (sans erreur) :**
```
✅ Server is running on port 3000
✅ Database connected successfully

[2025-10-23T10:XX:XX.XXXZ] GET /api/customer/dashboard/stats
📊 Récupération des statistiques pour user_id: 9
✅ Customer profile ID: 7

Executing: SELECT count(*) FROM `contracts` WHERE `customer_id` = 9;  ✅
Executing: SELECT count(*) FROM `contracts` WHERE `customer_id` = 9 AND `status` = 'active';  ✅

📊 Statistiques calculées: { ... }
GET /api/customer/dashboard/stats 200 ✅
```

**Erreurs qui ne doivent PLUS apparaître :**
```
❌ SQLITE_ERROR: no such column: Contract.customerId
❌ Error getting dashboard stats: Error
```

### **5. Tester l'App Flutter**

```bash
# Hot restart
R

# Vérifier dans les logs Flutter
flutter: 🟢 API Response (200): {"success":true,"data":{...}}  ✅
```

---

## 💡 Astuce : Utiliser nodemon pour le Développement

**Avantages :**
- Redémarre automatiquement le serveur à chaque modification
- Plus besoin de redémarrer manuellement
- Gain de temps en développement

**Installation :**
```bash
npm install -g nodemon
```

**Utilisation :**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
nodemon src/app.js
```

**Ou modifier package.json :**
```json
{
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js"  // ✅ Ajouter cette ligne
  }
}
```

**Puis lancer :**
```bash
npm run dev
```

---

## ✅ Checklist de Redémarrage

- [ ] Arrêter le serveur (Ctrl+C ou kill)
- [ ] Vérifier que le port 3000 est libre (`lsof -i:3000`)
- [ ] Redémarrer le serveur (`npm start`)
- [ ] Vérifier les logs de démarrage (pas d'erreur)
- [ ] Tester l'endpoint (`/api/customer/dashboard/stats`)
- [ ] Vérifier les logs SQL (utilise `customer_id` et non `customerId`)
- [ ] Hot restart Flutter (`R`)
- [ ] Vérifier que l'app charge sans erreur

---

## 🎯 Résumé

**Problème :** Node.js met en cache les modules, les modifications ne sont pas prises en compte.

**Solution :** Redémarrer complètement le serveur en tuant le processus.

**Commande rapide :**
```bash
lsof -ti:3000 | xargs kill -9 && npm start
```

**Pour le développement :** Utiliser `nodemon` pour redémarrage automatique.
