# 🚀 Guide de Démarrage Rapide - Upload Multi-Images

## ✅ Frontend Mobile - PRÊT

L'application mobile peut maintenant envoyer jusqu'à **5 photos** par intervention !

---

## 📋 **Étapes Backend (5 minutes)**

### **Étape 1 : Installer Multer**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm install multer
```

### **Étape 2 : Appliquer la Migration**

```bash
node apply-intervention-images-migration.js
```

**Résultat attendu :**
```
🔄 Application de la migration intervention_images...

✅ Connexion à la base de données réussie
📝 Création de la table intervention_images...

✅ Migration appliquée avec succès !
✅ Table intervention_images créée
✅ Index créé sur intervention_id

📋 Structure de la table:
   - id (INTEGER)
   - intervention_id (INTEGER)
   - image_url (VARCHAR(255))
   - order (INTEGER)
   - created_at (DATETIME)
   - updated_at (DATETIME)

🎉 Migration terminée avec succès !
```

### **Étape 3 : Ajouter InterventionImage au models/index.js**

**Ouvrir:** `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/src/models/index.js`

**Ajouter après les autres modèles :**

```javascript
db.InterventionImage = require('./InterventionImage')(sequelize, Sequelize);
```

### **Étape 4 : Ajouter Association dans Intervention.js**

**Ouvrir:** `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/src/models/Intervention.js`

**Dans la section `associate`, ajouter :**

```javascript
Intervention.associate = (models) => {
  // ... autres associations existantes
  
  // Association avec les images
  Intervention.hasMany(models.InterventionImage, {
    foreignKey: 'intervention_id',
    as: 'images'
  });
};
```

### **Étape 5 : Modifier interventionController.js**

**Ouvrir:** `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/src/controllers/intervention/interventionController.js`

**Ajouter en haut du fichier :**

```javascript
const upload = require('../../config/multer');
```

**Trouver la fonction `createIntervention` et remplacer par :**

```javascript
// Créer une nouvelle intervention avec support d'images
exports.createIntervention = [
  // Middleware multer pour gérer l'upload d'images (max 5)
  upload.array('images', 5),
  
  async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    
    try {
      console.log('📝 Création d\'une nouvelle intervention...');
      console.log('📋 Données reçues:', req.body);
      
      const interventionData = {
        title: req.body.title,
        description: req.body.description,
        customer_id: req.body.customer_id,
        technician_id: req.body.technician_id || null,
        scheduled_date: req.body.scheduled_date,
        priority: req.body.priority || 'medium',
        status: req.body.status || 'pending',
        address: req.body.address,
        intervention_type: req.body.intervention_type,
        equipment_count: req.body.equipment_count || 1,
      };

      // Créer l'intervention
      const intervention = await db.Intervention.create(interventionData, { transaction });
      console.log(`✅ Intervention créée avec l'ID: ${intervention.id}`);

      // Sauvegarder les images si présentes
      if (req.files && req.files.length > 0) {
        console.log(`📸 ${req.files.length} image(s) uploadée(s)`);
        
        const imagePromises = req.files.map((file, index) => {
          const imageUrl = `/uploads/interventions/${file.filename}`;
          console.log(`   ${index + 1}. ${imageUrl}`);
          
          return db.InterventionImage.create({
            intervention_id: intervention.id,
            image_url: imageUrl,
            order: index
          }, { transaction });
        });
        
        await Promise.all(imagePromises);
        console.log(`✅ ${req.files.length} image(s) enregistrée(s) en base`);
      }

      await transaction.commit();
      console.log('✅ Transaction validée');

      // Recharger l'intervention avec les images et associations
      const interventionWithDetails = await db.Intervention.findByPk(intervention.id, {
        include: [
          {
            model: db.InterventionImage,
            as: 'images',
            attributes: ['id', 'image_url', 'order']
          },
          {
            model: db.User,
            as: 'customer',
            attributes: ['id', 'first_name', 'last_name', 'email', 'phone']
          },
          {
            model: db.User,
            as: 'technician',
            attributes: ['id', 'first_name', 'last_name', 'email', 'phone']
          }
        ]
      });

      res.status(201).json({
        success: true,
        message: 'Intervention créée avec succès',
        data: interventionWithDetails
      });

    } catch (error) {
      await transaction.rollback();
      console.error('❌ Erreur lors de la création:', error);
      next(error);
    }
  }
];
```

### **Étape 6 : Servir les Fichiers Statiques**

**Ouvrir le fichier principal :** `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/server.js` ou `app.js`

**Ajouter avant les routes :**

```javascript
const path = require('path');

// Servir les fichiers uploadés (images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
console.log('📁 Dossier uploads disponible sur /uploads');
```

### **Étape 7 : Redémarrer le Serveur**

```bash
npm run dev
```

**Vérifier dans les logs :**
```
📁 Dossier uploads/interventions créé
📁 Dossier uploads disponible sur /uploads
✅ Serveur démarré sur le port 3000
```

---

## 🧪 **Tester Immédiatement**

### **1. Depuis l'Application Mobile**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter run
```

**Actions :**
1. Aller dans "Interventions"
2. Cliquer sur "+" (Nouvelle intervention)
3. Remplir le formulaire
4. **Ajouter 3 photos** (caméra ou galerie)
5. Soumettre

### **2. Vérifier Backend**

