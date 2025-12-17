# Guide de Migration des SnackBar vers SnackBarHelper

## 📋 Vue d'ensemble

Un helper `SnackBarHelper` a été créé pour standardiser l'affichage des notifications SnackBar dans toute l'application avec un style moderne et cohérent.

## 🎨 Caractéristiques du nouveau style

- **Comportement floating** : SnackBar flottant au-dessus du contenu
- **Coins arrondis** : BorderRadius de 12px
- **Icônes contextuelles** : Chaque type de message a son icône
- **Émojis** : Ajout d'émojis pour une meilleure UX
- **Padding amélioré** : Meilleur espacement interne
- **Durée appropriée** : 3s pour succès/info, 4s pour erreurs

## 📦 Import

```dart
import '../utils/snackbar_helper.dart';
```

## 🔧 Utilisation

### Avant (ancien style)
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Opération réussie'),
    backgroundColor: Colors.green,
  ),
);
```

### Après (nouveau style avec helper)
```dart
SnackBarHelper.showSuccess(context, 'Opération réussie');
```

## 📚 Méthodes disponibles

### 1. ✅ Succès (vert)
```dart
SnackBarHelper.showSuccess(context, 'Profil mis à jour avec succès');

// Avec emoji personnalisé
SnackBarHelper.showSuccess(
  context, 
  'Profil mis à jour avec succès',
  emoji: '🎉',
);
```

### 2. ❌ Erreur (rouge)
```dart
SnackBarHelper.showError(context, 'Une erreur est survenue');

// Avec action
SnackBarHelper.showError(
  context,
  'Connexion échouée',
  action: SnackBarAction(
    label: 'Réessayer',
    textColor: Colors.white,
    onPressed: () => _retry(),
  ),
);
```

### 3. ℹ️ Information (bleu)
```dart
SnackBarHelper.showInfo(context, 'Téléchargement en cours');

// Avec emoji personnalisé
SnackBarHelper.showInfo(
  context,
  'Nouvelle fonctionnalité disponible',
  emoji: '🎁',
);
```

### 4. ⚠️ Avertissement (orange)
```dart
SnackBarHelper.showWarning(context, 'Veuillez vérifier vos informations');
```

### 5. 🔄 Chargement (bleu avec spinner)
```dart
SnackBarHelper.showLoading(context, 'Connexion en cours...');

// Avec durée personnalisée
SnackBarHelper.showLoading(
  context,
  'Envoi en cours...',
  duration: const Duration(seconds: 5),
);
```

### 6. 🎨 Personnalisé
```dart
SnackBarHelper.showCustom(
  context,
  message: 'Message personnalisé',
  icon: Icons.star,
  backgroundColor: Colors.purple,
  duration: const Duration(seconds: 5),
);
```

### 7. ❎ Cacher le SnackBar actuel
```dart
SnackBarHelper.hide(context);
```

## 🔄 Exemples de Migration

### Exemple 1: Login Success
**Avant:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Connexion réussie !'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);
```

**Après:**
```dart
SnackBarHelper.showSuccess(
  context,
  'Connexion réussie !',
  duration: const Duration(seconds: 2),
);
```

### Exemple 2: Error with Action
**Avant:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Erreur: $message'),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  ),
);
```

**Après:**
```dart
SnackBarHelper.showError(
  context,
  message,
  action: SnackBarAction(
    label: 'OK',
    textColor: Colors.white,
    onPressed: () => SnackBarHelper.hide(context),
  ),
);
```

### Exemple 3: Loading Indicator
**Avant:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white),
        ),
        SizedBox(width: 12),
        Text('Chargement...'),
      ],
    ),
    backgroundColor: Colors.blue,
    duration: Duration(seconds: 10),
  ),
);
```

**Après:**
```dart
SnackBarHelper.showLoading(context, 'Chargement...');
```

## 📊 État de Migration

### ✅ Complété
- ✅ availability_screen.dart (référence)
- ✅ login_form.dart
- ✅ register_form.dart
- ✅ forgot_password_screen.dart
- ✅ report_summary_screen.dart

### 🔄 En cours
Fichiers avec beaucoup de SnackBar à migrer progressivement:
- profile_screen.dart (16 SnackBar)
- settings_screen.dart (16 SnackBar)
- technician_settings_screen.dart (18 SnackBar)
- support_screen.dart (13 SnackBar)
- new_intervention_screen.dart (11 SnackBar)

### ⏳ À faire
Environ 150+ autres SnackBar dans l'application.

## 💡 Conseils

1. **Utilisez des émojis appropriés** : Ils améliorent la compréhension visuelle
2. **Durées adaptées** : 
   - Succès rapide : 2-3 secondes
   - Info : 3-4 secondes
   - Erreur : 4-5 secondes
   - Chargement : 10+ secondes
3. **Messages clairs** : Évitez les messages techniques, privilégiez le français
4. **Action pertinente** : Ajoutez des actions quand c'est utile (Réessayer, OK, etc.)

## 🎯 Avantages

- ✨ **Cohérence** : Style uniforme dans toute l'app
- 🔧 **Maintenabilité** : Un seul endroit pour modifier le style
- 📱 **UX améliorée** : Design moderne avec icônes et émojis
- ⚡ **Productivité** : Moins de code répétitif
- 🐛 **Moins d'erreurs** : API simple et claire

## 🚀 Prochaines étapes

1. Migrer progressivement tous les SnackBar vers le helper
2. Tester visuellement sur iOS et Android
3. Considérer l'ajout de sons/vibrations pour certains types
4. Documenter les cas d'usage spécifiques par écran

---

**Note**: Le helper est compatible avec tous les widgets existants et ne nécessite aucun changement de dépendances.
