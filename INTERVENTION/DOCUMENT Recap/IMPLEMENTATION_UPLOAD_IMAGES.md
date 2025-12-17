# 📸 Implémentation Complète - Upload Multi-Images

## ✅ Frontend Mobile - Implémenté

Les **2 options** d'envoi d'images sont maintenant disponibles dans l'application mobile.

---

## 📱 **Option 1 : Multipart/Form-Data** ⭐ RECOMMANDÉ

### **ApiService - Méthode Implémentée**

```dart
Future<Map<String, dynamic>> createInterventionWithImages({
  required Map<String, dynamic> data,
  List<File>? images,
}) async {
  final url = Uri.parse('${AppConfig.baseUrl}/api/interventions');
  var request = http.MultipartRequest('POST', url);
  
  // Headers
  if (_authToken != null) {
    request.headers['Authorization'] = 'Bearer $_authToken';
  }
  
  // Données texte
  data.forEach((key, value) {
    if (value != null) {
      request.fields[key] = value.toString();
    }
  });
  
  // Images (max 5)
  if (images != null && images.isNotEmpty) {
    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final mimeType = file.path.toLowerCase().endsWith('.png') 
          ? 'image/png' 
          : 'image/jpeg';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'images', // Nom du champ array
          file.path,
          contentType: http_parser.MediaType.parse(mimeType),
        ),
      );
    }
  }
  
  // Envoi
  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  
  return json.decode(response.body);
}
```

### **Utilisation dans new_intervention_screen.dart**

```dart
// Appel API avec images
if (_selectedImages.isNotEmpty) {
  await _apiService.createInterventionWithImages(
    data: interventionData,
    images: _selectedImages, // Liste de 0 à 5 images
  );
} else {
  // Sans images
  await _apiService.createIntervention(interventionData);
}
```

---

## 📱 **Option 2 : Base64** (Alternative)

### **ApiService - Méthode Implémentée**

```dart
Future<Map<String, dynamic>> createInterventionWithImagesBase64({
  required Map<String, dynamic> data,
  List<File>? images,
}) async {
  // Convertir images en Base64
  if (images != null && images.isNotEmpty) {
    List<Map<String, String>> imagesBase64 = [];
    
    for (var image in images) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = image.path.toLowerCase().endsWith('.png') 
          ? 'image/png' 
          : 'image/jpeg';
      
      imagesBase64.add({
        'data': base64Image,
        'mimeType': mimeType,
      });
    }
    
    data['images_base64'] = imagesBase64;
  }
  
  // Envoi en JSON classique
  return await _handleRequest(
    'POST',
    '/api/interventions',
    body: data,
  );
}
```

### **Utilisation (à décommenter si préféré)**

```dart
// Alternative Base64
await _apiService.createInterventionWithImagesBase64(
  data: interventionData,
  images: _selectedImages.isNotEmpty ? _selectedImages : null,
);
```

---

## 🔧 **Backend - À Implémenter**

### **1. Installer Multer (pour Option 1)**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm install multer
```

### **2. Créer Modèle InterventionImage**

**Fichier:** `/src/models/InterventionImage.js`

```javascript
module.exports = (sequelize, DataTypes) => {
  const InterventionImage = sequelize.define('InterventionImage', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    intervention_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'interventions',
        key: 'id'
      },
      onDelete: 'CASCADE'
    },
    image_url: {
      type: DataTypes.STRING,
      allowNull: false
    },
    order: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      comment: 'Ordre d\'affichage des images'
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'intervention_images',
    timestamps: true,
    underscored: true
  });

  InterventionImage.associate = (models) => {
    InterventionImage.belongsTo(models.Intervention, {
      foreignKey: 'intervention_id',
      as: 'intervention'
    });
  };

  return InterventionImage;
};
```

### **3. Association dans Intervention.js**

```javascript
// Dans /src/models/Intervention.js
Intervention.associate = (models) => {
  // ... autres associations
  
  Intervention.hasMany(models.InterventionImage, {
    foreignKey: 'intervention_id',
    as: 'images'
  });
};
```

### **4. Ajouter dans models/index.js**

```javascript
// Dans /src/models/index.js
db.InterventionImage = require('./InterventionImage')(sequelize, Sequelize);
```

### **5. Migration Base de Données**

**Fichier:** `/migrations/create_intervention_images.sql`

```sql
-- Migration: Créer table intervention_images
-- Date: 2025-10-30

CREATE TABLE IF NOT EXISTS intervention_images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  intervention_id INTEGER NOT NULL,
  image_url VARCHAR(255) NOT NULL,
  `order` INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON DELETE CASCADE
);

