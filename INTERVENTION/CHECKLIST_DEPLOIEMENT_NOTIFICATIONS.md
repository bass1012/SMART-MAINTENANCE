# ✅ Checklist de Déploiement - Notifications Réclamations

## Pré-Déploiement

- [x] Code modifié et testé localement
- [x] Pas d'erreur de syntaxe
- [x] Documentation créée
- [ ] Revue de code effectuée
- [ ] Tests unitaires passent (si applicable)

## Déploiement

### 1. Sauvegarde

```bash
# Sauvegarder la base de données
cd mct-maintenance-api
npm run db:backup
# ou
mysqldump -u root -p mct_maintenance > backup_$(date +%Y%m%d_%H%M%S).sql
```

- [ ] Base de données sauvegardée

### 2. Mise à jour du code

```bash
# Vérifier les modifications
git status
git diff

# Commiter les changements
git add mct-maintenance-api/src/controllers/complaintController.js
git add mct-maintenance-api/src/services/notificationHelpers.js
git commit -m "fix: Ajout notifications pour toutes modifications réclamations

- Ajout notification pour modification résolution
- Ajout notification pour modification description  
- Ajout notification pour modification priorité
- Ajout notification pour modification sujet
- Amélioration message notifyComplaintResponse

Fix: Client ne recevait pas de notif lors de modifications web"

# Pousser sur le repo
git push origin main
```

- [ ] Code commité
- [ ] Code poussé sur le repo

### 3. Redémarrage de l'API

```bash
cd mct-maintenance-api

# Arrêter l'API actuelle
pm2 stop mct-api
# ou
pkill -f "node.*app.js"

# Redémarrer l'API
./restart.sh
# ou
npm run restart
```

- [ ] API redémarrée
- [ ] Aucune erreur au démarrage

### 4. Vérification des logs

```bash
tail -f logs/api.log
```

Rechercher :
```
✅ Server started on port 3000
✅ Database connected
✅ Socket.IO initialized
✅ FCM initialized
```

- [ ] Tous les services démarrés correctement

## Tests Post-Déploiement

### Test 1 : Modification Résolution

```bash
# Depuis le terminal
./test_complaint_notifications.sh
```

- [ ] Script exécuté sans erreur
- [ ] Notification créée en base de données

### Test 2 : Test Manuel Web → Mobile

1. **Dashboard Web**
   - [ ] Connexion admin réussie
   - [ ] Réclamation ouverte
   - [ ] Résolution modifiée
   - [ ] Sauvegarde OK
   - [ ] Log API : `✅ Notification mise à jour réclamation...`

2. **Mobile Client**
   - [ ] Notification push reçue
   - [ ] Titre correct : "Mise à jour de votre réclamation"
   - [ ] Message correct avec le sujet
   - [ ] Clic → Navigation vers la réclamation
   - [ ] Badge mis à jour

### Test 3 : Autres Modifications

- [ ] Modification description → Notification OK
- [ ] Changement priorité → Notification OK
- [ ] Changement statut → Notification OK (déjà existant)
- [ ] Ajout note → Notification OK (déjà existant)

## Surveillance

### Pendant les 24 premières heures

```bash
# Surveiller les logs
watch -n 5 'tail -20 mct-maintenance-api/logs/api.log | grep "Notification"'

# Compter les notifications envoyées
grep "Notification mise à jour réclamation" logs/api.log | wc -l
```

- [ ] Aucune erreur FCM
- [ ] Notifications envoyées correctement
- [ ] Pas de notification en double

### Vérification base de données

```sql
-- Compter les nouvelles notifications
SELECT 
  DATE(created_at) as date,
  type,
  COUNT(*) as count
FROM notifications 
WHERE type IN ('complaint_response', 'complaint_status_change')
  AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY date, type;

-- Vérifier qu'il n'y a pas de doublons
SELECT 
  user_id,
  type,
  created_at,
  COUNT(*) as duplicates
FROM notifications
WHERE type = 'complaint_response'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY user_id, type, created_at
HAVING duplicates > 1;
```

- [ ] Notifications créées correctement
- [ ] Pas de doublons détectés

## Rollback (en cas de problème)

### Si erreur critique détectée

```bash
# 1. Restaurer le code précédent
git revert HEAD
git push origin main

# 2. Redémarrer l'API
cd mct-maintenance-api
./restart.sh

# 3. Vérifier que tout fonctionne
curl http://localhost:3000/api/health
```

### Fichiers de rollback

Garder une copie des anciens fichiers :
```bash
cp mct-maintenance-api/src/controllers/complaintController.js{,.backup}
cp mct-maintenance-api/src/services/notificationHelpers.js{,.backup}
```

## Communication

### Informer l'équipe

- [ ] Équipe technique informée du déploiement
- [ ] Équipe support informée des nouvelles fonctionnalités
- [ ] Documentation mise à jour dans le wiki/confluence

### Informer les utilisateurs (optionnel)

Email/notification aux admins :
```
Nouvelle fonctionnalité : Notifications améliorées

Désormais, les clients recevront une notification mobile 
lorsque vous modifiez leur réclamation (résolution, 
description, priorité, etc.).

Plus besoin de les appeler pour les tenir informés !
```

## Validation Finale

- [ ] API en production fonctionne
- [ ] Notifications web (Socket.IO) OK
- [ ] Notifications mobile (FCM) OK
- [ ] Aucune erreur dans les logs
- [ ] Tests manuels réussis
- [ ] Performance normale (pas de ralentissement)
- [ ] Base de données OK
- [ ] Documentation à jour

## Métriques à Suivre (J+7)

```sql
-- Nombre de notifications envoyées
SELECT COUNT(*) as total_notifications
FROM notifications
WHERE type IN ('complaint_response', 'complaint_status_change')
  AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Taux de lecture
SELECT 
  is_read,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM notifications
WHERE type = 'complaint_response'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY is_read;

-- Délai de lecture moyen
SELECT 
  AVG(TIMESTAMPDIFF(MINUTE, created_at, read_at)) as avg_minutes
FROM notifications
WHERE type = 'complaint_response'
  AND is_read = 1
  AND read_at IS NOT NULL
  AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);
```

- [ ] Métriques collectées
- [ ] Analyse effectuée
- [ ] Rapport de déploiement créé

---

## Statut Global

**Date de déploiement** : ___________  
**Déployé par** : ___________  
**Statut** : ⏳ En attente / 🚀 En cours / ✅ Terminé / ❌ Échec

**Notes** :
_______________________________
_______________________________
_______________________________

**Signature** : ___________
