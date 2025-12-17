# 🔧 FIX : Problème Clavier Android (ImeTracker onCancelled)

## 📋 Symptômes

Quand on clique dans un champ de saisie, les logs Android affichent :

```
D/InsetsController: show(ime(), fromIme=false)
I/ImeTracker: onCancelled at PHASE_CLIENT_APPLY_ANIMATION
I/ImeTracker: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT
```

**Comportement :**
- Le clavier essaie de s'afficher
- L'animation est annulée
- Une nouvelle demande d'affichage est faite immédiatement
- Cycle qui se répète

**Impact :**
- ⚠️ Le clavier peut ne pas s'afficher
- ⚠️ Le clavier peut clignoter
- ⚠️ Expérience utilisateur dégradée

---

## 🔍 Cause

Le problème survient quand **plusieurs événements demandent l'affichage/masquage du clavier rapidement** :

1. TextField reçoit le focus → Demande d'affichage du clavier
2. Scaffold se redimensionne (`resizeToAvoidBottomInset: true`)
3. L'animation du clavier est annulée pendant le redimensionnement
4. Nouveau cycle démarre

**Conflit entre :**
- `windowSoftInputMode` (AndroidManifest)
- `resizeToAvoidBottomInset` (Scaffold Flutter)
- Multiple TextField focus changes

---

## ✅ Solutions

### **Solution 1 : Changer `windowSoftInputMode` (APPLIQUÉE)**

**Fichier :** `android/app/src/main/AndroidManifest.xml`

**Avant :**
```xml
android:windowSoftInputMode="adjustResize"
```

**Après :**
```xml
android:windowSoftInputMode="adjustPan"
```

**Différence :**
- **`adjustResize`** : L'écran se redimensionne quand le clavier apparaît
  - ✅ Meilleur pour les formulaires longs
  - ❌ Peut causer des animations conflictuelles
  
- **`adjustPan`** : L'écran se déplace (pan) sans redimensionnement
  - ✅ Pas de conflit d'animation
  - ❌ Certains éléments peuvent être masqués par le clavier

**Test :** Relancez l'app Android après cette modification.

---

### **Solution 2 : Désactiver `resizeToAvoidBottomInset`**

Si la solution 1 ne fonctionne pas, modifiez les Scaffold problématiques.

**Trouvez les écrans qui ont des TextField :**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
grep -r "resizeToAvoidBottomInset" lib/
```

**Modifiez les Scaffold :**

**Avant :**
```dart
Scaffold(
  resizeToAvoidBottomInset: true, // Par défaut
  body: ...
)
```

**Après :**
```dart
Scaffold(
  resizeToAvoidBottomInset: false, // Désactivé
  body: SingleChildScrollView( // Important pour le scroll manuel
    child: ...
  )
)
```

**⚠️ Important :** Enveloppez le body dans un `SingleChildScrollView` pour permettre le scroll manuel.

---

### **Solution 3 : Ajouter un Délai Entre les Focus**

Si vous avez plusieurs TextField qui changent de focus rapidement :

```dart
// Avant
FocusScope.of(context).requestFocus(_nextFocusNode);

// Après
Future.delayed(Duration(milliseconds: 100), () {
  FocusScope.of(context).requestFocus(_nextFocusNode);
});
```

---

### **Solution 4 : Utiliser `adjustNothing` (Dernier Recours)**

Si aucune solution ne fonctionne :

**`AndroidManifest.xml` :**
```xml
android:windowSoftInputMode="adjustNothing"
```

**Flutter :**
```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: SingleChildScrollView(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: ...
  )
)
```

---

## 🧪 Tests

### **Test 1 : Vérifier le Mode Actuel**

Après modification de `AndroidManifest.xml` :

1. **Arrêter l'app complètement** (ne pas juste hot reload)
2. **Rebuild et relancer** :
   ```bash
   flutter clean
   flutter run
   ```

3. **Cliquer dans un TextField**

4. **Vérifier les logs** :
   ```bash
   adb logcat | grep ImeTracker
   ```

**Résultat attendu :**
- ✅ Pas de `onCancelled at PHASE_CLIENT_APPLY_ANIMATION`
- ✅ Le clavier s'affiche normalement
- ✅ Pas de clignotement

---

### **Test 2 : Vérifier Différents Écrans**

Testez sur les écrans avec formulaires :

- [ ] **Login** (`/lib/widgets/auth/login_form.dart`)
- [ ] **Inscription** (`/lib/screens/register_screen.dart`)
- [ ] **Profil** (`/lib/screens/customer/profile_screen.dart`)
- [ ] **Support/Chat** (`/lib/screens/customer/support_screen.dart`)
- [ ] **Paiement** (`/lib/screens/customer/payment_screen.dart`)
- [ ] **Checkout** (`/lib/screens/customer/checkout_screen.dart`)

**Pour chaque écran :**
1. Cliquer dans le premier TextField
2. Cliquer dans le deuxième TextField
3. Utiliser le bouton "Suivant" du clavier (si disponible)

**Comportement attendu :**
- ✅ Le clavier s'affiche immédiatement
- ✅ Pas de clignotement
- ✅ Le contenu est visible (pas masqué par le clavier)

---

## 🔍 Diagnostic Avancé

### **Vérifier les Logs Complets**

```bash
# Logs ImeTracker uniquement
adb logcat | grep ImeTracker

# Logs InsetsController
adb logcat | grep InsetsController

