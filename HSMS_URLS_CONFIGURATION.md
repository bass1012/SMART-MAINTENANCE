# 📋 Configuration de l'application HSMS.ci

## URLs à fournir lors de la création de l'application

Lorsque vous créez une application sur HSMS.ci, ils vous demandent deux URLs :

---

### 1️⃣ URL de notification

**C'est quoi ?**  
Cette URL reçoit les notifications de statut des SMS (livré, échoué, en attente).

**URL à fournir** :

#### En développement (local) :
```
http://192.168.1.139:3000/api/sms/notification
```

#### En production (avec votre domaine) :
```
https://api.mct-maintenance.com/api/sms/notification
```

**⚠️ Important** : 
- En local, utilisez votre **IP locale** (pas `localhost`)
- Assurez-vous que le port **3000** est accessible
- HSMS.ci doit pouvoir accéder à cette URL depuis Internet

---

### 2️⃣ URL de stop

**C'est quoi ?**  
Cette URL est appelée quand un utilisateur répond "STOP" à un SMS pour se désabonner.

**URL à fournir** :

#### En développement (local) :
```
http://192.168.1.139:3000/api/sms/stop
```

#### En production (avec votre domaine) :
```
https://api.mct-maintenance.com/api/sms/stop
```

---

## 🚀 Démarrage rapide

### Étape 1 : Vérifier l'IP locale

```bash
# Sur macOS
ipconfig getifaddr en0

# Ou
ifconfig | grep "inet "
```

Vous devriez voir quelque chose comme : `192.168.1.139`

### Étape 2 : Mettre à jour le fichier .env

Ouvrez `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/.env` et mettez à jour :

```env
# Backend URL (utilisez votre IP locale)
BACKEND_URL=http://192.168.1.139:3000
```

### Étape 3 : Démarrer le backend

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node src/app.js
```

Vérifiez dans les logs :
```
✅ Routes mounted: /api/sms available
```

### Étape 4 : Tester les webhooks

```bash
# Test endpoint de notification
curl http://192.168.1.139:3000/api/sms/test

# Résultat attendu :
{
  "success": true,
  "message": "Webhooks HSMS.ci opérationnels",
  "endpoints": {
    "notification": "http://192.168.1.139:3000/api/sms/notification",
    "stop": "http://192.168.1.139:3000/api/sms/stop"
  }
}
```

### Étape 5 : Configurer sur HSMS.ci

1. Aller sur https://hsms.ci/connexion
2. Se connecter avec votre compte
3. Aller dans **Applications** → **Créer une application**
4. Remplir le formulaire :

| Champ | Valeur |
|-------|--------|
| Nom de l'application | SMART MAINTENANCE |
| Description | Application de maintenance MCT |
| URL de notification | `http://192.168.1.139:3000/api/sms/notification` |
| URL de stop | `http://192.168.1.139:3000/api/sms/stop` |

5. Valider la création
6. Copier la **clé API** générée

### Étape 6 : Mettre à jour la clé API

Dans `.env` :
```env
HSMS_API_KEY=la_cle_generee_par_hsms
```

---

## 🧪 Tester les webhooks

### Test manuel de l'URL de notification

```bash
curl -X POST http://192.168.1.139:3000/api/sms/notification \
  -H "Content-Type: application/json" \
  -d '{
    "message_id": "test123",
    "recipient": "2250170793131",
    "status": "delivered",
    "delivery_time": "2026-01-21 10:30:00"
  }'
```

**Résultat attendu** :
```json
{
  "success": true,
  "message": "Notification reçue"
}
```

**Dans les logs du backend** :
```
📬 Notification HSMS.ci reçue: { message_id: 'test123', ... }
✅ SMS test123 livré à 2250170793131 à 2026-01-21 10:30:00
```

### Test manuel de l'URL de stop

```bash
curl -X POST http://192.168.1.139:3000/api/sms/stop \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "2250170793131",
    "message": "STOP",
    "timestamp": "2026-01-21 10:30:00"
  }'
```

**Résultat attendu** :
```json
{
  "success": true,
  "message": "Désabonnement enregistré"
}
```

