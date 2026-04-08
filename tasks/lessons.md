# Leçons Apprises

<!-- Format: [date] | ce qui a mal tourné | règle pour l'éviter -->

[2026-04-07] | Notifications dupliquées envoyées car pas de vérification si déjà envoyée aujourd'hui | Toujours implémenter une logique de déduplication pour les jobs cron qui envoient des notifications

[2026-04-07] | Push notifications ne fonctionnent pas car le serveur de prod utilise un ancien fichier Firebase (projet différent) | Après changement de projet Firebase: 1) Mettre à jour firebase-service-account.json sur TOUS les serveurs 2) Redémarrer les serveurs 3) Les utilisateurs doivent se reconnecter pour régénérer leur token FCM

[2026-04-08] | firebase-admin SDK v13+ ne fonctionne pas pour envoyer des FCM (erreur auth interne) | Utiliser google-auth-library + HTTP v1 API directement via https natif au lieu de firebase-admin pour les notifications FCM

[2026-04-08] | Clé APNs uploadée uniquement en slot "développement" dans Firebase Console → iOS notifications échouent avec THIRD_PARTY_AUTH_ERROR | Firebase a deux slots séparés pour les clés APNs (dev et production). Toujours uploader la clé .p8 dans LES DEUX slots, même si Apple ne distingue plus dev/prod

[2026-04-08] | Token FCM envoyé à un appareil iOS avec THIRD_PARTY_AUTH_ERROR mais Android fonctionne | Quand Android marche mais iOS non → c'est un problème de clé APNs dans Firebase, pas un problème OAuth

[2026-04-08] | PM2 processes corrompus ("Process 0 not found") → 502 Bad Gateway | Quand pm2 restart échoue, utiliser: pm2 kill && pm2 start ecosystem.config.js

