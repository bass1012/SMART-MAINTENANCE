# 🔐 Ajouter un compte Apple ID dans Xcode - Guide détaillé

## Méthode 1: Directement depuis le projet (LA PLUS SIMPLE)

### ✅ Étapes

1. **Ouvrir le workspace**
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
   open ios/Runner.xcworkspace
   ```

2. **Dans Xcode, à gauche :**
   - Cliquer sur l'icône **Runner** (toute en haut, icône bleue de dossier)
   - Vous verrez 2 sections : PROJECT et TARGETS
   - Sous **TARGETS**, cliquer sur **Runner**

3. **En haut, sélectionner l'onglet "Signing & Capabilities"**

4. **Cocher la case : ✅ Automatically manage signing**

5. **Menu déroulant "Team" :**
   
   **Option A:** Si vous voyez votre nom/email
   - Sélectionnez-le directement
   - ✅ Terminé !
   
   **Option B:** Si vous voyez "None" ou rien
   - Cliquer sur le menu "Team"
   - En bas de la liste : **"Add an Account..."**
   - Cliquer dessus

6. **Fenêtre "Add Account" s'ouvre :**
   - Type : Sélectionner **Apple ID**
   - Cliquer **Continue**
   
7. **Se connecter :**
   - Email : Votre Apple ID (iCloud)
   - Mot de passe : Votre mot de passe iCloud
   - Cliquer **Next**
   
8. **Authentification à deux facteurs (si activée) :**
   - Entrer le code reçu sur votre iPhone
   - Cliquer **Continue**

9. **Retour au projet :**
   - Le compte apparaît maintenant dans "Team"
   - Xcode génère automatiquement le profil
   - ✅ Configuration terminée !

## Méthode 2: Via les Settings Xcode

### Si vous voulez ajouter le compte en premier

1. **Menu Xcode (en haut de l'écran Mac)**
   - Cliquer sur **Xcode** (à côté du logo Apple)
   - Choisir **Settings...** (ou **Preferences...** sur anciennes versions)
   - Raccourci clavier : **Cmd + ,** (virgule)

2. **Fenêtre Settings s'ouvre**
   - En haut : plusieurs onglets
   - Cliquer sur **Accounts** (2ème onglet)

3. **Dans la fenêtre Accounts :**
   
   **À GAUCHE :** Liste des comptes (peut être vide)
   
   **EN BAS À GAUCHE :** Trois boutons
   - **[+]** ← Ajouter un compte
   - **[-]** ← Supprimer
   - **[⚙️]** ← Gérer
   
4. **Cliquer sur le bouton [+]**
   
   **Si vous ne voyez PAS le bouton [+] :**
   - Agrandissez la fenêtre (elle est peut-être trop petite)
   - Tirez sur les bords pour l'agrandir
   - Les boutons devraient apparaître

5. **Menu apparaît : "Add Account"**
   - Choisir **Apple ID**
   - Cliquer **Continue**

6. **Connexion :**
   - Entrer votre Apple ID
   - Entrer votre mot de passe
   - Code 2FA si nécessaire
   - **Sign In**

7. **Vérification :**
   - Votre compte apparaît dans la liste de gauche
   - À droite : "Personal Team" ou votre nom
   - ✅ Terminé !

8. **Fermer Settings**
   - Retourner au projet
   - Sélectionner ce compte dans "Team"

## Méthode 3: Si les boutons sont cachés

### Agrandir la fenêtre Settings

**Si vous ne voyez pas les boutons [+] [-] [⚙️] :**

1. La fenêtre est probablement trop petite
2. **Tirez sur les bords** de la fenêtre Settings
3. Agrandissez-la en largeur ET en hauteur
4. Les boutons devraient apparaître en bas à gauche

**Position des boutons :**
```
┌────────────────────────────────────────┐
│  Settings - Accounts                   │
├────────────────────────────────────────┤
│  Onglets: General [Accounts] ...       │
│                                        │
│  ┌──────────┐  ┌──────────────────┐  │
│  │          │  │                  │  │
│  │          │  │  Account Details │  │
│  │ Comptes  │  │                  │  │
│  │ (liste)  │  │                  │  │
│  │          │  │                  │  │
│  │          │  │                  │  │
│  │          │  │                  │  │
│  │          │  │                  │  │
│  │          │  │                  │  │
│  │          │  │                  │  │
│  └──────────┘  └──────────────────┘  │
│  [+] [-] [⚙️]  ← ICI (tout en bas)    │
└────────────────────────────────────────┘
```

## Méthode 4: Vérifier version de Xcode

### Versions et différences d'interface

```bash
# Vérifier la version
xcodebuild -version
```

**Xcode 15+ (2023+) :**
- Settings au lieu de Preferences
- Bouton [+] en bas à gauche
- Interface modernisée

**Xcode 14 (2022) :**
- Preferences
- Bouton [+] en bas à gauche

**Xcode 13 et moins (2021-) :**
- Preferences
- Bouton [+] plus visible
- Interface classique

### Si version très ancienne

**Mettre à jour Xcode (RECOMMANDÉ) :**

1. Ouvrir **App Store**
2. Chercher "Xcode"
3. Cliquer sur **Update** ou **Get**
4. Attendre le téléchargement (peut prendre 1h+, fichier de 10+ GB)

## Méthode 5: Ligne de commande (Alternative)

### Si vraiment l'interface ne marche pas

**Vous pouvez configurer le signing via la ligne de commande :**

```bash
# Vérifier les identités disponibles
security find-identity -v -p codesigning

