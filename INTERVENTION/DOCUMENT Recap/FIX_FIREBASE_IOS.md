# 🔧 Fix erreur Firebase iOS - Non-modular header

## ❌ Erreur rencontrée

```
Lexical or Preprocessor Issue (Xcode): Include of non-modular header inside framework module
'firebase_messaging.FLTFirebaseMessagingPlugin':
'/Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/ios/Pods/Headers/Public/Firebase/Firebase.h'
```

## 🎯 Solution complète

### Méthode 1: Configuration manuelle dans Xcode (RECOMMANDÉE)

1. **Ouvrir le projet dans Xcode:**
   ```bash
   cd mct_maintenance_mobile
   open ios/Runner.xcworkspace
   ```

2. **Dans Xcode:**
   - Cliquer sur **Runner** (icône bleue en haut à gauche)
   - Sélectionner **Runner** sous TARGETS
   - Onglet **Build Settings**
   - Chercher: `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`
   - Définir à: **Yes**

3. **Appliquer à toutes les configurations:**
   - Debug: **Yes**
   - Release: **Yes**
   - Profile: **Yes**

4. **Nettoyer et rebuild:**
   ```bash
   # Dans le terminal
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

### Méthode 2: Via commande (Alternative)

```bash
# Dans le dossier du projet Flutter
cd mct_maintenance_mobile

# Ajouter le build setting
/usr/libexec/PlistBuddy -c "Set :objects:97C147031CF9000F007C117D:buildSettings:CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES YES" ios/Runner.xcodeproj/project.pbxproj

# Nettoyer et rebuild
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter run
```

### Méthode 3: Modification directe du Podfile (Déjà appliquée)

Le fichier `ios/Podfile` a déjà été modifié avec:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix pour Firebase - Permettre les imports non-modulaires
    target.build_configurations.each do |config|
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
end
```

**⚠️ IMPORTANT:** Ce fix s'applique aux Pods seulement, pas au projet Runner principal. Il faut AUSSI configurer dans Xcode (Méthode 1).

## 📋 Checklist de vérification

Après avoir appliqué le fix:

- [ ] Le Podfile contient le post_install avec CLANG_ALLOW_NON_MODULAR_INCLUDES
- [ ] Dans Xcode, Runner → Build Settings → CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = Yes
- [ ] `flutter clean` exécuté
- [ ] `pod install` exécuté
- [ ] Build réussi sans erreur

## 🔍 Vérification du build setting

Pour vérifier si le setting est appliqué:

```bash
# Extraire les build settings
xcodebuild -project ios/Runner.xcodeproj -target Runner -showBuildSettings | grep CLANG_ALLOW_NON_MODULAR
```

**Résultat attendu:**
```
CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES
```

## 🚀 Procédure de build complète

```bash
# 1. Nettoyer
flutter clean
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*
cd ..

# 2. Installer les dépendances
flutter pub get
cd ios && pod install && cd ..

# 3. Ouvrir Xcode et configurer manuellement
open ios/Runner.xcworkspace
# → Runner → Build Settings → CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = Yes

# 4. Build depuis le terminal
flutter run -d <device_id>
```

## 📱 Build pour différentes cibles

### Simulateur iOS
```bash
flutter run -d "iPhone 16e"
```

### Device physique
```bash
flutter run -d "iPhone de User"
```

### Android (pas affecté)
```bash
flutter run -d emulator-5554
```

## ⚠️ Problèmes connus

### 1. Le setting ne persiste pas après pod install

**Cause:** CocoaPods peut réinitialiser certains build settings.

**Solution:** 
- Toujours vérifier après `pod install`
- Réappliquer si nécessaire via Xcode

### 2. L'erreur persiste malgré le fix

**Solutions:**
1. Supprimer DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

2. Nettoyer complètement Xcode:
   - Xcode → Product → Clean Build Folder (⇧⌘K)

3. Redémarrer Xcode

### 3. Firebase obsolète

Si le problème persiste, envisager de mettre à jour Firebase:

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
```

Puis:
```bash
flutter pub upgrade
cd ios && pod install --repo-update && cd ..
```

## 🔧 Alternative: Désactiver temporairement Firebase Messaging

Si vous voulez tester l'app sans notifications:

1. **Commenter dans `pubspec.yaml`:**
   ```yaml
   # firebase_messaging: ^14.7.10
   ```

2. **Commenter dans `main.dart`:**
   ```dart
   // import 'package:firebase_messaging/firebase_messaging.dart';
   // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
   ```

3. **Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## ✅ Solution rapide (TL;DR)

```bash
# 1. Ouvrir Xcode
open ios/Runner.xcworkspace

# 2. Dans Xcode:
# Runner → Build Settings → Chercher "CLANG_ALLOW_NON_MODULAR"
# Mettre à "Yes"

# 3. Nettoyer et rebuild
flutter clean
flutter run
```

## 📚 Références

- [Flutter Firebase setup](https://firebase.flutter.dev/docs/overview)
- [CocoaPods troubleshooting](https://guides.cocoapods.org/using/troubleshooting.html)
- [Xcode build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference)

---

**Cette erreur est causée par un conflit entre les modules Firebase et le système de modules Clang d'Apple. Le fix autorise les includes non-modulaires dans les frameworks, ce qui est sûr et recommandé par Firebase.**
