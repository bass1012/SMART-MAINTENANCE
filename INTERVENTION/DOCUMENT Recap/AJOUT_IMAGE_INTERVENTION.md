# 📸 Ajout d'Image aux Interventions - Application Mobile

## ✅ Fonctionnalité Ajoutée

Les clients peuvent maintenant **joindre une photo optionnelle** lors de la création d'une intervention pour aider les techniciens à mieux comprendre le problème.

---

## 📋 **Modifications Apportées**

### **1. Package Utilisé**
- **`image_picker: ^1.0.7`** - Déjà installé dans pubspec.yaml
- Sources supportées : Caméra et Galerie

### **2. Interface Utilisateur** ✅

**Nouveau champ après "Nombre d'équipements" :**

```
┌─────────────────────────────────────────┐
│ Photo (optionnelle)                     │
├─────────────────────────────────────────┤
│ [Image preview si sélectionnée]         │
│ ─────────────────────────────────────── │
│ [📷 Appareil photo] [🖼️ Galerie] [🗑️]  │
└─────────────────────────────────────────┘
Ajoutez une photo pour aider le technicien...
```

**Caractéristiques :**
- 📸 **Appareil photo** : Prendre une photo directement
- 🖼️ **Galerie** : Sélectionner depuis les photos existantes
- 👁️ **Preview** : Affiche l'image sélectionnée (200px de hauteur)
- 🗑️ **Supprimer** : Bouton rouge pour retirer l'image
- 💬 **Texte d'aide** : Message explicatif en gris

---

## 🎨 **Design**

### **Apparence**

**Sans image sélectionnée :**
```
┌─────────────────────────────────────────┐
│ Photo (optionnelle)                     │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │  [📷 Appareil]   [🖼️ Galerie]     │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
Ajoutez une photo pour aider...
```

**Avec image sélectionnée :**
```
┌─────────────────────────────────────────┐
│ Photo (optionnelle)                     │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │     [IMAGE PREVIEW 200px]           │ │
│ │                                     │ │
│ ├─────────────────────────────────────┤ │
│ │ [📷] [🖼️ Galerie] [🗑️ Supprimer]   │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
Ajoutez une photo pour aider...
```

---

## ⚙️ **Paramètres d'Optimisation**

### **Compression Automatique**
```dart
await _imagePicker.pickImage(
  source: ImageSource.camera, // ou gallery
  imageQuality: 80,            // Compression 80%
  maxWidth: 1920,              // Max largeur
  maxHeight: 1080,             // Max hauteur
);
```

**Avantages :**
- ✅ Réduit la taille du fichier
- ✅ Upload plus rapide
- ✅ Moins de bande passante
- ✅ Qualité suffisante pour diagnostic

---

## 🔧 **Code Implémenté**

### **Variables d'État**
```dart
File? _selectedImage;
final ImagePicker _imagePicker = ImagePicker();
```

### **Méthode Caméra**
```dart
Future<void> _pickImageFromCamera() async {
  try {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  } catch (e) {
    // Affiche erreur
  }
}
```

### **Méthode Galerie**
```dart
Future<void> _pickImageFromGallery() async {
  // Même code avec ImageSource.gallery
}
```

---

## 📤 **Envoi au Backend**

### **Format d'Envoi** (À Implémenter)

**Option 1 : Multipart/Form-Data** (Recommandé)
```dart
// Dans ApiService
Future<void> createInterventionWithImage({
  required Map<String, dynamic> data,
  File? image,
}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/interventions'),
  );
  
  // Headers
  request.headers.addAll({
    'Authorization': 'Bearer $token',
  });
  
  // Données JSON
  data.forEach((key, value) {
    request.fields[key] = value.toString();
  });
  
  // Image si présente
  if (image != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
  }
  
  var response = await request.send();
  // Traiter la réponse
}
```

**Option 2 : Base64** (Alternative)
```dart
// Convertir en base64
import 'dart:convert';

final bytes = await _selectedImage!.readAsBytes();
final base64Image = base64Encode(bytes);

// Ajouter aux données
interventionData['image'] = base64Image;
```

---

## 🗄️ **Backend (À Ajouter)**

### **1. Modèle Intervention**
```javascript
// Dans Intervention.js
image_url: {
  type: DataTypes.STRING,
  allowNull: true
}
```

### **2. Migration SQL**
```sql
ALTER TABLE interventions ADD COLUMN image_url VARCHAR(255) DEFAULT NULL;
```

### **3. Upload Handler**
```javascript
// Utiliser multer pour gérer l'upload
const multer = require('multer');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/interventions/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'intervention-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Seules les images sont autorisées'));
    }
  }
});
```

### **4. Route**
```javascript
router.post('/interventions', 
  authenticateToken, 
  upload.single('image'), 
  async (req, res) => {
    try {
      const interventionData = req.body;
      
      // Ajouter l'URL de l'image si uploadée
      if (req.file) {
        interventionData.image_url = `/uploads/interventions/${req.file.filename}`;
      }
      
      const intervention = await Intervention.create(interventionData);
      res.json({ success: true, data: intervention });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
);
```

