# Guide de Publication - MCT Maintenance Mobile

## 📋 Préparatifs Avant Publication

### 1. Configuration de l'Application

#### Vérifier les fichiers de configuration

**Android** (`android/app/build.gradle`):
```gradle
android {
    defaultConfig {
        applicationId "ci.mct.smartmaintenance"  // ID unique
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1        // Incrémenter à chaque mise à jour
        versionName "1.0.0"  // Version visible par les utilisateurs
    }
}
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleIdentifier</key>
<string>ci.mct.smartmaintenance</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 2. Icônes et Splash Screen

```bash
# Installer flutter_launcher_icons
flutter pub add flutter_launcher_icons --dev

# Ajouter dans pubspec.yaml:
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"  # 1024x1024 px

# Générer les icônes
flutter pub run flutter_launcher_icons
```

### 3. Permissions à Vérifier

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pour localiser les interventions</string>
<key>NSCameraUsageDescription</key>
<string>Pour scanner les QR codes et prendre des photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Pour sélectionner des photos</string>
```

### 4. Désactiver le Mode Debug

```dart
// lib/main.dart
void main() {
  // Désactiver les logs en production
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  runApp(MyApp());
}
```

### 5. Configuration Firebase (Notifications)

- `android/app/google-services.json` ✓
- `ios/Runner/GoogleService-Info.plist` ✓

---

## 🤖 Publication sur Google Play

### Étape 1: Créer un Compte Développeur

1. Aller sur https://play.google.com/console
2. Payer les frais uniques de **25$**
3. Compléter les informations de l'entreprise

### Étape 2: Générer la Clé de Signature

```bash
cd android

# Créer le keystore (une seule fois, CONSERVER PRÉCIEUSEMENT)
keytool -genkey -v -keystore mct-maintenance-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mct-maintenance \
  -storepass VOTRE_MOT_DE_PASSE \
  -keypass VOTRE_MOT_DE_PASSE
```

### Étape 3: Configurer la Signature

Créer `android/key.properties`:
```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=mct-maintenance
storeFile=../mct-maintenance-key.jks
```

Modifier `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Étape 4: Générer l'AAB (App Bundle)

```bash
cd mct_maintenance_mobile

# Nettoyer et construire
flutter clean
flutter pub get
flutter build appbundle --release

# Le fichier sera dans:
# build/app/outputs/bundle/release/app-release.aab
```

### Étape 5: Publier sur Google Play Console

1. Créer une nouvelle application
2. Remplir les informations:
   - **Nom**: Smart Maintenance
   - **Description courte**: Gestion de maintenance climatisation
   - **Description complète**: Détails des fonctionnalités
   - **Catégorie**: Outils / Entreprise
   - **Captures d'écran**: 2-8 pour téléphone, tablette
   - **Icône**: 512x512 px
   - **Image de fonctionnalité**: 1024x500 px
3. Politique de confidentialité (URL obligatoire)
4. Télécharger l'AAB dans Tests internes → Production

---

## 🍎 Publication sur App Store

### Étape 1: Créer un Compte Développeur Apple

1. Aller sur https://developer.apple.com
2. S'inscrire au Apple Developer Program (**99$/an**)
3. Attendre la validation (24-48h)

### Étape 2: Configurer Xcode

```bash
cd mct_maintenance_mobile/ios
pod install
open Runner.xcworkspace
```

Dans Xcode:
1. Sélectionner **Runner** → **Signing & Capabilities**
2. Sélectionner votre Team
3. Bundle Identifier: `ci.mct.smartmaintenance`
4. Cocher **Automatically manage signing**

### Étape 3: Générer l'Archive

```bash
# Nettoyer et construire
flutter clean
flutter pub get
flutter build ios --release

# Ouvrir Xcode
cd ios && open Runner.xcworkspace
```

Dans Xcode:
1. **Product** → **Archive**
2. Une fois archivé, **Distribute App**
3. Choisir **App Store Connect**
4. Upload

### Étape 4: App Store Connect

1. Aller sur https://appstoreconnect.apple.com
2. Créer une nouvelle app
3. Remplir:
   - **Nom**: Smart Maintenance
   - **SKU**: ci.mct.smartmaintenance
   - **Captures d'écran**: iPhone 6.5", 5.5", iPad
   - **Description**
   - **Mots-clés**
   - **URL de support**
   - **Politique de confidentialité**
4. Soumettre pour révision (1-7 jours)

---

## 🔄 Faciliter les Mises à Jour

### 1. Script de Déploiement Automatique

Créer `deploy.sh`:
```bash
#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Déploiement MCT Maintenance${NC}"

