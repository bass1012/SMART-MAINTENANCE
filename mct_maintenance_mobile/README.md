# MCT Maintenance Mobile

Application mobile Flutter pour la gestion de maintenance - Client & Technicien

## 🚀 Getting Started

### Prérequis
- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio / Xcode

### Installation
```bash
flutter pub get
flutter run
```

## 📚 Documentation Importante

### 🎨 Migration SnackBar (Novembre 2025)
Une migration complète des SnackBar est en cours pour améliorer l'UX avec un design moderne.

**📖 Point de départ :** [INDEX_DOCUMENTATION_SNACKBAR.md](./INDEX_DOCUMENTATION_SNACKBAR.md)

**Documents disponibles :**
- 📄 [RESUME_AMELIORATION_SNACKBAR.md](./RESUME_AMELIORATION_SNACKBAR.md) - Résumé exécutif
- 📘 [GUIDE_SNACKBAR_MIGRATION.md](./GUIDE_SNACKBAR_MIGRATION.md) - Guide complet
- ⚡ [SCRIPT_MIGRATION_SNACKBAR.md](./SCRIPT_MIGRATION_SNACKBAR.md) - Patterns rapides
- 📊 [RAPPORT_MIGRATION_SNACKBAR.md](./RAPPORT_MIGRATION_SNACKBAR.md) - État détaillé

**Helper disponible :**
```dart
import '../utils/snackbar_helper.dart';

SnackBarHelper.showSuccess(context, 'Opération réussie');
SnackBarHelper.showError(context, 'Une erreur est survenue');
SnackBarHelper.showLoading(context, 'Chargement...');
```

**Progression :** 6% (12/200+ SnackBar migrés)

## 🏗️ Structure du Projet

```
lib/
├── models/           # Modèles de données
├── screens/          # Écrans de l'application
│   ├── auth/        # Authentification
│   ├── customer/    # Écrans client
│   └── technician/  # Écrans technicien
├── services/        # Services (API, notifications, etc.)
├── utils/           # Utilitaires (helpers, constantes)
│   └── snackbar_helper.dart  # ✨ Nouveau helper SnackBar
└── widgets/         # Widgets réutilisables

```

## 🔧 Commandes Utiles

```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format lib/

# Lancer les tests
flutter test

# Build Android
flutter build apk

# Build iOS
flutter build ios
```

## 📖 Ressources Flutter

- [Documentation Flutter](https://docs.flutter.dev/)
- [Cookbook Flutter](https://docs.flutter.dev/cookbook)
- [API Reference](https://api.flutter.dev/)