**Logs du serveur :**
```
📝 Création d'une nouvelle intervention...
📋 Données reçues: { title: '...', ... }
📸 Upload: IMG_1234.jpg → intervention-1730281234567-123456789.jpg
📸 Upload: IMG_1235.jpg → intervention-1730281345678-987654321.jpg
📸 Upload: IMG_1236.jpg → intervention-1730281456789-111222333.jpg
📸 3 image(s) uploadée(s)
   1. /uploads/interventions/intervention-1730281234567-123456789.jpg
   2. /uploads/interventions/intervention-1730281345678-987654321.jpg
   3. /uploads/interventions/intervention-1730281456789-111222333.jpg
✅ 3 image(s) enregistrée(s) en base
✅ Intervention créée avec l'ID: 45
✅ Transaction validée
```

**Fichiers créés :**
```bash
ls -lh uploads/interventions/
# intervention-1730281234567-123456789.jpg  234K
# intervention-1730281345678-987654321.jpg  456K
# intervention-1730281456789-111222333.jpg  189K
```

**Base de données :**
```bash
sqlite3 database.sqlite "SELECT * FROM intervention_images WHERE intervention_id = 45;"
# id | intervention_id | image_url | order
# 1  | 45             | /uploads/... | 0
# 2  | 45             | /uploads/... | 1
# 3  | 45             | /uploads/... | 2
```

### **3. Accéder aux Images**

**Dans un navigateur :**
```
http://localhost:3000/uploads/interventions/intervention-1730281234567-123456789.jpg
```

**Réponse attendue :** L'image s'affiche ✅

---

## 📊 **Vérifications Rapides**

### **✅ Checklist Installation**

```bash
# 1. Multer installé ?
npm list multer

# 2. Table créée ?
sqlite3 database.sqlite "SELECT name FROM sqlite_master WHERE type='table' AND name='intervention_images';"

# 3. Dossier uploads existe ?
ls -la uploads/interventions/

# 4. Serveur démarre sans erreur ?
npm run dev
```

---

## 🔧 **Dépannage**

### **Problème 1 : "Cannot find module 'multer'"**
```bash
npm install multer
```

### **Problème 2 : "Table intervention_images doesn't exist"**
```bash
node apply-intervention-images-migration.js
```

### **Problème 3 : "ENOENT: no such file or directory, open 'uploads/interventions'"**
```bash
mkdir -p uploads/interventions
```

### **Problème 4 : Images ne s'affichent pas**
**Vérifier dans server.js :**
```javascript
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
```

### **Problème 5 : "File too large"**
**Dans multer.js, augmenter la limite :**
```javascript
limits: {
  fileSize: 10 * 1024 * 1024, // 10MB au lieu de 5MB
}
```

---

## 📱 **Modes d'Upload Disponibles**

### **Mode Actuel : Option 1 (Multipart) ⭐**
- Upload direct des fichiers
- Performance optimale
- Recommandé pour production

### **Alternative : Option 2 (Base64)**
**Pour activer, dans `new_intervention_screen.dart` :**

```dart
// Commenter Option 1
// await _apiService.createInterventionWithImages(...)

// Décommenter Option 2
await _apiService.createInterventionWithImagesBase64(
  data: interventionData,
  images: _selectedImages.isNotEmpty ? _selectedImages : null,
);
```

**Note :** Pour Base64, le backend doit aussi être modifié (voir `IMPLEMENTATION_UPLOAD_IMAGES.md`)

---

## 📈 **Statistiques**

Après quelques jours d'utilisation, vous pouvez analyser :

```sql
-- Nombre total d'images
SELECT COUNT(*) FROM intervention_images;

-- Images par intervention
SELECT intervention_id, COUNT(*) as nb_images 
FROM intervention_images 
GROUP BY intervention_id 
ORDER BY nb_images DESC;

-- Interventions avec le plus de photos
SELECT i.id, i.title, COUNT(img.id) as nb_images
FROM interventions i
LEFT JOIN intervention_images img ON i.id = img.intervention_id
GROUP BY i.id
ORDER BY nb_images DESC
LIMIT 10;

-- Espace disque utilisé
SELECT SUM(LENGTH(image_url)) as total_images FROM intervention_images;
```

---

## 🎯 **Récapitulatif 5 Minutes**

```bash
# 1. Installer multer (30 sec)
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm install multer

# 2. Appliquer migration (30 sec)
node apply-intervention-images-migration.js

# 3. Modifier 3 fichiers (3 min)
# - models/index.js : ajouter InterventionImage
# - models/Intervention.js : ajouter association
# - controllers/intervention/interventionController.js : remplacer createIntervention

# 4. Ajouter static files dans server.js (30 sec)
# app.use('/uploads', express.static(...))

# 5. Redémarrer (30 sec)
npm run dev
```

**Total : 5 minutes ⏱️**

---

## ✅ **C'est Prêt !**

```
✅ Frontend Mobile : Upload 1-5 photos
✅ Backend API : Réception et stockage
✅ Base de données : Table intervention_images
✅ Fichiers statiques : Accessibles via /uploads
✅ Tests : Prêts à être effectués
```

**Commencez à tester dès maintenant ! 🚀**

---

**Besoin d'aide ?**
- Documentation complète : `IMPLEMENTATION_UPLOAD_IMAGES.md`
- Multi-photos : `MULTI_PHOTOS_INTERVENTION.md`
- Images simples : `AJOUT_IMAGE_INTERVENTION.md`

**Développé pour MCT Maintenance** 🔧📸✨