---

## 📱 **Permissions Requises**

### **Android (AndroidManifest.xml)**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### **iOS (Info.plist)**
```xml
<key>NSCameraUsageDescription</key>
<string>Cette application a besoin d'accéder à la caméra pour prendre des photos des équipements</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Cette application a besoin d'accéder aux photos pour sélectionner des images</string>
```

---

## 🧪 **Tests à Effectuer**

### **Test 1 : Photo depuis Caméra**
1. Ouvrir "Nouvelle Intervention"
2. Cliquer sur "📷 Appareil photo"
3. Autoriser l'accès caméra
4. Prendre une photo
5. ✅ Vérifier le preview
6. Soumettre
7. ✅ Vérifier l'envoi

### **Test 2 : Photo depuis Galerie**
1. Cliquer sur "🖼️ Galerie"
2. Autoriser l'accès photos
3. Sélectionner une image
4. ✅ Vérifier le preview
5. Soumettre
6. ✅ Vérifier l'envoi

### **Test 3 : Suppression**
1. Sélectionner une image
2. Cliquer sur "🗑️"
3. ✅ Vérifier disparition
4. Soumettre sans image
5. ✅ Doit fonctionner

### **Test 4 : Sans Image**
1. Ne pas sélectionner d'image
2. Soumettre
3. ✅ Doit fonctionner (optionnel)

### **Test 5 : Permissions Refusées**
1. Refuser permission caméra
2. ✅ Vérifier message d'erreur
3. Refuser permission galerie
4. ✅ Vérifier message d'erreur

---

## 📊 **Cas d'Usage**

### **Exemple 1 : Fuite d'Eau**
```
Client prend photo de la fuite
→ Technicien voit l'ampleur avant déplacement
→ Apporte le matériel approprié
```

### **Exemple 2 : Panne Climatisation**
```
Client photo du code erreur
→ Technicien identifie le problème
→ Prépare la pièce de rechange
```

### **Exemple 3 : Installation**
```
Client photo de l'emplacement
→ Technicien évalue la faisabilité
→ Prépare le devis précis
```

---

## 🎯 **Avantages**

✅ **Diagnostic précis** : Le technicien voit le problème avant déplacement
✅ **Gain de temps** : Préparation du matériel adapté
✅ **Meilleure communication** : Image vaut mille mots
✅ **Historique visuel** : Suivi de l'état avant/après
✅ **Devis précis** : Évaluation plus juste du coût
✅ **Optionnel** : Pas obligatoire pour les clients pressés

---

## 🚀 **Prochaines Étapes**

### **Backend**
1. [ ] Ajouter colonne `image_url` à la table `interventions`
2. [ ] Installer et configurer `multer`
3. [ ] Créer dossier `uploads/interventions/`
4. [ ] Modifier route POST pour accepter multipart
5. [ ] Ajouter validation taille/type fichier
6. [ ] Configurer serveur pour servir images statiques

### **Mobile**
1. [x] Interface de sélection d'image
2. [x] Méthodes caméra et galerie
3. [x] Preview et suppression
4. [ ] Modifier `ApiService.createIntervention` pour multipart
5. [ ] Tester upload complet
6. [ ] Gérer erreurs upload

### **Dashboard Web**
1. [ ] Afficher image dans liste interventions
2. [ ] Afficher image dans modal détails
3. [ ] Possibilité d'ajouter image en modification
4. [ ] Galerie d'images si plusieurs photos

---

## 📝 **Fichiers Modifiés**

| Fichier | Modification | Statut |
|---------|-------------|--------|
| `new_intervention_screen.dart` | UI + logique sélection | ✅ |
| `api_service.dart` | Upload multipart | ⏳ TODO |
| `Intervention.js` | Champ image_url | ⏳ TODO |
| `interventionController.js` | Upload handler | ⏳ TODO |
| `AndroidManifest.xml` | Permissions | ⏳ À vérifier |
| `Info.plist` | Permissions iOS | ⏳ À vérifier |

---

## 💾 **Stockage des Images**

### **Structure Recommandée**
```
uploads/
  interventions/
    intervention-1730281234567-123456789.jpg
    intervention-1730281345678-987654321.jpg
```

### **URL d'Accès**
```
http://api.example.com/uploads/interventions/intervention-xxxxx.jpg
```

### **Nettoyage**
- Images supprimées après 90 jours si intervention terminée
- Script cron pour cleanup automatique

---

## ⚡ **Optimisations Futures**

1. **Compression côté serveur** : Re-compresser avec Sharp/ImageMagick
2. **Miniatures** : Générer thumbnails pour liste
3. **CDN** : Stocker sur AWS S3 ou Cloudinary
4. **Lazy loading** : Charger images à la demande
5. **Watermark** : Ajouter logo MCT sur les photos
6. **Multi-photos** : Permettre plusieurs photos par intervention

---

**Date de création :** 30 octobre 2025  
**Statut :** ✅ Interface mobile prête | ⏳ Backend à implémenter  
**Prochaine étape :** Modifier ApiService pour multipart upload  

**Développé pour MCT Maintenance** 🔧📸
