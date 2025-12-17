# 🔥 État d'implémentation Firebase Cloud Messaging (FCM)

## ✅ ÉTAPES COMPLÉTÉES

### **1. Configuration Flutter** ✅

**Packages ajoutés dans pubspec.yaml :**
```yaml
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10
flutter_local_notifications: ^16.3.0
```

**Permissions ajoutées dans AndroidManifest.xml :**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### **2. Service FCM Flutter créé** ✅

**Fichier** : `/lib/services/fcm_service.dart`

**Fonctionnalités** :
- ✅ Initialisation Firebase
- ✅ Demande de permission
- ✅ Obtention du token FCM
- ✅ Rafraîchissement automatique du token
- ✅ Envoi du token au backend
- ✅ Gestion des notifications foreground
- ✅ Gestion des notifications background
- ✅ Gestion du clic sur les notifications
- ✅ Notifications locales
- ✅ Handler background (top-level)

### **3. ApiService mis à jour** ✅

**Méthode ajoutée** : `updateFcmToken(String fcmToken)`
- Endpoint : `POST /api/auth/fcm-token`
- Enregistre le token FCM dans le backend

### **4. main.dart mis à jour** ✅

**Ajouts** :
- ✅ Import Firebase Core et Messaging
- ✅ `Firebase.initializeApp()` au démarrage
- ✅ Configuration du handler background

---

## ⏳ ÉTAPES À FAIRE MANUELLEMENT

### **ÉTAPE 1 : Configuration Firebase Console** (5 min)

**Ce que VOUS devez faire** :

1. ✅ Aller sur https://console.firebase.google.com/
2. ✅ Créer/Sélectionner un projet : `MCT-Maintenance`
3. ✅ Ajouter une app Android
4. ✅ Package name : Vérifier dans `/android/app/build.gradle`
   ```gradle
   defaultConfig {
       applicationId "com.example.mct_maintenance_mobile"  ← Cette valeur
   }
   ```
5. ✅ Télécharger `google-services.json`
6. ✅ Placer le fichier dans : `/android/app/google-services.json`
7. ✅ Récupérer la **Server Key** (Project Settings → Cloud Messaging)
8. ✅ Copier la Server Key quelque part

---

### **ÉTAPE 2 : Configuration build.gradle** (2 min)

**Fichier** : `/android/build.gradle`

Vérifier que cette ligne existe (devrait déjà être là) :
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'  // Google Services plugin
}
```

**Fichier** : `/android/app/build.gradle`

Ajouter à la FIN du fichier :
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

### **ÉTAPE 3 : Installer les packages Flutter** (1 min)

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter pub get
```

---

## ⏳ ÉTAPES BACKEND (À FAIRE ENSUITE)

### **1. Migration : Ajouter colonne fcm_token**

**Table** : `users`
**Colonne** : `fcm_token` (VARCHAR 255, nullable)

### **2. Route : POST /api/auth/fcm-token**

Enregistrer le token FCM de l'utilisateur connecté

### **3. Service : fcmService.js**

Service d'envoi de notifications push via FCM

### **4. Intégration dans notificationHelpers.js**

Envoyer notifications push en plus de Socket.IO

---

## 📋 CHECKLIST COMPLÈTE

### **Flutter (Fait)** ✅
- [x] Packages ajoutés dans pubspec.yaml
- [x] Permissions AndroidManifest.xml
- [x] Service FCM créé
- [x] ApiService.updateFcmToken() ajoutée
- [x] main.dart avec Firebase.initializeApp()

### **Firebase Console (À FAIRE)**
- [ ] Projet Firebase créé
- [ ] App Android ajoutée
- [ ] google-services.json téléchargé
- [ ] google-services.json placé dans /android/app/
- [ ] Server Key récupérée

### **Configuration Android (À FAIRE)**
- [ ] build.gradle vérifié
- [ ] google-services plugin appliqué
- [ ] flutter pub get exécuté

### **Backend (À FAIRE)**
- [ ] Migration fcm_token
- [ ] Route POST /api/auth/fcm-token
- [ ] Service fcmService.js
- [ ] Intégration dans notificationHelpers.js

---

## 🚀 PROCHAINES ACTIONS

### **MAINTENANT (Vous)** :

1. **Configurer Firebase Console** (5 min)
   - Suivre le guide : `FCM_SETUP_GUIDE.md`
   - Créer le projet
   - Télécharger google-services.json

2. **Placer google-services.json**
   ```bash
   # Le fichier doit être ici
   /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/android/app/google-services.json
   ```

3. **Vérifier build.gradle** (2 min)
   - Ouvrir `/android/build.gradle`
   - Vérifier les dépendances
   - Ouvrir `/android/app/build.gradle`
   - Ajouter `apply plugin: 'com.google.gms.google-services'` à la fin

4. **Installer les packages**
   ```bash
   flutter pub get
   ```

5. **Copier la Server Key**
   - La noter quelque part (vous en aurez besoin pour le backend)

### **APRÈS (Moi)** :

Une fois que vous avez fait les étapes ci-dessus et que vous me donnez la **Server Key**, je créerai :

1. ✅ Migration pour ajouter `fcm_token` dans la table `users`
2. ✅ Route backend `POST /api/auth/fcm-token`
3. ✅ Service `fcmService.js` pour envoyer les notifications
4. ✅ Intégration dans `notificationHelpers.js`

---

## 📞 SUPPORT

### **Si google-services.json not found** :

Vérifier que le fichier est bien ici :
```
/android/app/google-services.json  ✅
```

Et PAS ici :
```
/android/google-services.json      ❌
/google-services.json               ❌
```

### **Si Package name mismatch** :

Les package names doivent être IDENTIQUES dans :
1. `android/app/build.gradle` (applicationId)
2. Firebase Console (lors de l'ajout de l'app)
3. `google-services.json` (package_name)

---

**🎯 DITES-MOI QUAND VOUS AVEZ TERMINÉ LES ÉTAPES CI-DESSUS !**

Incluez dans votre réponse :
1. ✅ "google-services.json placé"
2. ✅ "build.gradle configuré"
3. ✅ "flutter pub get fait"
4. 🔑 La **Server Key** (commence par `AAAA...`)

Et je continuerai avec le backend ! 🚀
