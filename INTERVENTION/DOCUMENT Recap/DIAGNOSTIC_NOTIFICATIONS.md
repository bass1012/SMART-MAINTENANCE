# 🔍 Diagnostic - Notifications ne s'affichent pas

## ✅ État actuel vérifié :

1. ✅ **Backend démarré** avec Socket.IO
2. ✅ **Table notifications** existe en base
3. ✅ **Code de notification** présent dans interventionController.js
4. ✅ **Admin existe** en base (ID: 6, email: admin@mct-maintenance.com)

## 🎯 Problème identifié :

**Les notifications sont envoyées aux admins uniquement.**

Pour recevoir les notifications sur le dashboard web, vous devez:
1. Être connecté avec un **compte admin**
2. Socket.IO doit être **connecté et authentifié**

## ✅ Solution :

### **Étape 1 : Se connecter au dashboard avec le compte admin**

1. Ouvrir : `http://localhost:3001`
2. Se connecter avec :
   - **Email** : `admin@mct-maintenance.com`
   - **Password** : (votre mot de passe)

### **Étape 2 : Vérifier la connexion Socket.IO**

1. Ouvrir la **Console du navigateur** (F12)
2. Chercher ces messages :
   ```
   🔌 Connexion Socket.IO à http://localhost:3000
   ✅ Socket.IO connecté: abc123
   🔐 Authentification envoyée pour user: 6
   ```

3. Si vous ne voyez PAS ces messages :
   - Rafraîchir la page (F5)
   - Vérifier que le backend tourne sur port 3000

### **Étape 3 : Créer une intervention depuis le mobile**

1. Ouvrir l'app mobile
2. Se connecter avec un **compte client** (pas admin)
3. Créer une demande d'intervention
4. **Regarder le dashboard web** → Badge devrait apparaître !

---

## 🧪 Test manuel rapide :

### **Test 1 : Vérifier que le backend reçoit la requête**

Quand vous créez une intervention depuis le mobile, regardez les logs du backend.

Vous devriez voir :
```
✅ Notification créée pour user 6: Nouvelle demande d'intervention
🔔 Notification envoyée en temps réel à user 6
✅ Notification envoyée aux admins
```

### **Test 2 : Vérifier en base de données**

Après avoir créé une intervention, exécutez :

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
sqlite3 database.sqlite "SELECT id, user_id, type, title, created_at FROM notifications ORDER BY created_at DESC LIMIT 3;"
```

Vous devriez voir une notification avec :
- `user_id` = 6 (l'admin)
- `type` = intervention_request

### **Test 3 : Vérifier Socket.IO sur le dashboard**

Dans la console du navigateur, tapez :
```javascript
localStorage.getItem('token')
```

Si ça retourne `null`, vous n'êtes pas connecté !

---

## 🐛 Si ça ne marche toujours pas :

### **Problème A : Pas de logs dans le backend**

**Cause** : Le code de notification n'est pas exécuté

**Solution** :
```bash
# Redémarrer le backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9
npm start
```

### **Problème B : Socket.IO ne se connecte pas**

**Cause** : Erreur CORS ou problème de connexion

**Solution** : Vérifier la console du navigateur pour les erreurs

### **Problème C : Badge n'apparaît pas**

**Cause** : Vous n'êtes pas connecté avec un compte admin

**Solution** : Se déconnecter et se reconnecter avec `admin@mct-maintenance.com`

---

## 📋 Checklist finale :

- [ ] Backend démarré (port 3000)
- [ ] Dashboard démarré (port 3001)
- [ ] Connecté au dashboard avec **admin@mct-maintenance.com**
- [ ] Console du navigateur ouverte (F12)
- [ ] Socket.IO connecté (voir logs console)
- [ ] Créer intervention depuis mobile
- [ ] Badge apparaît sur la cloche 🔔
- [ ] Toast "Nouvelle demande d'intervention"
- [ ] Clic sur cloche → Notification visible

---

**Si tous les points sont cochés et que ça ne marche toujours pas, partagez les logs de la console du navigateur !**