# Logs complets de l'app
adb logcat | grep "mct_maintenance"
```

**Logs normaux (OK) :**
```
I/ImeTracker: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT
I/ImeTracker: onProgress at PHASE_CLIENT_APPLY_ANIMATION
I/ImeTracker: onShown
```

**Logs problématiques (KO) :**
```
I/ImeTracker: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT
I/ImeTracker: onCancelled at PHASE_CLIENT_APPLY_ANIMATION ❌
I/ImeTracker: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT (cycle)
```

---

### **Vérifier les Scaffold Problématiques**

Cherchez les Scaffold qui utilisent `resizeToAvoidBottomInset` :

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
grep -rn "resizeToAvoidBottomInset" lib/
```

**Si vous trouvez :**
```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: Column( // ❌ Mauvais avec Column
    children: [
      TextField(),
      TextField(),
    ]
  )
)
```

**Changez en :**
```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: SingleChildScrollView( // ✅ Bon avec ScrollView
    child: Column(
      children: [
        TextField(),
        TextField(),
      ]
    )
  )
)
```

---

## 📊 Comparaison des Modes

| Mode | Redimensionnement | Animations | Scroll | Recommandé |
|------|-------------------|------------|--------|------------|
| **adjustResize** | ✅ Oui | ⚠️ Peut conflit | ✅ Auto | Formulaires longs |
| **adjustPan** | ❌ Non | ✅ Fluide | ⚠️ Manuel | **RECOMMANDÉ** |
| **adjustNothing** | ❌ Non | ✅ Fluide | ❌ Manuel + Padding | Layouts complexes |

---

## 🎯 Solution Recommandée

### **Configuration Optimale**

**1. AndroidManifest.xml :**
```xml
<activity
    android:name=".MainActivity"
    android:windowSoftInputMode="adjustPan"
    ...>
```

**2. Scaffold Flutter (pour écrans avec formulaires) :**
```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Email'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Mot de passe'),
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          child: Text('Connexion'),
        ),
      ],
    ),
  ),
)
```

**3. Gestion du Focus (optionnel) :**
```dart
FocusNode _emailFocus = FocusNode();
FocusNode _passwordFocus = FocusNode();

TextField(
  focusNode: _emailFocus,
  textInputAction: TextInputAction.next,
  onSubmitted: (_) {
    FocusScope.of(context).requestFocus(_passwordFocus);
  },
)
```

---

## 🚨 Problèmes Connus

### **Problème 1 : Clavier cache les champs**

**Symptôme :** Le clavier masque le TextField actif

**Solution :**
```dart
Scaffold(
  resizeToAvoidBottomInset: true, // Activer
  body: SingleChildScrollView(
    reverse: true, // Scroll automatique vers le bas
    child: ...
  )
)
```

---

### **Problème 2 : Clavier ne se ferme pas**

**Symptôme :** Le clavier reste ouvert quand on clique ailleurs

**Solution :**
```dart
GestureDetector(
  onTap: () {
    FocusScope.of(context).unfocus(); // Fermer le clavier
  },
  child: Scaffold(
    body: ...
  )
)
```

---

### **Problème 3 : Performance dégradée**

**Symptôme :** Lag quand le clavier apparaît

**Solution :**
1. Désactiver les animations pendant l'affichage du clavier
2. Utiliser `const` pour les widgets statiques
3. Éviter les `setState()` pendant le focus change

```dart
TextField(
  onTap: () {
    // Pas de setState() ici
  },
  onChanged: (value) {
    // setState() OK ici
  },
)
```

---

## 📝 Checklist de Débogage

Avant de déclarer le problème résolu :

- [ ] `AndroidManifest.xml` modifié (`adjustPan`)
- [ ] App complètement fermée et relancée (`flutter clean && flutter run`)
- [ ] Logs vérifiés (pas de `onCancelled`)
- [ ] Testé sur écran de login
- [ ] Testé sur écran avec plusieurs TextField
- [ ] Testé le bouton "Suivant" du clavier
- [ ] Testé le scroll quand clavier ouvert
- [ ] Testé la fermeture du clavier (clic ailleurs)

---

## 📚 Ressources

**Documentation officielle :**
- [Android Manifest - windowSoftInputMode](https://developer.android.com/guide/topics/manifest/activity-element#wsoft)
- [Flutter Scaffold - resizeToAvoidBottomInset](https://api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomInset.html)

**Stack Overflow :**
- [ImeTracker onCancelled issues](https://stackoverflow.com/questions/tagged/android-keyboard)

---

## ✅ Résumé

**Problème :** Logs `ImeTracker: onCancelled at PHASE_CLIENT_APPLY_ANIMATION`

**Cause :** Conflit entre `adjustResize` et `resizeToAvoidBottomInset`

**Solution :** Changer `windowSoftInputMode` de `adjustResize` → `adjustPan`

**Fichier modifié :** `android/app/src/main/AndroidManifest.xml` (ligne 30)

**Test :**
```bash
flutter clean
flutter run
```

Puis cliquer dans un TextField → Pas de logs `onCancelled` ✅

---

**Prochaines étapes :**

1. ✅ Modification appliquée dans `AndroidManifest.xml`
2. 🔄 Relancer l'app : `flutter clean && flutter run`
3. 🧪 Tester en cliquant dans un champ de saisie
4. 📋 Vérifier les logs : `adb logcat | grep ImeTracker`

**Si le problème persiste :** Essayez les solutions 2, 3 ou 4 du guide.
