# TODO - Session 7-8 avril 2026

## Problèmes résolus

### 1. ✅ Notifications de paiement en attente envoyées plusieurs fois
- **Cause racine** : Aucune vérification si une notification avait déjà été envoyée aujourd'hui
- **Fix** : Ajouté vérification dans `pendingDiagnosticReminder.js` avant d'envoyer
- **Fichier modifié** : `mct-maintenance-api/src/jobs/pendingDiagnosticReminder.js`

### 2. ✅ Notifications push ne fonctionnent pas en production
- **Causes racines** (multiples) :
  1. Ancien projet Firebase sur le serveur → Nouveau `firebase-service-account.json` uploadé (key ID: 9176df5e92)
  2. firebase-admin SDK v13+ ne fonctionne pas pour FCM → Réécrit `fcmService.js` avec google-auth-library + HTTP v1 API
  3. Clé APNs uploadée uniquement en slot "développement" dans Firebase Console → Uploadée aussi en "production"
- **Fichier modifié** : `mct-maintenance-api/src/services/fcmService.js` (réécriture complète)
- **Config Firebase** : Clé APNs D8R2UH35J6, Team ID A24M9HPHXW, uploadée en dev + prod
- **Résultat** : ✅ Android OK, ✅ iOS OK — testé avec succès le 8 avril 2026

### 3. ✅ Flutter UI overflow (support_screen.dart)
- **Fix** : SafeArea bottom padding conditionnel quand le clavier est ouvert

### 4. ✅ Serveur 502 Bad Gateway
- **Cause** : PM2 processes corrompus
- **Fix** : `pm2 kill && pm2 start ecosystem.config.js`

### 5. ✅ 8 notifications dupliquées par rappel de paiement
- **Cause racine** : PM2 cluster mode (8 workers) → chaque worker exécute les mêmes cron jobs
- **Fix** : Conditionner l'init des cron jobs à `NODE_APP_INSTANCE === '0'` dans `app.js`
- **Fichier modifié** : `mct-maintenance-api/src/app.js`
- **Résultat** : ✅ Seul le worker 0 exécute les cron jobs — vérifié dans les logs PM2

## Actions restantes

1. ⬜ Vérifier les notifications end-to-end depuis l'app (envoi de message chat)