# Incrémenter la version
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo "Version actuelle: $VERSION"

# Build Android
echo -e "${GREEN}📱 Build Android...${NC}"
flutter clean
flutter pub get
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Android Build Success${NC}"
    echo "📁 build/app/outputs/bundle/release/app-release.aab"
else
    echo -e "${RED}❌ Android Build Failed${NC}"
    exit 1
fi

# Build iOS
echo -e "${GREEN}🍎 Build iOS...${NC}"
flutter build ios --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iOS Build Success${NC}"
    echo "Ouvrez Xcode pour archiver: cd ios && open Runner.xcworkspace"
else
    echo -e "${RED}❌ iOS Build Failed${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Builds terminés !${NC}"
```

### 2. Gestion des Versions

Dans `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# - MAJOR: Changements majeurs incompatibles
# - MINOR: Nouvelles fonctionnalités
# - PATCH: Corrections de bugs
# - BUILD_NUMBER: Incrémenter à chaque upload
```

Script pour incrémenter la version:
```bash
# increment_version.sh
#!/bin/bash
CURRENT=$(grep 'version:' pubspec.yaml | sed 's/version: //')
BUILD=$(echo $CURRENT | cut -d'+' -f2)
NEW_BUILD=$((BUILD + 1))
VERSION=$(echo $CURRENT | cut -d'+' -f1)
NEW_VERSION="$VERSION+$NEW_BUILD"

sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "Version mise à jour: $NEW_VERSION"
```

### 3. CodePush / Shorebird (Mises à jour sans Store)

Pour les mises à jour critiques sans passer par les stores:

```bash
# Installer Shorebird
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Initialiser
shorebird init

# Créer un release
shorebird release android
shorebird release ios

# Pousser un patch (mise à jour instantanée)
shorebird patch android
shorebird patch ios
```

### 4. Environnements (Dev/Staging/Prod)

Créer des fichiers d'environnement:

```dart
// lib/config/environment.dart
enum Environment { dev, staging, prod }

class AppConfig {
  static late Environment env;
  
  static String get apiUrl {
    switch (env) {
      case Environment.dev:
        return 'http://192.168.1.100:3000';
      case Environment.staging:
        return 'https://api.sandbox.mct.ci';
      case Environment.prod:
        return 'https://api.mct.ci';
    }
  }
}
```

Lancer avec:
```bash
flutter run --dart-define=ENV=prod
```

### 5. CI/CD avec GitHub Actions

Créer `.github/workflows/build.yml`:
```yaml
name: Build & Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: build/app/outputs/bundle/release/

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
```

---

## 📝 Checklist Pré-Publication

### Application
- [ ] Icône d'application (1024x1024)
- [ ] Splash screen
- [ ] Permissions correctement déclarées
- [ ] Mode debug désactivé
- [ ] API pointant vers production
- [ ] Firebase configuré (notifications)
- [ ] Gestion des erreurs (Crashlytics/Sentry)
- [ ] Tests sur différents appareils

### Google Play
- [ ] Compte développeur (25$)
- [ ] Keystore généré et sauvegardé
- [ ] Captures d'écran (téléphone + tablette)
- [ ] Description courte et longue
- [ ] Politique de confidentialité
- [ ] Catégorie sélectionnée

### App Store
- [ ] Compte Apple Developer (99$/an)
- [ ] Certificats et profils de provisioning
- [ ] Captures d'écran (tous formats iPhone/iPad)
- [ ] Description et mots-clés
- [ ] URL de support
- [ ] Politique de confidentialité
- [ ] Âge de l'application

---

## 🔐 Fichiers à Ne JAMAIS Commiter

Ajouter au `.gitignore`:
```
# Clés de signature
*.jks
*.keystore
key.properties
android/key.properties

# Configurations sensibles
.env
.env.production

# Google Services
google-services.json
GoogleService-Info.plist
```

**Sauvegarder séparément** (Google Drive sécurisé, etc.):
- `mct-maintenance-key.jks`
- `key.properties`
- Mot de passe du keystore

---

## 💡 Commandes Utiles

```bash
# Vérifier les dépendances obsolètes
flutter pub outdated

# Analyser le code
flutter analyze

# Tester
flutter test

# Générer l'APK (pour tests)
flutter build apk --release

# Générer l'AAB (pour Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```
