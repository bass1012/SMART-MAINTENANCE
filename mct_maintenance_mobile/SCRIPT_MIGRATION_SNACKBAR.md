# 🚀 Script de Migration Rapide - SnackBar vers SnackBarHelper

## 📋 Checklist par Fichier

Pour chaque fichier à migrer:

- [ ] 1. Ajouter l'import `import '../utils/snackbar_helper.dart';` (ajuster le chemin)
- [ ] 2. Remplacer tous les `ScaffoldMessenger.of(context).showSnackBar`
- [ ] 3. Tester le fichier: `flutter analyze lib/path/to/file.dart`
- [ ] 4. Vérifier visuellement dans l'app

---

## 🔄 Patterns de Remplacement Rapide

### 1. Success Simple
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Opération réussie'),
    backgroundColor: Colors.green,
  ),
);

// ✅ APRÈS
SnackBarHelper.showSuccess(context, 'Opération réussie');
```

### 2. Success avec Duration
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Profil mis à jour !'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);

// ✅ APRÈS
SnackBarHelper.showSuccess(
  context,
  'Profil mis à jour !',
  duration: const Duration(seconds: 2),
);
```

### 3. Success avec Emoji Existant
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('✅ Rapport soumis avec succès'),
    backgroundColor: Colors.green,
  ),
);

// ✅ APRÈS (enlever l'emoji du message, il est ajouté automatiquement)
SnackBarHelper.showSuccess(context, 'Rapport soumis avec succès');
// OU garder un emoji personnalisé:
SnackBarHelper.showSuccess(
  context,
  'Rapport soumis avec succès',
  emoji: '📄',
);
```

### 4. Error Simple
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Erreur: $message'),
    backgroundColor: Colors.red,
  ),
);

// ✅ APRÈS
SnackBarHelper.showError(context, message);
```

### 5. Error avec Action
```dart
// ❌ AVANT
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

// ✅ APRÈS
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

### 6. Warning (Orange)
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Maximum 5 photos autorisées'),
    backgroundColor: Colors.orange,
  ),
);

// ✅ APRÈS
SnackBarHelper.showWarning(context, 'Maximum 5 photos autorisées');
```

### 7. Info (Bleu)
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Téléchargement en cours...'),
    backgroundColor: Colors.blue,
  ),
);

// ✅ APRÈS
SnackBarHelper.showInfo(context, 'Téléchargement en cours...');
```

### 8. Loading avec Spinner
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 12),
        Text('Connexion en cours...'),
      ],
    ),
    backgroundColor: Colors.blue,
    duration: Duration(seconds: 10),
  ),
);

// ✅ APRÈS
SnackBarHelper.showLoading(context, 'Connexion en cours...');
```

### 9. Hide Current
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).hideCurrentSnackBar();

// ✅ APRÈS
SnackBarHelper.hide(context);
```

### 10. Custom (Couleur spéciale)
```dart
// ❌ AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('🌟 Fonctionnalité Premium'),
    backgroundColor: Colors.purple,
    duration: Duration(seconds: 4),
  ),
);

// ✅ APRÈS
SnackBarHelper.showCustom(
  context,
  message: '🌟 Fonctionnalité Premium',
  icon: Icons.star,
  backgroundColor: Colors.purple,
  duration: const Duration(seconds: 4),
);
```

---

## 📝 Exemples Réels Migrés

### Exemple 1: login_form.dart
```dart
// Ligne 36 - AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Connexion en cours...'),
    duration: Duration(seconds: 10),
    backgroundColor: Colors.blue,
  ),
);

// Ligne 36 - APRÈS
SnackBarHelper.showLoading(context, 'Connexion en cours...');
```

### Exemple 2: register_form.dart  
```dart
// Ligne 91 - AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Bienvenue ! Votre compte a été créé avec succès 🎉'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);

// Ligne 91 - APRÈS
SnackBarHelper.showSuccess(
  context,
  'Bienvenue ! Votre compte a été créé avec succès',
  emoji: '🎉',
  duration: const Duration(seconds: 2),
);
```

### Exemple 3: forgot_password_screen.dart
```dart
// Ligne 50 - AVANT
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      e.toString().replaceAll('Exception: ', ''),
      style: GoogleFonts.poppins(),
    ),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 4),
  ),
);

// Ligne 50 - APRÈS
SnackBarHelper.showError(
  context,
  e.toString().replaceAll('Exception: ', ''),
);
```

### Exemple 4: report_summary_screen.dart
```dart
// Ligne 34 - AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('✅ Rapport soumis avec succès au client et à l\'admin'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3),
  ),
);

// Ligne 34 - APRÈS
SnackBarHelper.showSuccess(
  context,
  'Rapport soumis avec succès au client et à l\'admin',
);
```

---

## 🎯 Cas Spéciaux

### Cas 1: Message avec Variable
```dart
// AVANT
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Email envoyé à ${_emailController.text}'),
    backgroundColor: Colors.green,
  ),
);

// APRÈS
SnackBarHelper.showSuccess(
  context,
  'Email envoyé à ${_emailController.text}',
  emoji: '📧',
);
```

### Cas 2: Condition dans le Message
```dart
// AVANT
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      _selectedImages.length >= _maxImages
          ? 'Maximum atteint'
          : 'Photo ajoutée'
    ),
    backgroundColor: _selectedImages.length >= _maxImages
        ? Colors.orange
        : Colors.green,
  ),
);

