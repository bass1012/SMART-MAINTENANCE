# 📱 Téléchargement de Facture PDF - Application Mobile

## ✅ Fonctionnalités Implémentées

### 1. **Service API - Téléchargement PDF**

**Fichier:** `/lib/services/api_service.dart`

Nouvelle méthode ajoutée :
```dart
Future<List<int>> downloadInvoicePDF(int orderId)
```

**Fonctionnalités:**
- Authentification JWT
- Téléchargement du PDF depuis l'API backend
- Timeout de 30 secondes
- Logs de débogage détaillés
- Retourne les bytes du PDF

**Endpoint API utilisé:**
```
GET /api/payments/invoice/:orderId/download
```

---

### 2. **Écran de Détail de Commande**

**Fichier:** `/lib/screens/customer/order_detail_screen.dart`

**Fonctionnalités:**
- ✅ Affichage complet des détails de la commande
- ✅ Statut avec icône et couleur
- ✅ Informations (référence, date, paiement, livraison)
- ✅ Liste des articles avec quantités et prix
- ✅ Total en FCFA
- ✅ **Bouton de téléchargement de facture PDF**

**Bouton de téléchargement:**
- Icône PDF
- Loader pendant le téléchargement
- Gestion des permissions (Android)
- Sauvegarde dans le dossier Download
- Ouverture automatique du PDF
- Notification de succès avec bouton "Ouvrir"

---

### 3. **Navigation depuis l'Historique**

**Fichier:** `/lib/screens/customer/history_screen.dart`

**Modifications:**
- Stockage des données brutes des commandes
- Navigation vers `OrderDetailScreen` lors du clic sur une commande
- Passage des données complètes de la commande

---

### 4. **Dépendances Ajoutées**

**Fichier:** `pubspec.yaml`

```yaml
dependencies:
  path_provider: ^2.1.1      # Accès aux répertoires système
  open_file: ^3.3.2          # Ouverture de fichiers
  permission_handler: ^11.1.0 # Gestion des permissions
```

---

## 🎯 Flux d'Utilisation

### Étape 1 : Accéder à l'historique
```
Onglet "Commandes" → Liste des commandes
```

### Étape 2 : Voir les détails
```
Cliquer sur une commande → Écran de détail
```

### Étape 3 : Télécharger la facture
```
Cliquer sur "Télécharger la facture PDF"
↓
Demande de permission (Android uniquement)
↓
Téléchargement du PDF depuis l'API
↓
Sauvegarde dans /Download/facture-XXX.pdf
↓
Ouverture automatique du PDF
↓
Notification "Facture téléchargée" avec bouton "Ouvrir"
```

---

## 📊 Écran de Détail de Commande

### Structure

```
┌─────────────────────────────────────┐
│  Commande #4              [📥]      │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Icône] En attente          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Informations                │   │
│  │ ─────────────────────────   │   │
│  │ Référence: CMD-XXX          │   │
│  │ Date: 21/10/2025            │   │
│  │ Mode paiement: Carte        │   │
│  │ Adresse: Cocody             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Articles                    │   │
│  │ ─────────────────────────   │   │
│  │ Split Allège                │   │
│  │ Quantité: 3 × 755 000 FCFA  │   │
│  │                 2 265 000 F │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Total      3 020 000 FCFA   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [📄] Télécharger facture PDF│   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔐 Permissions Android

### AndroidManifest.xml

Ajouter ces permissions dans `/android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

Pour Android 11+ (API 30+), ajouter aussi :

```xml
<application
    android:requestLegacyExternalStorage="true"
    ...>
```

---

## 📱 Gestion des Permissions

### Android
```dart
if (Platform.isAndroid) {
  final status = await Permission.storage.request();
  if (!status.isGranted) {
    // Afficher un message d'erreur
    return;
  }
}
```

### iOS
Pas de permission nécessaire (sauvegarde dans Documents)

---

## 💾 Emplacement des Fichiers

### Android
```
/storage/emulated/0/Download/facture-CMD-XXX.pdf
```

### iOS
```
Application Documents/facture-CMD-XXX.pdf
```

---

## 🎨 Design

### Couleurs
- **Vert MCT:** `#0a543d`
- **Succès:** `Colors.green`
- **En attente:** `Colors.orange`
- **Erreur:** `Colors.red`

### Icônes
- **Téléchargement:** `Icons.download`
- **PDF:** `Icons.picture_as_pdf`
- **Statut:** `Icons.check_circle`, `Icons.pending`, `Icons.cancel`

---

## 🔧 Installation

### 1. Installer les dépendances
```bash
cd mct_maintenance_mobile
flutter pub get
```

### 2. Configurer les permissions Android
Modifier `/android/app/src/main/AndroidManifest.xml`

### 3. Tester
```bash
flutter run
```

---

## 🧪 Tests

### Test 1 : Navigation
1. Ouvrir l'app
2. Aller dans l'onglet "Commandes"
3. Cliquer sur une commande
4. Vérifier que l'écran de détail s'affiche

### Test 2 : Téléchargement
1. Dans l'écran de détail
2. Cliquer sur "Télécharger la facture PDF"
3. Accepter la permission (Android)
4. Vérifier que le PDF se télécharge
5. Vérifier que le PDF s'ouvre automatiquement

### Test 3 : Ouverture manuelle
1. Aller dans le dossier Download
2. Trouver `facture-CMD-XXX.pdf`
3. Ouvrir le fichier
4. Vérifier le contenu (logo, infos, articles)

---

## 📝 Fichiers Modifiés/Créés

### Créés
1. ✅ `/lib/screens/customer/order_detail_screen.dart` - Écran de détail
2. ✅ `/TELECHARGEMENT_FACTURE.md` - Documentation complète

### Modifiés
1. ✅ `/lib/services/api_service.dart` - Méthode downloadInvoicePDF
2. ✅ `/lib/screens/customer/history_screen.dart` - Navigation + stockage données
3. ✅ `/lib/screens/customer/invoices_screen.dart` - Téléchargement depuis l'écran factures
4. ✅ `/pubspec.yaml` - Dépendances

---

## 🚀 Prochaines Étapes

### Améliorations possibles
1. **Partage du PDF** - Bouton de partage par email/WhatsApp
2. **Historique des téléchargements** - Liste des factures téléchargées
3. **Aperçu du PDF** - Viewer intégré dans l'app
4. **Envoi par email** - Bouton pour envoyer la facture par email
5. **Cache** - Sauvegarder les factures déjà téléchargées

---

## ✅ Résultat Final

L'application mobile dispose maintenant de la même fonctionnalité de téléchargement de facture que le dashboard web :

- ✅ **Téléchargement PDF** depuis l'API backend
- ✅ **Sauvegarde locale** dans le dossier Download
- ✅ **Ouverture automatique** du PDF
- ✅ **Design professionnel** avec logo MCT
- ✅ **Gestion des permissions** Android
- ✅ **Notifications** de succès/erreur

**L'utilisateur peut maintenant télécharger et consulter ses factures directement depuis son téléphone !** 📱📄
