# 🔍 Diagnostic - 0 Tests Exécutés

## Problème Rencontré

```
Test summary:
📝 Total: 0
✅ Successful: 0
❌ Failed: 0
```

La compilation réussit mais **aucun test n'est exécuté**.

## Causes Possibles

### 1. Backend API Non Démarré ⚠️

**LE PLUS PROBABLE !**

Les tests essaient de se connecter mais le backend n'est pas accessible.

**Solution :**
```bash
# Terminal 1 - Démarrer le backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Vérifier que le backend répond
curl http://localhost:3000/health
```

### 2. L'App Crash au Démarrage

**Symptôme :** L'app se lance mais crash immédiatement.

**Diagnostic :**
```bash
# Voir les logs Flutter en temps réel
flutter logs

# Ou via ADB pour Android
adb logcat | grep flutter
```

**Causes courantes :**
- Firebase mal configuré
- API endpoint incorrect
- Permission manquante

### 3. Tests Non Configurés Correctement

**Vérifications :**

```bash
cd mct_maintenance_mobile

# Vérifier que les tests compilent
flutter analyze integration_test/

# Vérifier la structure
ls -la integration_test/
```

Devrait afficher :
```
app_test.dart
simple_test.dart
```

### 4. Device/Émulateur Non Prêt

**Vérifier :**
```bash
flutter devices
```

Devrait afficher votre émulateur.

## Solution Étape par Étape

### Étape 1 : Démarrer le Backend

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

Vous devriez voir :
```
✅ Serveur démarré sur http://localhost:3000
```

### Étape 2 : Vérifier l'Émulateur

```bash
# Lister les devices
flutter devices

# Si aucun device, démarrer l'émulateur
emulator -avd Pixel_8_API_34
```

### Étape 3 : Tester Manuellement l'App

```bash
cd mct_maintenance_mobile
flutter run -d emulator-5554
```

**Vérifier :**
- L'app se lance sans crash
- L'écran de login s'affiche
- Vous pouvez taper dans les champs

Si ça marche → Les tests devraient fonctionner !

### Étape 4 : Lancer un Test Simple

```bash
./test_simple.sh
```

Ou :
```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
patrol test \
  --target integration_test/simple_test.dart \
  --device emulator-5554 \
  --verbose
```

### Étape 5 : Si Toujours 0 Tests

Vérifier les logs détaillés :

```bash
patrol test \
  --target integration_test/app_test.dart \
  --device emulator-5554 \
  --verbose \
  --show-flutter-logs
```

Regarder dans la sortie :
- ✅ "Running test: Test 1..." → Le test démarre
- ❌ "Connection refused" → Backend pas démarré
- ❌ "Widget not found" → Keys manquantes
- ❌ App crash → Erreur dans l'app

## Commandes de Debug Utiles

### Voir les Logs Flutter

```bash
# Terminal séparé
flutter logs
```

### Voir les Logs Android (ADB)

```bash
adb logcat | grep -E "flutter|MCT"
```

### Nettoyer et Rebuild

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Tester l'API Manuellement

```bash
# Health check
curl http://localhost:3000/health

# Login test
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"client@test.com","password":"Test123!"}'
```

## Checklist Complète

Avant de lancer les tests, vérifier :

- [ ] Backend API démarré sur port 3000
- [ ] Émulateur/Device connecté et prêt
- [ ] App se lance manuellement sans crash
- [ ] Écran de login s'affiche correctement
- [ ] Utilisateurs de test existent dans la DB
- [ ] Les test keys sont bien dans les widgets
- [ ] `flutter analyze` ne montre pas d'erreurs critiques

## Tests de Vérification Rapides

### 1. Test Backend

```bash
curl http://localhost:3000/health
# Doit retourner : {"status":"ok"}
```

### 2. Test Émulateur

```bash
flutter devices
# Doit montrer : emulator-5554
```

### 3. Test App Manuelle

```bash
flutter run -d emulator-5554
# L'app doit se lancer
```

### 4. Test Compilation

```bash
flutter build apk --debug
# Doit compiler sans erreur
```

## Si Tout Échoue

### Option 1 : Tests Unitaires d'Abord

Commencez par des tests plus simples :

```bash
flutter test test/
```

### Option 2 : Test Manuel Guidé

1. Lancer l'app manuellement
2. Suivre les étapes du test à la main
3. Noter où ça bloque
4. Corriger ce point précis

### Option 3 : Vérifier la Configuration Patrol

```bash
patrol doctor
```

Doit montrer :
- ✅ Flutter installé
- ✅ ADB trouvé
- ✅ Versions compatibles

## Logs à Chercher

### Backend Logs

```
✅ Server is running on port 3000
✅ Connected to database
❌ Connection refused → Backend pas démarré !
```

### Flutter Logs

```
✅ Launching lib/main.dart on sdk gphone16k arm64
✅ Built build/app/outputs/flutter-apk/app-debug.apk
❌ EXCEPTION: Connection refused → API pas accessible
❌ Widget not found: emailField → Keys manquantes
```

### Patrol Logs

```
✅ Running test: Test Connexion Client
✅ Found widget: emailField
❌ Test failed: Timeout → App freeze ou crash
```

## Contact/Support

Si le problème persiste :

1. Copier les logs complets
2. Noter les erreurs exactes
3. Vérifier la compatibilité des versions :
   - Flutter: 3.38.4
   - Patrol: 3.20.0
   - Patrol CLI: 3.11.0

---

**Créé le :** 15 Décembre 2025  
**Dernière mise à jour :** 15 Décembre 2025
