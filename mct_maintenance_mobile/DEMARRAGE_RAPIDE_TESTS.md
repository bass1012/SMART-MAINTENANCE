# 🚀 Démarrage Rapide - Tests E2E

## ⚡ Étapes Simples

### 1. Premier Lancement (Configuration Automatique)

```bash
cd mct_maintenance_mobile
./run_tests.sh
```

Le script va automatiquement :
- ✅ Ajouter `patrol` au PATH
- ✅ Vérifier l'installation de Patrol CLI
- ✅ Afficher le menu des tests

### 2. Choisir un Test

Menu interactif :
```
1) 🚀 Exécuter TOUS les tests (6 tests)
2) 🔐 Test Connexion Client
3) 🔧 Test Création Intervention
4) 🛒 Test Achat Boutique
5) 👨‍🔧 Test Workflow Technicien
6) 📱 Test Permissions Natives
7) 🔔 Test Notifications
8) 📊 Rapport de Couverture
9) 🎥 Exécuter avec Vidéo
10) 🐛 Mode Debug (Verbose)
```

### 3. Prérequis pour Exécuter les Tests

#### Backend API (IMPORTANT !)
```bash
# Terminal 1 - Démarrer le backend
cd mct-maintenance-api
npm start
```

Le backend doit tourner sur `http://localhost:3000`

#### Utilisateurs de Test

Assurez-vous d'avoir ces comptes :

**Client :**
- Email : `client@test.com`
- Mot de passe : `Test123!`

**Technicien :**
- Email : `technicien@test.com`
- Mot de passe : `Test123!`

#### Device/Émulateur

```bash
# Lister les devices disponibles
flutter devices

# Démarrer un émulateur Android
emulator -avd Pixel_8_API_34

# Ou iOS Simulator
open -a Simulator
```

---

## 🎯 Tests Recommandés pour Commencer

### Test 1 : Connexion Client (Simple)

```bash
./run_tests.sh
# Choisir option 2
```

**Durée :** ~10 secondes  
**Ce qui est testé :**
- Saisie email/mot de passe
- Clic sur bouton connexion
- Navigation vers dashboard client

### Test 2 : Création Intervention (Complet)

```bash
./run_tests.sh
# Choisir option 3
```

**Durée :** ~15 secondes  
**Ce qui est testé :**
- Tout le formulaire d'intervention
- Sélection de date/heure
- Type, priorité, équipements
- Soumission

---

## 🐛 Résolution des Problèmes

### Problème : `patrol: command not found`

**Solution :**
```bash
# Ajouter à votre ~/.zshrc ou ~/.bash_profile
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Puis recharger
source ~/.zshrc  # ou source ~/.bash_profile
```

### Problème : "Backend API not responding"

**Solution :**
```bash
# Vérifier que le backend tourne
curl http://localhost:3000/health

# Si non, démarrer :
cd mct-maintenance-api && npm start
```

### Problème : "Widget with key not found"

**Cause :** Les test keys ne sont pas encore ajoutées aux widgets

**Solution :** Vérifier que le fichier contient bien :
```dart
import '../../utils/test_keys.dart';

// Et dans le widget :
TextField(
  key: const ValueKey(TestKeys.emailField),
  // ...
)
```

### Problème : Incompatibilité de Version

**Erreur :**
```
Version incompatibility detected! 
patrol_cli 4.0.1 is not compatible with patrol 3.20.0
```

**Solution :**
```bash
dart pub global activate patrol_cli 3.11.0
```

---

## 📊 Interpréter les Résultats

### ✅ Test Réussi
```
✓ Test Connexion Client (10.2s)
```

### ❌ Test Échoué
```
✗ Test Connexion Client (3.1s)
  Expected: finds one widget
  Actual: found 0 widgets
```

**Actions :**
1. Vérifier les logs Flutter : `flutter logs`
2. Exécuter en mode debug : Option 10 du menu
3. Vérifier que les test keys existent dans le widget

---

## 🎥 Enregistrement Vidéo des Tests

Pour débugger visuellement :

```bash
./run_tests.sh
# Choisir option 9
```

Vidéos sauvegardées dans : `build/patrol_videos/`

---

## ⚙️ Configuration Avancée

### Exécuter en Mode Release

```bash
patrol test --release --target integration_test/app_test.dart
```

### Exécuter sur Device Physique

```bash
# iOS
patrol test --device <device-id> --target integration_test/app_test.dart

# Android
patrol test --device <device-id> --target integration_test/app_test.dart
```

### Générer Rapport de Couverture

```bash
./run_tests.sh
# Choisir option 8
```

---

## 📝 Commandes Utiles

```bash
# Vérifier installation Patrol
patrol doctor

# Lister les tests disponibles
patrol test --list

# Exécuter un test spécifique
patrol test --target integration_test/app_test.dart --name "Connexion Client"

# Mode verbose
patrol test --verbose --target integration_test/app_test.dart

# Avec logs Flutter
patrol test --target integration_test/app_test.dart --dart-define=FLUTTER_LOG=true
```

---

## 🎯 Objectif des Tests

| Test | Durée | Couverture |
|------|-------|------------|
| Connexion Client | ~10s | Login flow |
| Création Intervention | ~15s | Formulaire complet |
| Achat Boutique | ~20s | E-commerce flow |
| Workflow Technicien | ~25s | Accept → Complete → Report |
| Permissions Natives | ~12s | Location, Camera |
| Notifications Push | ~15s | FCM handling |

**Total :** ~100 secondes pour tous les tests

---

## 💡 Tips

1. **Toujours démarrer le backend avant les tests**
2. **Utiliser un émulateur dédié aux tests** (pas votre device perso)
3. **Mode debug (option 10)** pour voir chaque étape
4. **Vidéo (option 9)** quand un test échoue mystérieusement
5. **Rapport couverture (option 8)** pour voir ce qui reste à tester

---

## 📚 Documentation Complète

Pour plus de détails, voir :
- `GUIDE_TESTS_E2E_PATROL.md` - Guide technique complet
- `lib/utils/test_keys_examples.dart` - Exemples d'ajout de keys
- `SETUP_TESTS_E2E_COMPLETE.md` - Setup détaillé

---

**Créé le :** 15 Décembre 2025  
**Version :** 1.0.0
