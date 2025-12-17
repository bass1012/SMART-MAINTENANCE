# 🐛 Debug - Badge de Notification Chat

## 🔍 Étapes de Diagnostic

### 1. Ouvrir le Dashboard
- URL: http://localhost:3001
- Se connecter comme **admin**

### 2. Ouvrir la Console Navigateur
- Appuyer sur **F12** ou **Cmd+Option+I** (Mac)
- Aller dans l'onglet **Console**

### 3. Vérifier les Logs au Chargement

Vous devriez voir ces logs au chargement de la page :

```
🔔 [useChatNotifications] Hook désactivé (enabled=false)
OU
🔔 [useChatNotifications] Chargement du compteur...
🔔 [useChatNotifications] Réponse API: {...}
🔔 [useChatNotifications] Total messages non lus: X
🔔 [NewLayout] Total messages non lus: X isAdmin: true
```

### 4. Envoyer un Message Test

**Depuis l'app mobile**, envoyez un message client

**OU** Utilisez ce code dans la console navigateur :

```javascript
// Test 1: Vérifier le rôle admin
const user = JSON.parse(localStorage.getItem('user'));
console.log('User:', user);
console.log('Is Admin?', user?.role === 'admin');

// Test 2: Vérifier la connexion Socket.IO
console.log('Socket connecté?', window.chatService?.socket?.connected);
```

### 5. Observer les Logs après Envoi

Vous devriez voir :

```
🔔 [useChatNotifications] Message reçu: {...}
🔔 [useChatNotifications] Incrémentation du compteur
🔔 [useChatNotifications] Nouveau compteur: 1
🔔 [NewLayout] Total messages non lus: 1 isAdmin: true
```

---

## ✅ Vérifications

### Le badge devrait apparaître si :

1. ✅ **Vous êtes admin** : `isAdmin: true` dans les logs
2. ✅ **Vous n'êtes PAS sur /chat** : Vous êtes sur /dashboard ou autre page
3. ✅ **Il y a des messages non lus** : `totalUnreadCount > 0` dans les logs
4. ✅ **Socket.IO est connecté** : Messages reçus en temps réel

---

## 🐛 Problèmes Possibles

### Badge ne s'affiche pas

**Cause 1 : Pas admin**
- Log : `isAdmin: false`
- Solution : Se connecter avec un compte admin

**Cause 2 : Compteur à 0**
- Log : `Total messages non lus: 0`
- Solution : Envoyer un message depuis le mobile

**Cause 3 : Sur la page Chat**
- URL : `/chat`
- Solution : Aller sur `/dashboard`

**Cause 4 : Hook désactivé**
- Log : `Hook désactivé (enabled=false)`
- Solution : Vérifier que `isAdmin` est `true`

**Cause 5 : Pas de connexion Socket.IO**
- Pas de logs de messages reçus
- Solution : Vérifier que le serveur backend tourne

---

## 🧪 Test Manuel Rapide

### Dans la console navigateur :

```javascript
// 1. Vérifier l'état actuel
console.log('=== ÉTAT ACTUEL ===');
console.log('URL:', window.location.pathname);
console.log('User:', JSON.parse(localStorage.getItem('user')));
console.log('Is Admin?', JSON.parse(localStorage.getItem('user'))?.role === 'admin');

// 2. Vérifier le DOM
const badge = document.querySelector('.MuiBadge-badge');
console.log('Badge trouvé?', badge !== null);
if (badge) {
  console.log('Badge content:', badge.textContent);
}

// 3. Forcer un refresh du compteur (si le hook est monté)
setTimeout(() => {
  console.log('Envoyez un message depuis le mobile maintenant!');
}, 2000);
```

---

## 📊 Logs Attendus (Scénario Complet)

```
// Au chargement de la page
🔔 [useChatNotifications] Chargement du compteur...
🔔 [useChatNotifications] Réponse API: {success: true, data: [...]}
🔔 [useChatNotifications] Total messages non lus: 2
🔔 [NewLayout] Total messages non lus: 2 isAdmin: true

// Badge devrait afficher "2"

// Après réception d'un message
🔔 [useChatNotifications] Message reçu: {sender_role: "customer", ...}
🔔 [useChatNotifications] Incrémentation du compteur
🔔 [useChatNotifications] Nouveau compteur: 3
🔔 [NewLayout] Total messages non lus: 3 isAdmin: true

// Badge devrait afficher "3"

// En cliquant sur Chat
🔔 [useChatNotifications] Sur la page chat, compteur réinitialisé
🔔 [NewLayout] Total messages non lus: 0 isAdmin: true

// Badge devrait disparaître
```

---

## 🔧 Solution Rapide si Ça Ne Marche Pas

### Forcer l'affichage du badge (TEST UNIQUEMENT) :

Dans `NewLayout.tsx`, remplacer temporairement :

```typescript
{item.path === '/chat' && totalUnreadCount > 0 ? (
```

Par :

```typescript
{item.path === '/chat' && (totalUnreadCount > 0 || true) ? ( // Affiche toujours
```

Si le badge apparaît maintenant avec cette modification, le problème vient du compteur.

---

**Date** : 6 novembre 2025