CREATE INDEX idx_intervention_images_intervention_id 
ON intervention_images(intervention_id);
```

**Appliquer la migration:**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
sqlite3 database.sqlite < migrations/create_intervention_images.sql
```

### **6. Configuration Multer**

**Fichier:** `/src/config/multer.js`

```javascript
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Créer le dossier uploads si n'existe pas
const uploadDir = path.join(__dirname, '../../uploads/interventions');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuration du stockage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `intervention-${uniqueSuffix}${ext}`);
  }
});

// Filtrage des types de fichiers
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Seules les images (JPEG, PNG, GIF) sont autorisées'));
  }
};

// Export de la configuration
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max par image
    files: 5 // Max 5 images
  },
  fileFilter: fileFilter
});

module.exports = upload;
```

### **7. Modifier le Contrôleur**

**Fichier:** `/src/controllers/intervention/interventionController.js`

```javascript
const upload = require('../../config/multer');
const { InterventionImage } = require('../../models');

// Créer une intervention avec images
exports.createIntervention = [
  // Middleware multer pour gérer les images
  upload.array('images', 5),
  
  async (req, res, next) => {
    const transaction = await Intervention.sequelize.transaction();
    
    try {
      const interventionData = req.body;
      
      // Créer l'intervention
      const intervention = await Intervention.create(interventionData, { transaction });
      
      // Sauvegarder les images si présentes
      if (req.files && req.files.length > 0) {
        console.log(`📸 ${req.files.length} image(s) uploadée(s)`);
        
        const imagePromises = req.files.map((file, index) => {
          return InterventionImage.create({
            intervention_id: intervention.id,
            image_url: `/uploads/interventions/${file.filename}`,
            order: index
          }, { transaction });
        });
        
        await Promise.all(imagePromises);
      }
      
      // OU pour Option 2 (Base64) :
      if (req.body.images_base64 && Array.isArray(req.body.images_base64)) {
        console.log(`📸 ${req.body.images_base64.length} image(s) Base64`);
        
        const imagePromises = req.body.images_base64.map(async (imageData, index) => {
          // Décoder Base64
          const base64Data = imageData.data.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');
          
          // Sauvegarder sur disque
          const filename = `intervention-${Date.now()}-${index}.${imageData.mimeType.split('/')[1]}`;
          const filepath = path.join(__dirname, '../../uploads/interventions', filename);
          await fs.promises.writeFile(filepath, buffer);
          
          // Créer l'entrée en DB
          return InterventionImage.create({
            intervention_id: intervention.id,
            image_url: `/uploads/interventions/${filename}`,
            order: index
          }, { transaction });
        });
        
        await Promise.all(imagePromises);
      }
      
      await transaction.commit();
      
      // Recharger avec images
      const interventionWithImages = await Intervention.findByPk(intervention.id, {
        include: [
          { model: InterventionImage, as: 'images' },
          // ... autres includes
        ]
      });
      
      res.status(201).json({
        success: true,
        data: interventionWithImages
      });
      
    } catch (error) {
      await transaction.rollback();
      console.error('❌ Erreur création intervention:', error);
      next(error);
    }
  }
];
```

### **8. Servir les Images Statiques**

**Dans le fichier principal (server.js ou app.js):**

```javascript
const express = require('express');
const path = require('path');

const app = express();

// Servir les fichiers statiques
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ... reste du code
```

### **9. Route Complète**

**Fichier:** `/src/routes/interventionRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const interventionController = require('../controllers/intervention/interventionController');
const { authenticateToken } = require('../middleware/auth');

// POST /api/interventions (avec upload d'images)
router.post(
  '/',
  authenticateToken,
  interventionController.createIntervention // Inclut déjà le middleware multer
);

module.exports = router;
```

---

## 🔄 **Flux Complet**

### **Mobile → Backend**

```
Mobile App
  ↓
[Sélectionner 1-5 photos]
  ↓
[OPTION 1] Multipart/Form-Data
  ↓
POST /api/interventions
  Content-Type: multipart/form-data
  ↓
  - fields: title, description, etc.
  - files: image1.jpg, image2.jpg, ...
  ↓
Backend - Multer
  ↓
Sauvegarde physique dans /uploads/interventions/
  ↓
Création entrées dans intervention_images
  ↓
Retour JSON avec URLs des images
```

### **Ou Alternative Base64**

```
Mobile App
  ↓
[Sélectionner 1-5 photos]
  ↓
[OPTION 2] Base64
  ↓
Conversion en Base64 côté mobile
  ↓
POST /api/interventions
  Content-Type: application/json
  ↓
  {
    "title": "...",
    "images_base64": [
      { "data": "base64...", "mimeType": "image/jpeg" },
      { "data": "base64...", "mimeType": "image/png" }
    ]
  }
  ↓
Backend - Décodage Base64
  ↓
Sauvegarde physique dans /uploads/interventions/
  ↓
Création entrées dans intervention_images
```

