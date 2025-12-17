# 🧪 TEST : Notifications Technicien

## 📋 Objectif

Vérifier que le technicien reçoit bien les notifications push FCM quand une intervention lui est assignée.

---

## 🔍 **Problème Actuel**

- ✅ Le technicien se connecte à l'app mobile
- ✅ Le dashboard affiche les stats correctement
- ❌ **Le token FCM n'est pas enregistré dans le backend**
- ❌ **Les notifications push ne sont pas reçues**

**Logs manquants dans le terminal Dart :**
```
❌ 🔔 [FCM] Début initialisation...
❌ 🚀 [FCM] Étape 1: Demande de permission...
❌ 📱 [FCM] Token obtenu...
❌ 📤 [FCM] Étape 4: Envoi token au backend...
```

---

## ✅ **Étapes de Test**

### **1. Activer les Logs de Debug**

Les logs détaillés ont été ajoutés dans `fcm_service.dart`.

### **2. Relancer l'App Mobile**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile

# Clean rebuild complet
flutter clean
flutter pub get

# Lancer sur Android
flutter run
```

### **3. Se Déconnecter**

Dans l'app mobile :
1. **Paramètres** (icône ⚙️)
2. **Déconnexion**
3. **Confirmer**

### **4. Se Reconnecter**

1. **Email :** `cissoko@gmail.com`
2. **Mot de passe :** Le mot de passe du technicien
3. **Cliquer sur Connexion**

### **5. Observer les Logs Flutter**

**Terminal Dart - Logs attendus après le login :**

```
I/flutter: 🔔 [FCM] Début initialisation...
I/flutter: 🚀 [FCM] Étape 1: Demande de permission...
I/flutter: 📋 [FCM] Statut permission: AuthorizationStatus.authorized
I/flutter: ✅ [FCM] Permission de notification accordée
I/flutter: 🔔 [FCM] Étape 2: Initialisation notifications locales...
I/flutter: ✅ [FCM] Notifications locales OK
I/flutter: 🔔 [FCM] Étape 3: Obtention du token FCM...
I/flutter: 📱 [FCM] Token obtenu: dGhpc19pc19hX2ZjbV...
I/flutter: 📤 [FCM] Étape 4: Envoi token au backend...
I/flutter: 📤 [FCM->Backend] Appel API updateFcmToken...
I/flutter: 📤 Envoi du token FCM au backend...
I/flutter: ✅ [FCM->Backend] Token FCM enregistré dans le backend
I/flutter: ✅ [FCM] Token envoyé au backend avec succès
I/flutter: 🎉 [FCM] Initialisation terminée avec succès
I/flutter: ✅ FCM initialisé avec succès après login
```

**Terminal Node (Backend) - Logs attendus :**

```
[2025-10-28T09:00:00.000Z] POST /api/auth/fcm-token
Headers: {
  authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  ...
}
Body: { fcm_token: 'dGhpc19pc19hX2ZjbV90b2tlbl9leGFtcGxlX2Zvcl9kb2N1bWVudGF0aW9u...' }
📱 Mise à jour du token FCM
   User ID: 8
   Token: dGhpc19pc19hX2ZjbV90...
