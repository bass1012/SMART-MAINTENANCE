# 🧪 Test Socket.IO en Temps Réel

## 🎯 Objectif
Vérifier que Socket.IO envoie bien les notifications en temps réel au dashboard web.

## 📋 Prérequis
- ✅ Backend démarré sur port 3000
- ✅ Dashboard démarré sur port 3001

## 🚀 Test Méthode 1 : Page de test HTML

### Étape 1 : Ouvrir la page de test
La page `test-socketio.html` devrait s'être ouverte automatiquement.
Sinon : Double-cliquer sur `/Users/bassoued/Documents/MAINTENANCE/test-socketio.html`

### Étape 2 : Se connecter
1. Vérifier que "User ID" = 6 (l'admin)
2. Cliquer sur **"Se connecter"**
3. Vérifier dans les logs :
   ```
   ✅ Connecté! Socket ID: xxx
   🔐 Authentification user 6...
   ```

### Étape 3 : Déclencher une notification
Dans un terminal :
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node trigger-test-notification.js
```

### Étape 4 : Vérifier
- ✅ Dans la page de test, vous devriez voir :
  ```
  🔔 NOTIFICATION REÇUE: 🧪 Test de notification en temps réel
  ```
- ✅ La notification apparaît dans la section "Dernière notification"

---

## 🚀 Test Méthode 2 : Dashboard Web

### Étape 1 : Ouvrir le dashboard
1. Ouvrir : `http://localhost:3001`
2. Se connecter avec `admin@mct-maintenance.com`

### Étape 2 : Ouvrir la console
1. Appuyer sur **F12**
2. Aller dans l'onglet **Console**
3. Vérifier les logs Socket.IO :
   ```
   🔌 Connexion Socket.IO à http://localhost:3000
   ✅ Socket.IO connecté: abc123
   🔐 Authentification envoyée pour user: 6
   ```

### Étape 3 : Créer une intervention depuis le mobile
1. Ouvrir l'app mobile
2. Se connecter avec un compte client
3. Créer une demande d'intervention

### Étape 4 : Vérifier le dashboard
- ✅ Badge apparaît sur la cloche 🔔
- ✅ Toast "Nouvelle demande d'intervention"
- ✅ Dans la console : `🔔 Nouvelle notification reçue`

---

## 🐛 Si ça ne marche pas

### Problème 1 : "Erreur connexion" dans test-socketio.html

**Cause** : Backend non démarré ou CORS bloqué

**Solution** :
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
lsof -ti:3000 | xargs kill -9
npm start
```

### Problème 2 : Pas de log "Authentification" dans la console backend

**Cause** : Le dashboard n'envoie pas l'événement `authenticate`

**Solution** : Vérifier que `socketService.connect(currentUser.id)` est bien appelé dans NotificationBell.tsx

### Problème 3 : Notification créée en DB mais pas reçue en temps réel

**Cause** : L'utilisateur n'a pas rejoint la room `user:6`

**Solution** : Vérifier les logs backend :
```bash
# Devrait afficher :
✅ Utilisateur 6 authentifié sur socket xxx
✅ Utilisateur 6 a rejoint la room role:admin
```

---

## 📊 Logs à surveiller

### Backend (Terminal) :
```
✅ Socket.IO initialisé
🔌 Client connecté: abc123
✅ Utilisateur 6 authentifié sur socket abc123
✅ Utilisateur 6 a rejoint la room role:admin
📬 Notification créée pour user 6: Nouvelle demande d'intervention
🔔 Notification envoyée en temps réel à user 6
```

### Dashboard (Console F12) :
```
🔌 Connexion Socket.IO à http://localhost:3000
✅ Socket.IO connecté: abc123
🔐 Authentification envoyée pour user: 6
🔔 Nouvelle notification reçue: {...}
```

---

## ✅ Checklist

- [ ] Backend démarré
- [ ] Page test-socketio.html ouverte
- [ ] Clic sur "Se connecter" dans la page de test
- [ ] Logs "✅ Connecté" visible
- [ ] Lancer `node trigger-test-notification.js`
- [ ] Notification reçue dans la page de test
- [ ] Dashboard web ouvert et connecté
- [ ] Console F12 ouverte
- [ ] Logs Socket.IO visibles
- [ ] Créer intervention depuis mobile
- [ ] Badge + Toast apparaissent

---

**Si tous les tests passent, le système fonctionne parfaitement ! 🎉**
