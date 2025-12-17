# 🔐 Liens de navigation Login ↔ Register

## ✅ Modifications effectuées

### 1. Lien de création de compte sur le Login

**Fichier modifié :** `lib/widgets/auth/login_form.dart`

**Ajout :**
```dart
// Après le bouton "Se connecter"
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      'Pas encore de compte ?',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 14,
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/register');
      },
      child: const Text(
        'Créer un compte',
        style: TextStyle(
          color: Color(0xFF0a543d),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),
```

**Résultat :**
- ✅ Lien "Créer un compte" affiché sous le bouton de connexion
- ✅ Couleur verte MCT (#0a543d) pour le lien
- ✅ Navigation vers `/register`

### 2. Amélioration de l'écran d'inscription

**Fichier modifié :** `lib/screens/auth/register_screen.dart`

**Améliorations :**
- ✅ Ajout du logo Smart Maintenance (100x100)
- ✅ Titre "Créer un compte" en gros (28px)
- ✅ Sous-titre "Rejoignez Smart Maintenance"
- ✅ Design cohérent avec l'écran de login
- ✅ Fond vert clair (#e6ffe6)
- ✅ Card avec elevation pour le formulaire

**Avant :**
```
┌────────────────────────────────┐
│ ← Créer un compte              │ (AppBar)
├────────────────────────────────┤
│                                │
│    [Formulaire]                │
│                                │
└────────────────────────────────┘
```

**Après :**
```
┌────────────────────────────────┐
│                                │
│        [Logo 100x100]          │
│                                │
│      Créer un compte           │ (28px, gras)
│   Rejoignez Smart Maintenance  │ (14px, gris)
│                                │
│   ┌────────────────────────┐  │
│   │  [Formulaire]          │  │
│   │  - Nom complet         │  │
│   │  - Email               │  │
│   │  - Mot de passe        │  │
│   │  [Créer mon compte]    │  │
│   │  Déjà un compte ?      │  │
│   └────────────────────────┘  │
│                                │
└────────────────────────────────┘
```

### 3. Formulaire d'inscription existant

**Fichier :** `lib/widgets/auth/register_form.dart`

**Fonctionnalités déjà présentes :**
- ✅ Champ Nom complet (validation min 3 caractères)
- ✅ Champ Email (validation regex)
- ✅ Champ Mot de passe (validation min 6 caractères)
- ✅ Bouton "Créer mon compte"
- ✅ Lien "Déjà un compte ? Connectez-vous" (retour au login)
- ✅ Loader pendant la création
- ✅ Messages de succès/erreur
- ✅ Appel API `register` avec rôle 'client'

**API appelée :**
```dart
await api.register({
  'name': _nameController.text.trim(),
  'email': _emailController.text.trim().toLowerCase(),
  'password': _passwordController.text,
  'role': 'client',
});
```

## 🔄 Flux de navigation complet

### De Login → Register

```
Écran Login
  ↓
Clic sur "Créer un compte"
  ↓
Navigation: Navigator.pushNamed(context, '/register')
  ↓
Écran Register
```

### De Register → Login

**Méthode 1 : Après création réussie**
```
Écran Register
  ↓
Remplir formulaire + Clic "Créer mon compte"
  ↓
API: POST /api/auth/register
  ↓
Succès: SnackBar "Compte créé avec succès !"
  ↓
Délai 2 secondes
  ↓
Navigation: Navigator.pushReplacementNamed(context, '/login')
  ↓
Écran Login (avec message pour se connecter)
```

**Méthode 2 : Lien direct**
```
Écran Register
  ↓
Clic sur "Déjà un compte ? Connectez-vous"
  ↓
Navigation: Navigator.pushReplacementNamed(context, '/login')
  ↓
Écran Login
```

## 📱 Interface utilisateur

### Écran Login

```
┌─────────────────────────────────────┐
│                                     │
│        [Logo Smart Maintenance]     │
│                                     │
│      Smart Maintenance              │
│                                     │
│   ┌───────────────────────────┐    │
│   │  Email                    │    │
│   │  ───────────────────      │    │
│   │                           │    │
│   │  Mot de passe             │    │
│   │  ───────────────────      │    │
│   │                           │    │
│   │  [Se connecter]           │    │
│   │                           │    │
│   │  Pas encore de compte ?   │    │
│   │  [Créer un compte] ←NEW!  │    │
│   └───────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Écran Register

```
┌─────────────────────────────────────┐
│                                     │
│        [Logo Smart Maintenance]     │
│                                     │
│      Créer un compte                │
│  Rejoignez Smart Maintenance        │
│                                     │
│   ┌───────────────────────────┐    │
│   │  Nom complet              │    │
│   │  ───────────────────      │    │
│   │                           │    │
│   │  Email                    │    │
│   │  ───────────────────      │    │
│   │                           │    │
│   │  Mot de passe             │    │
│   │  ───────────────────      │    │
│   │                           │    │
│   │  [Créer mon compte]       │    │
│   │                           │    │
│   │  Déjà un compte ?         │    │
│   │  Connectez-vous           │    │
│   └───────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

## 🎨 Design cohérent

**Couleurs MCT :**
- Vert principal : `#0a543d`
- Fond clair : `#e6ffe6`
- Texte gris : `Colors.grey[600]`
- Liens : Vert MCT bold

**Typographie :**
- Police : Nunito Sans (Google Fonts)
- Titre principal : 32px (Login), 28px (Register)
- Sous-titre : 14px
- Liens : 14px bold

**Éléments communs :**
- Logo centré en haut
- Card avec elevation 4
- Border radius 16
- Padding 24
- Largeur max 350px

## 🧪 Tests à effectuer

### Test 1 : Navigation Login → Register

1. Lancer l'app : `flutter run`
2. Aller sur l'écran de login
3. Cliquer sur "Créer un compte"
4. ✅ Vérifier que l'écran Register s'affiche
5. ✅ Vérifier que le logo est visible
6. ✅ Vérifier que le formulaire est complet

### Test 2 : Création de compte

1. Sur l'écran Register
2. Remplir :
   - Nom : "Jean Dupont"
   - Email : "jean.dupont@test.com"
   - Mot de passe : "123456"
3. Cliquer sur "Créer mon compte"
4. ✅ Vérifier le loader
5. ✅ Vérifier le message de succès
6. ✅ Vérifier la redirection vers Login après 2s

### Test 3 : Navigation Register → Login

1. Sur l'écran Register
2. Cliquer sur "Déjà un compte ? Connectez-vous"
3. ✅ Vérifier le retour à l'écran Login

### Test 4 : Validation des champs

**Register - Nom :**
- Vide → "Veuillez entrer votre nom complet"
- "Jo" (2 car) → "Le nom doit contenir au moins 3 caractères"
- "John Doe" → ✅ Valid

**Register - Email :**
- Vide → "Veuillez entrer votre adresse email"
- "test" → "Veuillez entrer une adresse email valide"
- "test@example.com" → ✅ Valid

**Register - Mot de passe :**
- Vide → "Veuillez entrer un mot de passe"
- "12345" (5 car) → "Le mot de passe doit contenir au moins 6 caractères"
- "123456" → ✅ Valid

## 🔧 Configuration backend requise

**Endpoint d'inscription :**
```
POST /api/auth/register
```

**Body :**
```json
{
  "name": "Jean Dupont",
  "email": "jean.dupont@test.com",
  "password": "123456",
  "role": "client"
}
```

**Réponse attendue (succès) :**
```json
{
  "success": true,
  "message": "Utilisateur créé avec succès",
  "data": {
    "user": {
      "id": 123,
      "name": "Jean Dupont",
      "email": "jean.dupont@test.com",
      "role": "client"
    }
  }
}
```

**Réponse attendue (erreur) :**
```json
{
  "success": false,
  "message": "Cet email est déjà utilisé"
}
```

## 📊 Routes configurées

**Fichier :** `lib/core/app.dart`

```dart
routes: {
  '/': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(), // ← Route existante
  '/client': (context) => const CustomerMainScreen(),
  '/technician': (context) => const TechnicianMainScreen(),
  '/subscriptions': (context) => const SubscriptionsScreen(),
},
```

## ✅ Résultat final

**Login Screen :**
- ✅ Lien "Créer un compte" ajouté
- ✅ Style cohérent avec le design MCT
- ✅ Navigation fonctionnelle vers Register

**Register Screen :**
- ✅ Design amélioré avec logo et titre
- ✅ Formulaire complet et validé
- ✅ Lien de retour vers Login
- ✅ Création de compte fonctionnelle
- ✅ Redirection automatique après succès

**Flux complet :**
```
Login ←→ Register
  ↓
Création compte
  ↓
Retour Login
  ↓
Connexion
  ↓
App (Client ou Technicien)
```

## 🚀 Prochaines étapes possibles

1. **Mot de passe oublié :**
   - Ajouter un lien "Mot de passe oublié ?" sur Login
   - Créer un écran de réinitialisation

2. **Confirmation mot de passe :**
   - Ajouter un champ "Confirmer mot de passe" sur Register
   - Validation que les deux champs correspondent

3. **Numéro de téléphone :**
   - Ajouter un champ téléphone sur Register
   - Validation du format Côte d'Ivoire (+225)

4. **Conditions d'utilisation :**
   - Ajouter une checkbox "J'accepte les conditions"
   - Lien vers les CGU

5. **Avatar par défaut :**
   - Générer un avatar par défaut lors de la création
   - Permettre l'upload d'une photo de profil

## 📝 Notes

- Le rôle est automatiquement défini à "client" lors de l'inscription
- L'email est converti en minuscules automatiquement
- Le nom est trimé (espaces supprimés)
- Le formulaire est disabled pendant le loading
- Les erreurs sont affichées avec un SnackBar rouge
- Le succès est affiché avec un SnackBar vert

**Tout est prêt pour que les nouveaux clients puissent créer un compte ! 🎉**
