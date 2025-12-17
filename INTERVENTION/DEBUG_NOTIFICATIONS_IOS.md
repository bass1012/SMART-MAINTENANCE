# 🔍 Debug Notifications iOS - Compte Payant

## ✅ Prérequis Vérifiés
- Compte Apple Developer payant : ✅
- App iOS ouverte : ✅

## 🚨 Configuration APNs Requise

### Étape 1 : Générer la Clé APNs

1. **URL** : https://developer.apple.com/account/resources/authkeys/list
2. **Créer** une nouvelle clé :
   - Nom : `MCT Maintenance APNs Key`
   - ✅ Apple Push Notifications service (APNs)
3. **Télécharger** le fichier `.p8` (UNE SEULE FOIS)
4. **Noter** :
   - Key ID : `__________`
   - Team ID : `__________`

### Étape 2 : Configurer Firebase

1. **Firebase Console** : https://console.firebase.google.com
2. **⚙️ Project Settings** → **Cloud Messaging**
3. **Section iOS** → Upload APNs Authentication Key
4. **Remplir** :
   - Fichier `.p8`
   - Key ID
   - Team ID
5. **Save**

### Étape 3 : Vérifier l'App ID Apple

1. **URL** : https://developer.apple.com/account/resources/identifiers/list
2. **Chercher** : `com.bassoued.mctMaintenanceMobile`
3. **Vérifier** : ✅ Push Notifications est activé

### Étape 4 : Vérifier Xcode

Dans Xcode → Runner → Signing & Capabilities :
- ✅ Push Notifications
- ✅ Background Modes
  - ✅ Remote notifications

### Étape 5 : Rebuild Complet

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter clean
flutter run
```

---

## 🧪 Tests de Notifications

### Test 1 : Logs Backend en Temps Réel

**Terminal 1 - Afficher les logs du backend :**
```bash
# Si le backend tourne en background, voir les logs :
tail -f /dev/null
```

OU suivre les logs si vous avez un fichier de log :
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
# Le backend affiche dans la console où il a été lancé
```

Cherchez ces lignes quand vous créez une intervention :
```
✅ Notification FCM envoyée avec succès
   Token: cv4aheaESSKXzoGOOqmZ...
   Titre: [Titre]
   Message ID: [ID Firebase]
```

### Test 2 : Logs iOS en Temps Réel

**Terminal 2 - Logs Flutter :**
```bash
# Dans le terminal où "flutter run" tourne
# Cherchez :
🔔 [FCM] Permission de notification accordée
📱 [FCM] Token obtenu: cv4aheaESSKXzoGOOqmZ...
📤 [FCM] Envoi token au backend...
✅ [FCM] Token envoyé au backend avec succès
🎉 [FCM] Initialisation terminée avec succès

# Puis quand une notification arrive :
🔔 Notification reçue (foreground)
   Titre: [Titre]
   Message: [Message]
```

### Test 3 : Déclencher une Notification

**Option A - Depuis le Dashboard Web :**
1. Ouvrir : http://localhost:3001/interventions
2. Créer une nouvelle intervention
3. Client : Noel Pkanta (ID: 14)
4. Assigner un technicien

**Option B - Depuis l'API directement :**
```bash
# Récupérer le token
TOKEN=$(cat ~/.mct_auth_token 2>/dev/null || echo "your_token_here")

# Créer une intervention
curl -X POST http://localhost:3000/api/interventions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 14,
    "type": "maintenance",
    "description": "Test notification iOS",
    "address": "Test",
    "scheduledDate": "2025-11-04",
    "technicianId": 15
  }'
```

---

## ❌ Si Ça Ne Marche Toujours Pas

### Problème 1 : Pas de Token FCM

**Symptôme :**
```
⚠️  [FCM] Impossible d'obtenir le token FCM
```

**Solution :**
1. Vérifier les permissions iOS
2. iPhone → Réglages → MCT Maintenance → Notifications → Tout activer
3. Désinstaller et réinstaller l'app

### Problème 2 : Token Invalide

**Symptôme :**
```
❌ Erreur envoi notification FCM: Requested entity was not found
```

**Solution :**
- Le Bundle ID dans Firebase ne correspond pas
- Vérifier que `com.bassoued.mctMaintenanceMobile` est dans Firebase

### Problème 3 : Clé APNs Invalide

**Symptôme :**
```
❌ Error sending message: messaging/invalid-apns-credentials
```

**Solution :**
1. Régénérer la clé APNs sur Apple Developer
2. Re-uploader dans Firebase
3. Attendre 5-10 minutes que Firebase propage la config
4. Relancer l'app

### Problème 4 : App iOS Ne Reçoit Rien

**Debug :**

1. **Vérifier le token dans la DB :**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
sqlite3 database.sqlite "SELECT id, first_name, fcm_token FROM users WHERE id = 14;"
```

2. **Vérifier que les notifications sont créées :**
```bash
sqlite3 database.sqlite "SELECT * FROM notifications ORDER BY id DESC LIMIT 3;"
```

3. **Tester avec un outil externe :**
   - Firebase Console → Cloud Messaging → Send test message
   - Token : celui de l'utilisateur 14
   - Envoyer

---

## 📊 Checklist de Diagnostic

- [ ] Clé APNs uploadée dans Firebase
- [ ] Bundle ID correspond (`com.bassoued.mctMaintenanceMobile`)
- [ ] Push Notifications activé dans App ID Apple
- [ ] Capabilities OK dans Xcode
- [ ] Token FCM présent dans la DB pour user 14
- [ ] Backend affiche "Notification FCM envoyée"
- [ ] Permissions iOS accordées sur l'iPhone
- [ ] App relancée après config

---

## 🎯 Contact Support Firebase

Si tout échoue après configuration :

1. **Firebase Console** → Support
2. Fournir :
   - Project ID
   - Bundle ID : `com.bassoued.mctMaintenanceMobile`
   - Token FCM de test
   - Logs d'erreur
