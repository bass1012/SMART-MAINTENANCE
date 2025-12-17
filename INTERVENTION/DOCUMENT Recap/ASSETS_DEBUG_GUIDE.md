# Guide de débogage - Assets ne s'affichent pas

## 🔍 Diagnostic du problème

### Vérifications effectuées:
✅ **Fichiers présents dans assets/images/:**
- `orange_money.png` (10 KB)
- `mtn_money.png` (13 KB)
- `moov_money.jpg` (49 KB)
- `wave.png` (65 KB)
- `logo.png` (1.5 KB)

✅ **Assets déclarés dans pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/images/
```

## 🐛 Pourquoi les assets ne s'affichent pas ?

### Cause probable:
Les **assets Flutter sont compilés lors du build**. Un simple Hot Reload ne suffit pas pour charger de nouveaux fichiers ajoutés dans le dossier assets.

### Différence importante:
- **Images réseau** (produits): Chargées dynamiquement depuis le serveur → Hot Reload OK
- **Images assets** (logos paiement): Compilées dans l'APK/IPA → Hot Restart ou Rebuild REQUIS

## ✅ Solutions (par ordre de priorité)

### Solution 1: Hot Restart (RECOMMANDÉ)
**Dans le terminal Flutter en cours d'exécution:**

```
Appuyez sur: Shift + R
Ou tapez: R (majuscule)
```

**Résultat:** Redémarre l'app sans recompiler (rapide, ~5 secondes)

### Solution 2: Stop & Restart
**Dans le terminal Flutter:**

```
Appuyez sur: q (pour quitter)
Puis relancez: flutter run
```

**Résultat:** Recompile complètement l'app (plus long, ~30 secondes)

### Solution 3: Clean & Rebuild (Si les 2 premières ne marchent pas)
**Dans le terminal:**

```bash
flutter clean
flutter pub get
flutter run
```

**Résultat:** Nettoie et reconstruit tout (le plus long, ~2 minutes)

## 🧪 Comment tester les logos

### Test 1: Écran de paiement des factures

**Navigation:**
```
1. Ouvrir l'app Flutter
2. Aller à l'onglet "Factures"
3. Cliquer sur une facture impayée
4. Cliquer sur "Payer"
```

**Vérification:**
- ✅ Mobile Money: 3 logos côte à côte (Orange, MTN, Moov)
- ✅ Wave: 1 grand logo Wave
- ✅ Carte, Virement, Espèces: Icônes (inchangé)

### Test 2: Écran de paiement des souscriptions

**Navigation:**
```
1. Ouvrir l'app Flutter
2. Aller aux "Offres d'entretien"
3. Cliquer sur "Souscrire" sur une offre
4. Écran de paiement s'ouvre
```

**Vérification:**
- ✅ Orange Money: logo Orange
- ✅ MTN Money: logo MTN
- ✅ Moov Money: logo Moov
- ✅ Wave: logo Wave
- ✅ Carte: Icône (inchangé)

## 📋 Checklist de diagnostic

### Si les logos ne s'affichent toujours pas:

#### 1. Vérifier la console Flutter
**Erreur typique si asset manquant:**
```
flutter: ══╡ EXCEPTION ╞═══════════
flutter: The following assertion was thrown resolving an image codec:
flutter: Unable to load asset: assets/images/orange_money.png
```

**Si vous voyez cette erreur:**
- Vérifier le chemin exact dans le code
- Vérifier que le fichier existe
- Vérifier l'extension (.png vs .jpg)

#### 2. Vérifier les chemins dans le code

**PaymentScreen.dart (ligne 180-182):**
```dart
[
  'assets/images/orange_money.png',  // ✅ Correct
  'assets/images/mtn_money.png',     // ✅ Correct
  'assets/images/moov_money.jpg',    // ✅ Correct (JPG!)
],
```

**SubscriptionPaymentScreen.dart:**
```dart
'assets/images/orange_money.png'  // ✅ Correct
'assets/images/mtn_money.png'     // ✅ Correct
'assets/images/moov_money.jpg'    // ✅ Correct (JPG!)
'assets/images/wave.png'          // ✅ Correct
```

#### 3. Vérifier pubspec.yaml

**Doit contenir (ligne 80-82):**
```yaml
flutter:
  assets:
    - assets/images/
```

**ATTENTION aux espaces:**
```yaml
# ✅ CORRECT (2 espaces pour 'assets:', 4 pour '- assets/')
flutter:
  assets:
    - assets/images/

# ❌ INCORRECT (mauvais indentation)
flutter:
assets:
  - assets/images/
```

## 🔧 Dépannage avancé

### Problème: Les logos apparaissent en gris ou vides

**Cause possible:** Image corrompue ou format non supporté

**Solution:**
```bash
# Vérifier le type de fichier
file assets/images/orange_money.png
# Devrait afficher: PNG image data, 200 x 200, ...

# Vérifier la taille
ls -lh assets/images/
# Tous les fichiers doivent avoir une taille > 0
```

### Problème: Certains logos s'affichent, d'autres non

**Cause probable:** Extension incorrecte dans le code

**Vérification:**
```bash
# Lister avec extensions
ls -1 assets/images/
```

**Résultat attendu:**
```
logo.png
moov_money.jpg       # ← JPG, pas PNG !
mtn_money.png
orange_money.png
wave.png
```

**Dans le code, utiliser:**
```dart
'assets/images/moov_money.jpg'  // ✅ jpg
// PAS: 'assets/images/moov_money.png'  // ❌ png
```

### Problème: Erreur "Asset not found" malgré tout

**Solution nucléaire:**

```bash
# 1. Arrêter complètement Flutter
# Appuyez sur 'q' dans le terminal