✅ Token FCM enregistré avec succès
POST /api/auth/fcm-token 200 12.345 ms - 67
```

---

## 🔍 **Diagnostic selon les Logs**

### **Cas 1 : Aucun log FCM**

**Logs :**
```
❌ Aucun log [FCM] dans le terminal Dart
```

**Diagnostic :** FCMService().initialize() n'est jamais appelé

**Causes possibles :**
- Exception lors du login avant d'arriver à FCM
- login_form.dart n'appelle pas FCMService().initialize()

**Solution :**
1. Vérifier les logs juste avant la ligne de FCM
2. Chercher des erreurs dans le login
3. Vérifier que le code atteint bien la ligne 70 de login_form.dart

---

### **Cas 2 : Permission refusée**

**Logs :**
```
I/flutter: 🔔 [FCM] Début initialisation...
I/flutter: 🚀 [FCM] Étape 1: Demande de permission...
I/flutter: ⚠️  [FCM] Permission de notification refusée: AuthorizationStatus.denied
```

**Diagnostic :** L'utilisateur a refusé les notifications

**Solution :**
```
Paramètres Android → Applications → MCT Maintenance → Notifications → Activer
```

Puis **redémarrer l'app** (pas juste hot reload).

---

### **Cas 3 : Token non obtenu**

**Logs :**
```
I/flutter: ✅ [FCM] Permission de notification accordée
I/flutter: 🔔 [FCM] Étape 2: Initialisation notifications locales...
I/flutter: ✅ [FCM] Notifications locales OK
I/flutter: 🔔 [FCM] Étape 3: Obtention du token FCM...
I/flutter: ⚠️  [FCM] Impossible d'obtenir le token FCM
```

**Diagnostic :** Firebase ne peut pas générer de token

**Causes possibles :**
- `google-services.json` manquant ou invalide
- Clé API Firebase incorrecte
- Connexion internet indisponible
- Google Play Services manquants (émulateur)

**Solutions :**
1. Vérifier `android/app/google-services.json` existe
2. Tester sur un appareil physique (pas émulateur)
3. Vérifier la connexion internet
4. Reconfigurer Firebase dans le projet

---

### **Cas 4 : Erreur envoi au backend**

**Logs :**
```
I/flutter: 📱 [FCM] Token obtenu: dGhpc19pc19hX2ZjbV...
I/flutter: 📤 [FCM] Étape 4: Envoi token au backend...
I/flutter: 📤 [FCM->Backend] Appel API updateFcmToken...
I/flutter: ❌ [FCM->Backend] Erreur envoi token: Exception: ...
I/flutter: 📍 [FCM->Backend] Stack trace: ...
```

**Diagnostic :** Le backend refuse ou n'accepte pas le token

**Causes possibles :**
- Token JWT expiré
- Route `/api/auth/fcm-token` non disponible
- Backend pas démarré
- Erreur réseau

**Solutions :**
1. Vérifier que le backend est démarré (port 3000)
2. Tester la route manuellement :
   ```bash
   curl -X POST http://localhost:3000/api/auth/fcm-token \
     -H "Authorization: Bearer <TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"fcm_token":"test123"}'
   ```
3. Vérifier les logs du backend

---

### **Cas 5 : Tout OK (Succès)**

**Logs Flutter :**
```
I/flutter: 🎉 [FCM] Initialisation terminée avec succès
I/flutter: ✅ FCM initialisé avec succès après login
```

**Logs Backend :**
```
POST /api/auth/fcm-token 200 OK
✅ Token FCM enregistré avec succès
```

**Vérification en base de données :**
```sql
SELECT id, email, fcm_token 
FROM users 
WHERE email = 'cissoko@gmail.com';
```

**Résultat attendu :**
```
id | email                | fcm_token
8  | cissoko@gmail.com    | dGhpc19pc19hX2ZjbV90b2tlbl9leGFtcGxlX2Zvcl9kb2N1bWVudGF0aW9u...
```

✅ **Le token est enregistré !**

---

## 🧪 **Test de Notification Push**

Une fois le token enregistré, testez l'envoi de notification :

### **1. Dashboard Web - Assigner une Intervention**

1. Se connecter au dashboard admin (http://localhost:3001)
2. **Interventions** → Sélectionner une intervention
3. **Modifier** → Assigner au technicien **Edourd Cissoko**
4. **Enregistrer**

### **2. Vérifier les Logs Backend**

**Logs attendus :**
```
PATCH /api/interventions/4/assign
📤 Envoi notification assignation au technicien user_id: 8
📬 Notification créée pour user 8: Nouvelle intervention assignée
🔌 Tentative d'envoi Socket.IO à la room "user:8"
📱 Notification FCM envoyée avec succès
✅ Notification envoyée au technicien pour l'assignation
PATCH /api/interventions/4/assign 200 OK
```

### **3. Vérifier l'App Mobile**

**L'app doit afficher :**

1. **Notification push Android** :
   ```
   🔔 Nouvelle intervention assignée
   Une intervention vous a été assignée
   ```

2. **Badge sur l'icône de l'app**

3. **Dans l'app** :
   - Nouvelle intervention dans la liste
   - Badge "Nouveau"

---

## 🚨 **Erreurs Courantes**

### **Erreur 1 : MissingPluginException**

```
MissingPluginException(No implementation found for method requestPermission)
```

**Cause :** Plugins Firebase pas enregistrés

**Solution :**
```bash
flutter clean
flutter pub get
flutter run
```

---

### **Erreur 2 : PlatformException**

```
PlatformException(ERROR, MISSING_INSTANCEID_SERVICE)
```

**Cause :** Google Play Services manquants

**Solution :**
- Tester sur appareil physique
- Ou installer Google Play Services sur l'émulateur

---

### **Erreur 3 : FirebaseException**

```
FirebaseException: [core/no-app] No Firebase App '[DEFAULT]' has been created
```

**Cause :** Firebase pas initialisé dans main.dart

**Solution :**
Vérifier que `main.dart` contient :
```dart
await Firebase.initializeApp();
```

---

## 📊 **Tableau de Diagnostic Complet**

| Symptôme | Cause | Solution |
|----------|-------|----------|
| Aucun log [FCM] | FCM pas appelé | Vérifier login_form.dart ligne 70 |
| Permission refusée | Utilisateur a refusé | Activer dans paramètres Android |
| Token NULL | Firebase config invalide | Vérifier google-services.json |
| Erreur backend | Route API manquante | Vérifier authRoutes.js |
| Notification pas reçue | Token pas enregistré | Vérifier base de données |
| Badge pas affiché | Permissions badges | Activer badges dans paramètres |

---

## 📝 **Checklist de Validation**

Avant de déclarer le problème résolu :

- [ ] Logs [FCM] visibles dans le terminal Dart
- [ ] Permission de notification accordée
- [ ] Token FCM obtenu (20+ caractères)
- [ ] Appel API `POST /api/auth/fcm-token` dans logs backend
- [ ] Token enregistré en base de données (`fcm_token` NOT NULL)
- [ ] Notification push reçue lors de l'assignation
- [ ] Badge affiché sur l'icône de l'app
- [ ] Son/vibration lors de la notification
- [ ] Clic sur notification ouvre l'app

---

## 🎯 **Résumé**

**Problème :** Technicien ne reçoit pas de notifications

**Cause probable :** Token FCM jamais enregistré (FCMService échoue silencieusement)

**Solution :**
1. Logs de debug ajoutés dans `fcm_service.dart`
2. Relancer l'app : `flutter clean && flutter run`
3. Se reconnecter en tant que technicien
4. Vérifier les logs Flutter et Backend
5. Vérifier le token en base de données

**Validation finale :**
```bash
# Vérifier le token
mysql> SELECT fcm_token FROM users WHERE id = 8;

# Assigner intervention
Dashboard Web → Interventions → Assigner au technicien

# Vérifier notification
App Mobile → 🔔 Notification reçue ✅
```

---

## 🔗 **Fichiers Modifiés**

- ✅ `/lib/services/fcm_service.dart` - Logs de debug ajoutés
- ✅ `/lib/widgets/auth/login_form.dart` - Appelle FCM après login
- ✅ Backend `/src/routes/authRoutes.js` - Route POST /api/auth/fcm-token
- ✅ Backend `/src/controllers/auth/authController.js` - updateFcmToken()

---

**IMPORTANT :** Après modification du code, **TOUJOURS** faire un `flutter clean` puis relancer l'app complètement (pas de hot reload).

**Prochaine étape :** Suivre ce guide de test et partager les logs obtenus.
