# 🧪 TEST DES NOTIFICATIONS POUR LES DEVIS

## 📋 INFORMATIONS IMPORTANTES

### Admin trouvé dans la DB:
- **ID**: 6
- **Email**: admin@mct-maintenance.com
- **Status**: active

## 🔍 ÉTAPES DE TEST

### 1️⃣ OUVRIR LE DASHBOARD WEB (Admin)

1. Ouvrez le dashboard: `http://localhost:3001`
2. Connectez-vous avec: `admin@mct-maintenance.com`
3. **Ouvrez la console du navigateur** (F12 → Console)

### 2️⃣ VÉRIFIER LA CONNEXION SOCKET.IO

**Dans la console du navigateur, vous devriez voir :**
```
🔌 Tentative de connexion Socket.IO avec user: 6
🔌 socketService.connect() appelé avec userId: 6
✅ Socket.IO connecté: [socket-id]
🔐 Authentification envoyée pour user: 6
```

**Si vous NE voyez PAS ces logs :**
- ❌ Socket.IO n'est pas connecté
- → Le NotificationBell ne charge pas correctement

### 3️⃣ VÉRIFIER LES LOGS BACKEND

**Dans le terminal du backend (`npm start`), vous devriez voir :**
```
🔌 Client connecté: [socket-id]
✅ Utilisateur 6 authentifié sur socket [socket-id]
✅ Utilisateur 6 a rejoint la room role:admin
```

**Si vous NE voyez PAS ces logs :**
- ❌ Le client web ne s'est pas connecté au backend
- → Problème CORS ou configuration Socket.IO

### 4️⃣ ACCEPTER UN DEVIS DEPUIS LE MOBILE

1. Ouvrez l'app mobile
2. Allez dans "Devis"
3. Sélectionnez un devis "En attente"
4. Cliquez sur "Accepter"

### 5️⃣ VÉRIFIER LES LOGS BACKEND APRÈS ACCEPTATION

**Logs attendus :**
```
✅ Notification envoyée aux admins : devis accepté
👥 Recherche des admins actifs...
👥 1 admin(s) trouvé(s): [ { id: 6, email: 'admin@mct-maintenance.com' } ]
📬 Envoi de notifications à 1 admin(s)
📬 Notification créée pour user 6: Devis accepté
🔌 Tentative d'envoi Socket.IO à la room "user:6"
👤 1 client(s) connecté(s) dans cette room
🔔 Notification envoyée en temps réel à 1 client(s) de user 6
✅ Notifications créées pour les admins
```

### 6️⃣ VÉRIFIER LA CONSOLE DU NAVIGATEUR

**Logs attendus :**
```
🔔 Nouvelle notification reçue: {
  id: XX,
  type: 'quote_accepted',
  title: 'Devis accepté',
  message: 'Client X a accepté un devis de Y FCFA',
  ...
}
```

## 🚨 PROBLÈMES POSSIBLES

### Problème 1: Pas de logs Socket.IO dans la console web
**Cause**: NotificationBell ne se charge pas ou Socket.IO ne se connecte pas

**Solution**:
1. Vérifiez que le NotificationBell est dans le layout
2. Vérifiez que l'utilisateur est bien connecté
3. Rafraîchissez la page (Cmd+R)

### Problème 2: "0 client(s) connecté(s) dans cette room"
**Cause**: L'admin n'est pas connecté via Socket.IO

**Solutions**:
1. Vérifiez CORS dans le backend
2. Vérifiez que l'URL API est correcte: `http://localhost:3000`
3. Vérifiez que le port 3000 est accessible

### Problème 3: "Aucun admin actif trouvé"
**Cause**: Pas d'utilisateur avec role='admin' et status='active'

**Solution**: Vérifier la base de données avec `node check-admins.js`

### Problème 4: Socket.IO connecté mais pas de notification
**Cause**: La room n'est pas correcte ou l'événement n'est pas écouté

**Solutions**:
1. Vérifiez que l'authentification Socket.IO a réussi
2. Vérifiez que la room `user:6` a été jointe
3. Vérifiez que `new_notification` est écouté

## 📊 COMMANDES UTILES

### Voir les logs backend en temps réel
```bash
cd mct-maintenance-api
npm start
```

### Vérifier les admins
```bash
node check-admins.js
```

### Redémarrer le backend
```bash
lsof -ti:3000 | xargs kill -9
npm start
```

## 📝 RAPPORT DE TEST

Après avoir suivi toutes les étapes, notez :

1. **Console navigateur** :
   - [ ] Socket.IO connecté ?
   - [ ] Authentification réussie ?
   - [ ] Notification reçue ?

2. **Logs backend** :
   - [ ] Client connecté ?
   - [ ] Utilisateur authentifié ?
   - [ ] Room jointe ?
   - [ ] Notification créée ?
   - [ ] Socket.IO envoyé ?
   - [ ] Clients connectés dans la room ?

3. **Comportement** :
   - [ ] Badge de notification apparaît ?
   - [ ] Toast de notification s'affiche ?
   - [ ] Son de notification (si activé) ?

## 🎯 PROCHAINES ÉTAPES

Si tout fonctionne :
✅ Les notifications fonctionnent correctement !

Si ça ne fonctionne pas :
📋 Copiez-collez TOUS les logs (navigateur + backend) et partagez-les