# 2. Nettoyer tout
flutter clean

# 3. Supprimer les builds
rm -rf build/
rm -rf ios/Pods
rm -rf android/.gradle

# 4. Réinstaller les dépendances
flutter pub get

# 5. Pour iOS uniquement (si applicable)
cd ios && pod install && cd ..

# 6. Relancer
flutter run
```

## 📸 À quoi ça devrait ressembler

### Mobile Money (3 logos ensemble):
```
┌────────────────────────────────────────────────┐
│ ┌──────────────────────────────┐               │
│ │  [🟠]    [🟡]    [🟢]       │  Mobile Money │
│ │ Orange   MTN    Moov         │               │
│ └──────────────────────────────┘  Orange...   │
└────────────────────────────────────────────────┘
```

### Wave (1 logo):
```
┌────────────────────────────────────────────────┐
│ ┌──────────┐                                   │
│ │   [💧]   │  Wave                             │
│ │   Wave   │  Paiement mobile Wave             │
│ └──────────┘                                   │
└────────────────────────────────────────────────┘
```

### Orange Money seul:
```
┌────────────────────────────────────────────────┐
│ ┌──────────┐                                   │
│ │   [🟠]   │  Orange Money                     │
│ │  Orange  │  Paiement via Orange Money        │
│ └──────────┘                                   │
└────────────────────────────────────────────────┘
```

## 🎯 Actions immédiates

### Étape 1: Hot Restart
**Dans votre terminal Flutter actuel:**
```
Appuyez sur: Shift + R
```

### Étape 2: Tester
1. Ouvrir l'app
2. Aller aux Factures
3. Cliquer sur une facture
4. Cliquer sur "Payer"
5. ✅ Vérifier si les logos apparaissent

### Étape 3: Si ça ne marche toujours pas
**Envoyer ces informations:**

1. **Console Flutter:** Copier les erreurs si présentes
2. **Capture d'écran:** De l'écran de paiement
3. **Version Flutter:**
   ```bash
   flutter --version
   ```

## 💡 Astuces pour l'avenir

### Quand ajouter de nouveaux assets:
1. ✅ Ajouter le fichier dans `assets/images/`
2. ✅ Vérifier qu'il est bien là: `ls assets/images/`
3. ✅ S'assurer que pubspec.yaml inclut `assets/images/`
4. ✅ **TOUJOURS faire un Hot Restart** (Shift + R)
5. ❌ **Ne PAS faire juste un Hot Reload** (r minuscule)

### Quand modifier un asset existant:
- Remplacer le fichier
- Hot Restart (Shift + R)
- Pas besoin de Clean Build

### Quand supprimer un asset:
- Supprimer le fichier
- Supprimer les références dans le code
- Clean Build recommandé

## 🆘 Support

### Si rien ne fonctionne:

**Vérification finale:**
```bash
# 1. Position dans le projet
pwd
# Devrait afficher: /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile

# 2. Assets présents
ls -la assets/images/

# 3. pubspec.yaml correct
grep -A 3 "assets:" pubspec.yaml

# 4. Aucune erreur de compilation
flutter analyze
```

### Cas extrême: Créer un test isolé

**Créer `test_assets_screen.dart`:**
```dart
import 'package:flutter/material.dart';

class TestAssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Assets')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Orange Money'),
            leading: Image.asset('assets/images/orange_money.png', width: 50, height: 50),
          ),
          ListTile(
            title: Text('MTN Money'),
            leading: Image.asset('assets/images/mtn_money.png', width: 50, height: 50),
          ),
          ListTile(
            title: Text('Moov Money'),
            leading: Image.asset('assets/images/moov_money.jpg', width: 50, height: 50),
          ),
          ListTile(
            title: Text('Wave'),
            leading: Image.asset('assets/images/wave.png', width: 50, height: 50),
          ),
        ],
      ),
    );
  }
}
```

**Tester cet écran directement pour isoler le problème.**

## 📊 Résumé

| Problème | Solution | Durée |
|----------|----------|-------|
| Assets ajoutés | Hot Restart (Shift + R) | 5 sec |
| Toujours pas visible | Stop & Restart | 30 sec |
| Erreurs persistantes | Flutter Clean | 2 min |
| Corruption suspected | Rebuild complet | 5 min |

## ✅ Checklist finale

Avant de demander de l'aide:

- [ ] Assets existent dans `assets/images/`
- [ ] Extensions correctes (.png ou .jpg)
- [ ] Chemins corrects dans le code
- [ ] pubspec.yaml bien formaté
- [ ] Hot Restart effectué (Shift + R)
- [ ] App relancée complètement
- [ ] Flutter Clean + Rebuild essayé
- [ ] Console Flutter vérifiée pour erreurs
- [ ] Capture d'écran de l'écran de paiement prise

**Si tout est coché et ça ne marche toujours pas, il y a un problème plus profond à investiguer !**
