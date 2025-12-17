# 🧪 Guide de Test - Notifications des Réclamations

## Préparation

### 1. Redémarrer l'API

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
./restart.sh
# ou
npm run restart
```

### 2. Vérifier que l'API est en cours d'exécution

```bash
curl http://localhost:3000/api/health
# Devrait retourner: {"status":"ok"}
```

### 3. Ouvrir les logs en temps réel

Dans un terminal séparé :
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
tail -f logs/api.log
```

---

## 🎯 Tests à Effectuer

### Test 1 : Modification de la Résolution

#### Scénario
Un client a créé une réclamation. L'admin/technicien ajoute une résolution.

#### Steps
1. **Dashboard Web** : 
   - Se connecter en tant qu'admin/technicien
   - Aller dans "Réclamations"
   - Ouvrir une réclamation existante
   - Modifier le champ **"Résolution"**
   - Cliquer sur "Sauvegarder"

2. **Logs API** :
   ```
   ✅ Notification mise à jour réclamation [ID] envoyée au client
   ```

3. **Mobile Client** :
   - Doit recevoir une notification push
   - Titre : "Mise à jour de votre réclamation"
   - Message : "Votre réclamation '[sujet]' a été mise à jour"

#### ✅ Résultat attendu
- [ ] Notification push reçue sur le mobile
- [ ] Notification visible dans l'app (badge)
- [ ] Au clic, navigation vers la réclamation

---

### Test 2 : Modification de la Description

#### Scénario
L'admin modifie la description de la réclamation pour clarifier.

#### Steps
1. **Dashboard Web** :
   - Ouvrir une réclamation
   - Modifier le champ **"Description"**
   - Sauvegarder

2. **Logs API** :
   ```
   ✅ Notification mise à jour réclamation [ID] envoyée au client
   ```

3. **Mobile Client** :
   - Notification push reçue
   - Type : `complaint_response`

#### ✅ Résultat attendu
- [ ] Notification push reçue
- [ ] Message correct affiché

---

### Test 3 : Changement de Priorité

#### Scénario
L'admin change la priorité de "medium" à "high".

#### Steps
1. **Dashboard Web** :
   - Ouvrir une réclamation
   - Changer le champ **"Priorité"** (low/medium/high)
   - Sauvegarder

2. **Vérification** :
   - Log : `✅ Notification mise à jour réclamation...`
   - Mobile : Notification reçue

#### ✅ Résultat attendu
- [ ] Notification envoyée
- [ ] Client informé du changement

---

### Test 4 : Changement de Statut

#### Scénario
L'admin change le statut de "open" à "in_progress".

#### Steps
1. **Dashboard Web** :
   - Ouvrir une réclamation
   - Changer le **"Statut"** uniquement
   - Sauvegarder

2. **Logs API** :
   ```
   ✅ Notification changement statut réclamation [ID] vers "in_progress" envoyée
   ```

3. **Mobile Client** :
   - Notification : "Réclamation en cours de traitement"
   - Type : `complaint_status_change`

#### ✅ Résultat attendu
- [ ] Notification de statut spécifique reçue
- [ ] Message adapté au nouveau statut

---

### Test 5 : Statut "Resolved" avec Résolution

#### Scénario
L'admin résout la réclamation et ajoute une résolution.

#### Steps
1. **Dashboard Web** :
   - Ouvrir une réclamation
   - Changer le **"Statut"** à "resolved"
   - Ajouter une **"Résolution"**
   - Sauvegarder

2. **Logs API** :
   ```
   ✅ Notification changement statut réclamation [ID] vers "resolved" envoyée
   ```

3. **Mobile Client** :
   - Notification : "Réclamation résolue"
   - Message : "Votre réclamation a été résolue. Merci de votre patience !"

#### ✅ Résultat attendu
- [ ] Notification de résolution reçue
- [ ] Pas de notification double (statut prioritaire)

---

### Test 6 : Ajout d'une Note

#### Scénario
L'admin ajoute une note/commentaire à la réclamation.

#### Steps
1. **Dashboard Web** :
   - Ouvrir une réclamation
   - Ajouter une note dans la section "Suivi"
   - Soumettre

2. **Logs API** :
   ```
   ✅ Notification suivi réclamation envoyée au client
   ```

3. **Mobile Client** :
   - Notification : "Nouveau suivi sur votre réclamation"
   - Message : "[Admin/Tech] a ajouté un suivi à votre réclamation"

#### ✅ Résultat attendu
- [ ] Notification de note reçue
- [ ] Message avec prévisualisation de la note

---

## 🔍 Vérifications Techniques

### Base de données (Notifications)

Vérifier qu'une nouvelle notification est créée :

```sql
SELECT id, user_id, type, title, message, created_at 
FROM notifications 
WHERE user_id = [CLIENT_USER_ID]
ORDER BY created_at DESC 
LIMIT 5;
```

### Types de notifications attendus

- `complaint_status_change` → Changement de statut
- `complaint_response` → Autres modifications
- `complaint_response` → Note ajoutée

### FCM Token

Vérifier que le client a un token FCM actif :

```sql
SELECT id, user_id, fcm_token, platform, created_at 
FROM fcm_tokens 
WHERE user_id = [CLIENT_USER_ID];
```

---

## ❌ Problèmes Possibles et Solutions

### Problème 1 : Aucune notification reçue

**Causes possibles :**
- [ ] Client n'a pas de token FCM enregistré
- [ ] Token FCM expiré
- [ ] Notifications désactivées dans l'app mobile

**Solution :**
1. Vérifier les tokens FCM dans la base de données
2. Demander au client de se reconnecter dans l'app
3. Vérifier les permissions de notification sur l'appareil

### Problème 2 : Notification créée mais pas envoyée

**Causes possibles :**
- [ ] Erreur FCM (clés incorrectes)
- [ ] Service FCM non démarré
- [ ] Fichier `firebase-service-account.json` manquant

**Solution :**
```bash
# Vérifier le fichier de configuration FCM
ls -la mct-maintenance-api/firebase-service-account.json

# Vérifier les logs d'erreur FCM
grep "FCM" mct-maintenance-api/logs/api.log | tail -20
```

### Problème 3 : Notification en double

**Causes possibles :**
- [ ] Plusieurs tokens FCM pour le même utilisateur
- [ ] Appel multiple de la fonction de notification

**Solution :**
```bash
# Nettoyer les tokens dupliqués
cd mct-maintenance-api
node fix-duplicate-fcm-tokens.js
```

---

## 📊 Tableau de Bord de Test

| Test | Description | Statut | Notes |
|------|-------------|--------|-------|
| 1 | Modification résolution | ⏳ | |
| 2 | Modification description | ⏳ | |
| 3 | Changement priorité | ⏳ | |
| 4 | Changement statut | ⏳ | |
| 5 | Statut resolved + résolution | ⏳ | |
| 6 | Ajout de note | ⏳ | |

**Légende :**
- ⏳ À tester
- ✅ Réussi
- ❌ Échec

---

## 🎉 Validation Finale

Une fois tous les tests réussis :

- [x] Code déployé en production
- [ ] Tests manuels effectués sur tous les scénarios
- [ ] Validation sur appareil iOS
- [ ] Validation sur appareil Android
- [ ] Documentation utilisateur mise à jour
- [ ] Client informé des améliorations

---

## 📞 Support

En cas de problème :
1. Vérifier les logs : `tail -f mct-maintenance-api/logs/api.log`
2. Vérifier la base de données (notifications table)
3. Tester avec le script : `./test_complaint_notifications.sh`

**Date du guide** : 4 novembre 2025
