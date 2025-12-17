# 🔥 Guide d'installation Firebase Cloud Messaging (FCM)

## 📋 ÉTAPE 1 : Configuration Firebase Console (5 min)

### **1.1 Créer/Accéder au projet Firebase**

1. Aller sur : https://console.firebase.google.com/
2. Cliquer sur **"Ajouter un projet"** (ou sélectionner existant)
3. Nom du projet : **MCT-Maintenance** (ou votre choix)
4. Désactiver Google Analytics (optionnel, pour aller plus vite)
5. Cliquer sur **"Créer le projet"**

---

### **1.2 Ajouter l'application Android**

1. Dans le projet Firebase, cliquer sur l'icône **Android** 📱
2. **Package name** : Vérifier dans `/android/app/build.gradle`
   ```
   Cherchez : applicationId "com.example.mct_maintenance_mobile"
   Utilisez cette valeur exactement !
   ```
3. **App nickname** : MCT Maintenance Mobile (optionnel)
4. **Debug signing certificate SHA-1** : Laisser vide pour l'instant
5. Cliquer sur **"Enregistrer l'application"**

---

### **1.3 Télécharger google-services.json**

1. Firebase vous propose de télécharger **google-services.json**
2. **Télécharger le fichier**
3. **Le placer ici** : 
   ```
   /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/android/app/google-services.json
   ```
4. ⚠️ **IMPORTANT** : Le fichier doit être dans `/android/app/` et PAS dans `/android/`

---

### **1.4 Récupérer la Server Key**

1. Dans Firebase Console, cliquer sur **⚙️ Project Settings**
2. Onglet **Cloud Messaging**
3. Chercher **Server key** (commence par `AAAA...`)
4. **Copier cette clé** (vous en aurez besoin pour le backend)
5. La sauvegarder quelque part (notepad, notes, etc.)

---

## 📱 ÉTAPE 2 : Vérifier le package name Flutter

### **2.1 Ouvrir le fichier build.gradle**

```bash
# Ouvrir ce fichier
/Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/android/app/build.gradle
```

### **2.2 Chercher applicationId**

```gradle
android {
    ...
    defaultConfig {
        applicationId "com.example.mct_maintenance_mobile"  ← Cette ligne !
        ...
    }
}
```

### **2.3 Utiliser ce MÊME package name dans Firebase**

⚠️ **CRITIQUE** : Le package name doit être IDENTIQUE entre :
- `android/app/build.gradle`
- Firebase Console
- `google-services.json`

---

## 🔑 ÉTAPE 3 : Server Key pour le backend

### **Où le mettre :**

Une fois que vous avez la Server Key :

```bash
# Ouvrir ce fichier
/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/.env
```

### **Ajouter cette ligne :**

```env
# Firebase Cloud Messaging
FCM_SERVER_KEY=AAAA....votre_clé_ici
```

---

## ✅ Checklist de configuration

- [ ] Projet Firebase créé
- [ ] Application Android ajoutée
- [ ] Package name correspond à build.gradle
- [ ] google-services.json téléchargé
- [ ] google-services.json placé dans `/android/app/`
- [ ] Server Key récupérée
- [ ] Server Key ajoutée dans `.env` du backend

---

## 🆘 Problèmes fréquents

### **Problème : "google-services.json not found"**

**Solution** : Vérifier que le fichier est bien ici :
```
/android/app/google-services.json
```

Et PAS ici :
```
/android/google-services.json  ❌
/google-services.json          ❌
```

---

### **Problème : "Package name mismatch"**

**Solution** : Les package names doivent être identiques dans :
1. `android/app/build.gradle` (applicationId)
2. Firebase Console (lors de l'ajout de l'app)
3. `google-services.json` (package_name)

---

## 📸 Screenshots de référence

### **Firebase Console - Ajouter une app**
```
[Vue du projet Firebase]
  └─ Project Overview
      └─ "Ajouter une application"
          └─ [Icône Android] ← Cliquer ici
```

### **Cloud Messaging - Server Key**
```
[Project Settings]
  └─ Cloud Messaging
      └─ Server key: AAAA... ← Copier ceci
```

---

**Une fois que vous avez fait ces étapes, dites-moi "Fait" et je continuerai avec le code !**