---

## 📊 **Comparaison Options**

| Critère | Option 1 (Multipart) | Option 2 (Base64) |
|---------|---------------------|-------------------|
| **Taille données** | ✅ Optimale | ❌ +33% (overhead Base64) |
| **Mémoire serveur** | ✅ Stream direct | ❌ Décodage en mémoire |
| **Performance** | ✅ Rapide | ⚠️ Plus lent |
| **Simplicité backend** | ⚠️ Multer requis | ✅ JSON classique |
| **Limite taille** | ✅ 5MB par image | ⚠️ Limite JSON (~50MB) |
| **Recommandation** | ⭐ PRODUCTION | 🔧 Développement/Test |

---

## 🧪 **Tests à Effectuer**

### **Test 1 : Upload 1 Image**
```bash
# Mobile
1. Créer intervention
2. Ajouter 1 photo
3. Soumettre

# Vérifier Backend
- Fichier dans /uploads/interventions/
- Entrée dans intervention_images
- URL retournée dans réponse
```

### **Test 2 : Upload 5 Images**
```bash
# Mobile
1. Ajouter 5 photos
2. Soumettre

# Vérifier Backend
- 5 fichiers dans /uploads/
- 5 entrées en DB
- Ordre préservé (0-4)
```

### **Test 3 : Sans Image**
```bash
# Mobile
1. Ne pas ajouter de photo
2. Soumettre

# Vérifier Backend
- Intervention créée normalement
- Aucune entrée dans intervention_images
```

### **Test 4 : Types de Fichiers**
```bash
# Tester avec:
- JPEG ✅
- PNG ✅
- GIF ✅
- PDF ❌ (doit être rejeté)
- MP4 ❌ (doit être rejeté)
```

---

## 📁 **Structure Fichiers Backend**

```
mct-maintenance-api/
├── uploads/
│   └── interventions/
│       ├── intervention-1730281234567-123456789.jpg
│       ├── intervention-1730281345678-987654321.png
│       └── ...
├── src/
│   ├── config/
│   │   └── multer.js          ← À créer
│   ├── models/
│   │   ├── Intervention.js    ← Modifier (association)
│   │   ├── InterventionImage.js ← À créer
│   │   └── index.js           ← Modifier (import)
│   ├── controllers/
│   │   └── intervention/
│   │       └── interventionController.js ← Modifier
│   └── routes/
│       └── interventionRoutes.js ← Vérifier
├── migrations/
│   └── create_intervention_images.sql ← À créer
└── server.js                   ← Modifier (static files)
```

---

## 🎯 **Checklist Complète**

### **Frontend Mobile** ✅
- [x] Option 1 : Multipart implémentée
- [x] Option 2 : Base64 implémentée
- [x] Formulaire multi-photos (1-5)
- [x] Appel API conditionnel
- [x] Gestion erreurs

### **Backend** ⏳
- [ ] npm install multer
- [ ] Créer config/multer.js
- [ ] Créer models/InterventionImage.js
- [ ] Modifier models/Intervention.js (association)
- [ ] Modifier models/index.js
- [ ] Créer migration SQL
- [ ] Appliquer migration
- [ ] Modifier interventionController.js
- [ ] Servir fichiers statiques
- [ ] Tester uploads

### **Tests** ⏳
- [ ] Upload 1 image
- [ ] Upload 5 images
- [ ] Sans image
- [ ] Types de fichiers
- [ ] Limites de taille
- [ ] Récupération avec images

---

## 🚀 **Commandes Rapides**

### **Backend Setup**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Installer multer
npm install multer

# Créer dossier uploads
mkdir -p uploads/interventions

# Appliquer migration
sqlite3 database.sqlite < migrations/create_intervention_images.sql

# Redémarrer serveur
npm run dev
```

### **Test Upload**
```bash
# Depuis mobile
flutter run

# Logs backend
tail -f logs/app.log | grep "📸"
```

---

## 📝 **Résumé**

### **✅ Complété**
- Frontend mobile : 2 options d'upload
- Interface multi-photos (1-5)
- Compression automatique
- Validation taille/type

### **⏳ À Faire**
- Backend : Configuration multer
- Backend : Modèle InterventionImage
- Backend : Migration base de données
- Backend : Contrôleur upload
- Tests complets

### **🎯 Prochaine Étape**
**Configurer le backend pour recevoir les images !**

---

**Date de création :** 30 octobre 2025  
**Statut :** ✅ Frontend prêt | ⏳ Backend à configurer  
**Mode actuel :** Option 1 (Multipart) activée par défaut  

**Développé pour MCT Maintenance** 🔧📸✨