// APRÈS
if (_selectedImages.length >= _maxImages) {
  SnackBarHelper.showWarning(context, 'Maximum atteint');
} else {
  SnackBarHelper.showSuccess(context, 'Photo ajoutée', emoji: '📸');
}
```

### Cas 3: Try-Catch Pattern
```dart
// AVANT
try {
  // code...
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Succès'),
      backgroundColor: Colors.green,
    ),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur: $e'),
      backgroundColor: Colors.red,
    ),
  );
}

// APRÈS
try {
  // code...
  SnackBarHelper.showSuccess(context, 'Succès');
} catch (e) {
  SnackBarHelper.showError(context, e.toString());
}
```

### Cas 4: Permission Refusée
```dart
// AVANT
if (permission.isDenied) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Permission refusée'),
      backgroundColor: Colors.orange,
    ),
  );
}

// APRÈS
if (permission.isDenied) {
  SnackBarHelper.showWarning(context, 'Permission refusée');
}
```

### Cas 5: Localisation
```dart
// AVANT
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Localisation récupérée avec succès'),
    backgroundColor: Colors.green,
  ),
);

// APRÈS
SnackBarHelper.showSuccess(
  context,
  'Localisation récupérée avec succès',
  emoji: '📍',
);
```

---

## ⚡ Méthode de Migration Batch

### Approche Recommandée

1. **Ouvrir le fichier à migrer**
2. **Ajouter l'import en haut:**
   ```dart
   import '../utils/snackbar_helper.dart';
   // ou '../../utils/snackbar_helper.dart' selon la profondeur
   ```

3. **Utiliser Find & Replace avec Regex (VSCode):**
   
   **Rechercher (Regex activé):**
   ```regex
   ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(\s*content:\s*Text\('(.+?)'\),\s*backgroundColor:\s*Colors\.green,
   ```
   
   **Remplacer par:**
   ```
   SnackBarHelper.showSuccess(context, '$1',
   ```

4. **Ajuster manuellement:**
   - Emojis personnalisés
   - Actions sur les erreurs
   - Durées spécifiques
   - Cas spéciaux

5. **Tester:**
   ```bash
   flutter analyze lib/path/to/file.dart
   ```

---

## 📊 Templates par Type de Fichier

### Fichiers d'Authentification
- Loading: `showLoading(context, 'Connexion en cours...')`
- Success: `showSuccess(context, 'Connexion réussie !')`
- Error: `showError(context, message)`

### Fichiers de Profil
- Success: `showSuccess(context, 'Profil mis à jour', emoji: '✨')`
- Error: `showError(context, 'Mise à jour échouée')`
- Info: `showInfo(context, 'Modifications enregistrées')`

### Fichiers d'Intervention
- Success: `showSuccess(context, 'Intervention créée', emoji: '✅')`
- Warning: `showWarning(context, 'Date invalide')`
- Error: `showError(context, 'Création échouée')`

### Fichiers de Media (Photos)
- Success: `showSuccess(context, 'Photo ajoutée', emoji: '📸')`
- Warning: `showWarning(context, 'Maximum 5 photos')`
- Error: `showError(context, 'Erreur lors de l\'upload')`

### Fichiers de Localisation
- Success: `showSuccess(context, 'Position trouvée', emoji: '📍')`
- Warning: `showWarning(context, 'Service de localisation désactivé')`
- Error: `showError(context, 'Permission refusée')`

---

## ✅ Validation Finale

Après migration complète d'un fichier:

```bash
# 1. Analyser le fichier
flutter analyze lib/path/to/file.dart

# 2. Vérifier qu'il n'y a plus de ScaffoldMessenger.showSnackBar
grep "ScaffoldMessenger.of(context).showSnackBar" lib/path/to/file.dart
# Doit retourner: rien (ou uniquement des commentaires)

# 3. Vérifier que l'import est présent
grep "import.*snackbar_helper" lib/path/to/file.dart
# Doit retourner: import '../utils/snackbar_helper.dart';

# 4. Compiler et tester
flutter run
```

---

## 🎨 Émojis Recommandés par Contexte

| Contexte | Emoji | Utilisation |
|----------|-------|-------------|
| Authentification | 🔐 | Login/Register success |
| Email | 📧 | Email envoyé |
| Photo | 📸 | Photo prise/ajoutée |
| Localisation | 📍 | GPS trouvé |
| Document | 📄 | PDF généré/téléchargé |
| Paiement | 💳 | Paiement réussi |
| Notification | 🔔 | Notification reçue |
| Téléchargement | 📥 | Download terminé |
| Upload | 📤 | Upload réussi |
| Suppression | 🗑️ | Élément supprimé |
| Validation | ✅ | Action validée |
| Anniversaire | 🎉 | Compte créé, milestone |
| Paramètres | ⚙️ | Settings mis à jour |
| Calendrier | 📅 | RDV confirmé |
| Messagerie | 💬 | Message envoyé |

---

**Note:** Ce script est conçu pour accélérer la migration. Adapter selon les besoins spécifiques de chaque fichier.