**Dans les logs du backend** :
```
🛑 Demande de désabonnement HSMS.ci: { phone_number: '2250170793131', ... }
🛑 Désabonnement demandé par 2250170793131
```

---

## 🌐 Pour le développement avec ngrok

Si votre backend n'est pas accessible depuis Internet (firewall, NAT, etc.), utilisez **ngrok** :

### Installation ngrok

```bash
# macOS
brew install ngrok

# Ou télécharger depuis https://ngrok.com
```

### Exposer le backend

```bash
# Exposer le port 3000
ngrok http 3000
```

**Résultat** :
```
Forwarding  https://abc123.ngrok.io -> http://localhost:3000
```

### Mettre à jour les URLs dans HSMS.ci

| Champ | Valeur |
|-------|--------|
| URL de notification | `https://abc123.ngrok.io/api/sms/notification` |
| URL de stop | `https://abc123.ngrok.io/api/sms/stop` |

⚠️ **Attention** : L'URL ngrok change à chaque redémarrage (version gratuite)

---

## 📊 Ce que font les webhooks

### URL de notification

Quand HSMS.ci envoie un SMS, il notifie votre backend du statut :

| Statut | Description |
|--------|-------------|
| `pending` | SMS en attente d'envoi |
| `sent` | SMS envoyé au réseau mobile |
| `delivered` | SMS livré au destinataire ✅ |
| `failed` | Échec de livraison ❌ |

**Exemple de notification** :
```json
{
  "message_id": "msg_12345",
  "recipient": "2250170793131",
  "status": "delivered",
  "delivery_time": "2026-01-21 10:30:15",
  "error_code": null,
  "error_message": null
}
```

### URL de stop

Quand un utilisateur répond **"STOP"** à un SMS, HSMS.ci vous notifie :

**Exemple** :
```json
{
  "phone_number": "2250170793131",
  "message": "STOP",
  "timestamp": "2026-01-21 10:30:00"
}
```

Vous devez alors :
1. Enregistrer que cet utilisateur ne veut plus recevoir de SMS
2. Ne plus lui envoyer de SMS marketing (codes de vérification OK)

---

## 🔒 Sécurité

### En production

1. **Utiliser HTTPS** :
   ```
   https://api.mct-maintenance.com/api/sms/notification
   ```

2. **Vérifier l'origine** :
   - Ajouter une vérification de l'IP source (IP de HSMS.ci)
   - Ou utiliser un token de sécurité dans l'URL

3. **Logger les appels** :
   - Sauvegarder toutes les notifications dans la BDD
   - Pour audit et statistiques

### Exemple de sécurisation

```javascript
// Dans smsWebhookRoutes.js
router.post('/notification', async (req, res) => {
  // Vérifier l'IP source
  const clientIp = req.ip || req.connection.remoteAddress;
  const allowedIps = ['IP_HSMS_1', 'IP_HSMS_2']; // À demander à HSMS.ci
  
  if (!allowedIps.includes(clientIp)) {
    console.warn(`⚠️ Tentative d'accès non autorisée depuis ${clientIp}`);
    return res.status(403).json({ error: 'Forbidden' });
  }
  
  // Continuer le traitement...
});
```

---

## 📝 Résumé

**URLs à fournir à HSMS.ci** :

| Type | URL de développement | URL de production |
|------|---------------------|-------------------|
| Notification | `http://192.168.1.139:3000/api/sms/notification` | `https://api.mct-maintenance.com/api/sms/notification` |
| Stop | `http://192.168.1.139:3000/api/sms/stop` | `https://api.mct-maintenance.com/api/sms/stop` |

**Fichiers créés** :
- ✅ `src/routes/smsWebhookRoutes.js` - Routes webhooks
- ✅ `src/app.js` - Routes montées sur `/api/sms`

**Prochaines étapes** :
1. Démarrer le backend
2. Tester les webhooks avec curl
3. Créer l'application sur HSMS.ci
4. Récupérer et configurer la clé API
5. Tester l'envoi de SMS

---

**Besoin d'aide ?** Consultez [INTEGRATION_HSMS_SMS.md](INTEGRATION_HSMS_SMS.md) pour plus de détails.
