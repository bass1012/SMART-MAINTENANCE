# 🚀 Quick Start - Notifications iOS

⚠️ **IMPORTANT : Compte Apple Developer requis (99$/an)**

**Vous n'avez PAS de compte payant ?**  
👉 Consultez : **`IOS_NOTIFICATIONS_FREE_DEV.md`** pour la solution gratuite de développement

---

## ⚡ Actions immédiates (5 minutes) - AVEC compte payant

### 1. Télécharger GoogleService-Info.plist

```
1. Aller sur: https://console.firebase.google.com
2. Projet: mct-maintenance-10748
3. ⚙️ → Project Settings → Your apps
4. Ajouter une app iOS
5. Bundle ID: com.remples.mctMaintenanceMobile
6. Télécharger GoogleService-Info.plist
```

### 2. Ajouter au projet

```bash
# Copier dans le projet
cp ~/Downloads/GoogleService-Info.plist ios/Runner/

# Ouvrir Xcode
open ios/Runner.xcworkspace

# Dans Xcode:
# - Clic droit sur "Runner" (dossier bleu)
# - "Add Files to Runner..."
# - Sélectionner GoogleService-Info.plist
# - Cocher "Copy items if needed"
# - Cocher Target "Runner"
# - Add
```

### 3. Créer clé APNs

```
1. Aller sur: https://developer.apple.com/account/resources/authkeys/list
2. Créer une nouvelle clé (+)
3. Nom: "MCT Maintenance APNs"
4. Cocher: Apple Push Notifications service (APNs)
5. Continue → Register → Download
6. NOTER le Key ID et Team ID
```

### 4. Uploader dans Firebase

```
1. Firebase Console → Project Settings → Cloud Messaging
2. Section "iOS app configuration"
3. Upload APNs Authentication Key
4. Uploader le fichier .p8
5. Entrer Key ID et Team ID
6. Upload
```

### 5. Installer les pods

```bash
cd ios
pod install
cd ..
```

### 6. Configurer Xcode

```bash
open ios/Runner.xcworkspace
```

**Dans Xcode:**
1. Sélectionner "Runner" (target)
2. Onglet "Signing & Capabilities"
3. Ajouter "Push Notifications" (+ Capability)
4. Ajouter "Background Modes" (+ Capability)
5. Cocher "Remote notifications"

### 7. Tester

```bash
# Sur appareil RÉEL uniquement
flutter run
```

**Vérifier les logs:**
```
✅ Permission de notification accordée
📱 FCM Token obtenu: ...
📱 APNs token enregistré
🔔 FCM Token iOS: ...
```

## ✅ Checklist rapide

- [ ] GoogleService-Info.plist téléchargé
- [ ] Fichier ajouté dans Xcode (bleu)
- [ ] Clé APNs créée
- [ ] Clé APNs uploadée dans Firebase
- [ ] `pod install` réussi
- [ ] Push Notifications activé
- [ ] Background Modes activé
- [ ] Test sur appareil réel OK

## 🐛 Erreurs communes

**"No such module 'Firebase'"**
```bash
cd ios && pod install && cd ..
open ios/Runner.xcworkspace  # PAS .xcodeproj !
```

**Token FCM null**
```bash
# Vérifier le fichier
ls ios/Runner/GoogleService-Info.plist
```

**Notifications ne marchent pas**
- ⚠️ Simulateur ne supporte PAS les push notifications
- ✅ Utiliser un appareil réel

## 📚 Documentation complète

Voir `IOS_NOTIFICATIONS_SETUP.md` pour:
- Guide détaillé complet
- Architecture des notifications
- Dépannage avancé
- Format des payloads
- Navigation depuis notifications