# Lister les profils
security find-certificate -c "Apple Development" -a

# Si rien n'apparaît, Xcode doit créer le profil
# Retournez dans Xcode et suivez Méthode 1
```

## 🐛 Problèmes courants

### Problème 1: "Le bouton [+] n'existe pas"

**Solutions :**
1. Agrandir la fenêtre Settings
2. Vérifier que vous êtes bien dans l'onglet "Accounts"
3. Essayer la **Méthode 1** (directement depuis le projet)

### Problème 2: "Je ne peux pas me connecter"

**Causes possibles :**
- Mauvais Apple ID / mot de passe
- Authentification à 2 facteurs requise
- Connexion internet coupée
- Serveurs Apple temporairement indisponibles

**Solutions :**
1. Vérifier vos identifiants sur iCloud.com
2. Accepter le code 2FA sur votre iPhone
3. Vérifier votre connexion internet
4. Réessayer dans quelques minutes

### Problème 3: "Le compte n'apparaît pas après ajout"

**Solution :**
1. Fermer et rouvrir Xcode
2. Vérifier dans Settings → Accounts
3. Si toujours absent : réessayer l'ajout

### Problème 4: "Team = None, impossible de sélectionner"

**Solution :**
1. Le compte n'est pas ajouté correctement
2. Retourner dans Settings → Accounts
3. Vérifier que le compte existe
4. Si non : suivre Méthode 2
5. Si oui : fermer/rouvrir Xcode

## ✅ Vérification finale

### Comment savoir si ça a marché ?

**Dans le projet Runner → Signing & Capabilities :**

✅ **Bon signe :**
```
Automatically manage signing: ✅
Team: Votre Nom (Personal Team)
Signing Certificate: Apple Development
Provisioning Profile: iOS Team Provisioning Profile: *
Status: [Aucun message d'erreur]
```

❌ **Mauvais signe :**
```
Team: None
Status: ⚠️ Signing for "Runner" requires a development team
```

### Si tout est OK

**Vous devriez voir :**
- Bundle Identifier : com.bassoued.mctMaintenanceMobile
- Team : Votre nom
- Signing Certificate : Apple Development
- Pas de message d'erreur rouge ou jaune

**✅ Passez à l'étape suivante : Ajouter les Capabilities**

## 📸 Capture d'écran (description)

### Fenêtre Settings → Accounts

```
┌────────────────────────────────────────────────────────┐
│  Settings                                         [X]   │
├────────────────────────────────────────────────────────┤
│  [General] [Accounts] [Behaviors] [Navigation] ...     │
│                                                        │
│  ┌─────────────────────┐  ┌─────────────────────────┐ │
│  │ Apple IDs           │  │ votre@email.com         │ │
│  │ ─────────────       │  │ ───────────────────────  │ │
│  │ votre@email.com ←   │  │ Apple ID Account        │ │
│  │                     │  │ Personal Team           │ │
│  │                     │  │                         │ │
│  │                     │  │ Name: Votre Nom         │ │
│  │                     │  │ Type: User              │ │
│  │                     │  │                         │ │
│  │                     │  │ [Manage Certificates...]│ │
│  │                     │  │ [Download Manual        │ │
│  │                     │  │  Profiles...]           │ │
│  └─────────────────────┘  └─────────────────────────┘ │
│                                                        │
│  [+] [-] [⚙️]  ← BOUTONS ICI (en bas à gauche)         │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## 🎯 Résumé ultra-rapide

**Si vous êtes perdu, suivez juste ça :**

1. `open ios/Runner.xcworkspace`
2. Cliquer Runner (icône bleue) → target Runner → Signing & Capabilities
3. Cocher "Automatically manage signing"
4. Team → "Add an Account..." → Apple ID → Se connecter
5. Terminé !

**Pas besoin de passer par Settings → Accounts !**

## 💡 Conseil

**La Méthode 1 (directement depuis le projet) est LA PLUS SIMPLE.**

Vous n'avez PAS besoin d'aller dans Settings → Accounts si vous ajoutez le compte directement depuis le menu "Team" du projet.

**C'est exactement le même résultat !**
