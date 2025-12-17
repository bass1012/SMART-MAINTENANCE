# 📸 Fonctionnalité Multi-Photos pour Interventions

## ✅ Implémenté - Jusqu'à 5 Photos par Intervention

Les clients peuvent maintenant ajouter **jusqu'à 5 photos** lors de la création d'une intervention.

---

## 🎨 **Interface Utilisateur**

### **Sans Photo**
```
┌─────────────────────────────────────┐
│ Photos (optionnelles)               │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [📷 Appareil]  [🖼️ Galerie]    │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
Ajoutez jusqu'à 5 photos... (0/5)
```

### **Avec 3 Photos**
```
┌─────────────────────────────────────┐
│ Photos (optionnelles)    [3/5]      │  ← Badge compteur
├─────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐            │
│ │ [X] │ │ [X] │ │ [X] │ ← Scroll → │  ← Grille horizontale
│ │ IMG │ │ IMG │ │ IMG │            │
│ └─────┘ └─────┘ └─────┘            │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [📷 Appareil]  [🖼️ Galerie]    │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
Ajoutez jusqu'à 5 photos... (3/5)
```

### **Limite Atteinte (5 Photos)**
```
┌─────────────────────────────────────┐
│ Photos (optionnelles)    [5/5]      │
├─────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐... │
│ │ [X] │ │ [X] │ │ [X] │ │ [X] │→  │
│ │ IMG │ │ IMG │ │ IMG │ │ IMG │   │
│ └─────┘ └─────┘ └─────┘ └─────┘   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [📷] [🖼️] (désactivés - gris)  │ │  ← Boutons désactivés
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
Maximum 5 photos autorisées
```

---

## 🎯 **Fonctionnalités**

### **1. Ajout de Photos** ✅
- 📸 **Caméra** : Prendre une photo directement
- 🖼️ **Galerie** : Sélectionner depuis les photos existantes
- ➕ **Ajouter progressivement** : Jusqu'à 5 photos

### **2. Gestion des Photos** ✅
- 👁️ **Preview en grille** : Scrollable horizontalement
- 🗑️ **Suppression individuelle** : Bouton X rouge sur chaque photo
- 🔢 **Compteur visuel** : Badge vert montrant X/5
- 🚫 **Limite stricte** : Maximum 5 photos

### **3. UX Optimisée** ✅
- ✅ Boutons **désactivés automatiquement** après 5 photos
- ✅ Message d'alerte si tentative au-delà de la limite
- ✅ Compteur dynamique dans le texte d'aide
- ✅ Images carrées 120x120px

---

## 🔧 **Paramètres Techniques**

### **Constantes**
```dart
static const int _maxImages = 5;  // Maximum de photos
```

### **Variables d'État**
```dart
List<File> _selectedImages = [];  // Liste des images
```

### **Compression Automatique**
```dart
imageQuality: 80,      // 80% de qualité
maxWidth: 1920,        // Max largeur
maxHeight: 1080,       // Max hauteur
```

---

## 📐 **Design Détaillé**

### **Badge Compteur**
- **Couleur** : Vert MCT (#0a543d)
- **Format** : "X/5" en blanc
- **Position** : À droite du titre
- **Visible** : Uniquement si photos > 0

### **Grille d'Images**
- **Type** : ListView horizontal
- **Hauteur** : 120px
- **Largeur par image** : 120px (carré)
- **Espacement** : 8px entre images
- **Bordures** : Arrondies (8px radius)

### **Bouton Suppression**
- **Position** : Top-right de chaque image
- **Style** : Cercle rouge avec icône X blanche
- **Taille** : 24px de diamètre
- **Action** : Retire l'image de la liste

### **Boutons Ajout**
- **État Normal** : Vert MCT (#0a543d)
- **État Désactivé** : Gris (automatique après 5 photos)
- **Layout** : 2 boutons côte à côte, 50% chacun

---

## 💡 **Logique de Validation**

### **Avant d'Ajouter une Photo**
```dart
if (_selectedImages.length >= _maxImages) {
  // Afficher message d'erreur orange
  // Annuler l'action
  return;
}
```

### **État des Boutons**
```dart
onPressed: _selectedImages.length < _maxImages 
    ? _pickImageFromCamera   // Actif
    : null                   // Désactivé (gris)
```

---

## 🧪 **Tests à Effectuer**

### **Test 1 : Ajout Progressif**
1. Ouvrir nouvelle intervention
2. Ajouter photo 1 → ✅ Voir preview + badge "1/5"
3. Ajouter photo 2 → ✅ Voir 2 photos + badge "2/5"
4. Ajouter photo 3 → ✅ Voir 3 photos + badge "3/5"
5. Vérifier le scroll horizontal

### **Test 2 : Limite Maximale**
1. Ajouter 5 photos
2. ✅ Badge affiche "5/5"
3. ✅ Boutons désactivés (gris)
4. Cliquer sur bouton → ✅ Message "Maximum 5 photos"
5. Texte d'aide → ✅ "(5/5)"

### **Test 3 : Suppression**
1. Avoir 5 photos (limite atteinte)
2. Supprimer une photo → ✅ Badge devient "4/5"
3. ✅ Boutons redeviennent actifs (verts)
4. Ajouter une nouvelle photo → ✅ Fonctionne
5. Supprimer toutes → ✅ Badge disparaît

### **Test 4 : Mix Caméra + Galerie**
1. Prendre 2 photos avec caméra
2. Ajouter 3 photos depuis galerie
3. ✅ 5 photos mélangées
4. ✅ Ordre d'ajout préservé

### **Test 5 : Scroll Horizontal**
1. Ajouter 5 photos
2. ✅ Swiper horizontalement
3. ✅ Toutes les photos visibles en scrollant

---

## 📱 **Cas d'Usage Concrets**

### **Exemple 1 : Fuite d'Eau Multiple**
```
Photo 1: Vue d'ensemble de la pièce
Photo 2: Fuite principale (gros plan)
Photo 3: Taches au plafond
Photo 4: Compteur d'eau
Photo 5: Dégâts au sol
```

### **Exemple 2 : Panne Climatisation**
```
Photo 1: Code erreur affiché
Photo 2: Unité extérieure
Photo 3: Unité intérieure
Photo 4: Tableau électrique
Photo 5: Installation complète
```

### **Exemple 3 : Installation**
```
Photo 1: Emplacement souhaité
Photo 2: Mur de fixation
Photo 3: Arrivée électrique
Photo 4: Vue d'ensemble pièce
Photo 5: Accès technique
```

---

## 🎯 **Avantages Multi-Photos**

✅ **Vision complète** : Contexte avant + détails
✅ **Diagnostic précis** : Plusieurs angles du problème
✅ **Meilleure préparation** : Technicien voit tous les aspects
✅ **Moins d'allers-retours** : Tout le matériel du premier coup
✅ **Documentation riche** : Historique visuel complet
✅ **Flexibilité** : 1 à 5 photos selon besoin

---

## 📊 **Comparaison Avant/Après**

### **Avant (1 photo)**
```
❌ Vision limitée
❌ Contexte incomplet
❌ Risque d'oublier détails
```

### **Après (jusqu'à 5)**
```
✅ Vue panoramique + détails
✅ Contexte complet
✅ Documentation exhaustive
✅ Meilleur diagnostic
```

---

## 🔄 **Flux d'Utilisation**

```
Ouvrir formulaire
  ↓
Descendre à "Photos (optionnelles)"
  ↓
Cliquer "📷 Appareil photo"
  ↓
Prendre photo → Voir dans grille [1/5]
  ↓
Cliquer "🖼️ Galerie"
  ↓
Sélectionner photo → Grille [2/5]
  ↓
Répéter jusqu'à satisfaction (max 5)
  ↓
Cliquer [X] pour retirer une photo
  ↓
Soumettre avec toutes les photos
```

---

## 📤 **Backend (À Implémenter)**

### **1. Modèle de Données**

**Option A : Champ JSON**
```javascript
// Dans Intervention.js
images: {
  type: DataTypes.JSON,
  allowNull: true,
  defaultValue: []
}

// Exemple de données :
{
  "images": [
    "/uploads/interventions/img1.jpg",
    "/uploads/interventions/img2.jpg",
    "/uploads/interventions/img3.jpg"
  ]
}
```

**Option B : Table Séparée** (Recommandé)
```javascript
// Nouveau modèle InterventionImage.js
module.exports = (sequelize, DataTypes) => {
  const InterventionImage = sequelize.define('InterventionImage', {
    intervention_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    image_url: {
      type: DataTypes.STRING,
      allowNull: false
    },
    order: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    }
  });
  
  return InterventionImage;
};
```

### **2. Upload Multiple avec Multer**
```javascript
// Route
router.post('/interventions', 
  authenticateToken, 
  upload.array('images', 5),  // Max 5 images
  async (req, res) => {
    try {
      const interventionData = req.body;
      const intervention = await Intervention.create(interventionData);
      
      // Sauvegarder les images
      if (req.files && req.files.length > 0) {
        const imagePromises = req.files.map((file, index) => {
          return InterventionImage.create({
            intervention_id: intervention.id,
            image_url: `/uploads/interventions/${file.filename}`,
            order: index
          });
        });
        
        await Promise.all(imagePromises);
      }
      
      res.json({ success: true, data: intervention });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);
```

### **3. ApiService Mobile**
```dart
Future<void> createInterventionWithImages({
  required Map<String, dynamic> data,
  List<File>? images,
}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/interventions'),
  );
  
  request.headers.addAll({
    'Authorization': 'Bearer $token',
  });
  
  // Données texte
  data.forEach((key, value) {
    request.fields[key] = value.toString();
  });
  
  // Images multiples
  if (images != null && images.isNotEmpty) {
    for (int i = 0; i < images.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',  // Nom du champ pour array
          images[i].path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }
  }
  
  var response = await request.send();
  // Traiter réponse
}
```

---

## 🗄️ **Structure Base de Données**

### **Table `intervention_images`**
```sql
CREATE TABLE intervention_images (
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

---

## 📊 **Statistiques Potentielles**

- Nombre moyen de photos par intervention
- Photos les plus utiles (feedback techniciens)
- Temps de diagnostic réduit grâce aux photos
- Taux de résolution au premier passage

---

## 🚀 **Optimisations Futures**

1. **Compression côté serveur** : Sharp/ImageMagick
2. **Miniatures** : Générer thumbnails (200x200)
3. **Zoom** : Tap pour agrandir en plein écran
4. **Réorganisation** : Drag & drop pour changer l'ordre
5. **CDN** : Stockage AWS S3 / Cloudinary
6. **Annotations** : Dessiner sur les photos
7. **OCR** : Extraction texte des codes erreur
8. **AI** : Pré-diagnostic automatique par IA

---

## 📝 **Fichiers Modifiés**

| Fichier | Statut |
|---------|--------|
| `new_intervention_screen.dart` | ✅ Multi-photos implémenté |
| `api_service.dart` | ⏳ À modifier pour multipart |
| `InterventionImage.js` | ⏳ Nouveau modèle à créer |
| `interventionController.js` | ⏳ Upload multiple à ajouter |

---

## ✅ **Checklist Complète**

### **Frontend Mobile**
- [x] Liste d'images au lieu d'une seule
- [x] Limite de 5 photos
- [x] Grille scrollable horizontale
- [x] Badge compteur X/5
- [x] Boutons désactivés après limite
- [x] Suppression individuelle
- [x] Messages de validation
- [x] Texte d'aide dynamique
- [ ] Modification ApiService pour multipart

### **Backend**
- [ ] Créer modèle InterventionImage
- [ ] Migration base de données
- [ ] Route upload multiple (multer)
- [ ] Validation 5 images max
- [ ] Stockage organisé par intervention
- [ ] Endpoint récupération images

### **Dashboard Web**
- [ ] Galerie d'images dans détails
- [ ] Lightbox pour agrandissement
- [ ] Upload multiple en modification
- [ ] Suppression d'images

---

**Date de création :** 30 octobre 2025  
**Statut :** ✅ Interface mobile complète | ⏳ Backend à implémenter  
**Limite :** 5 photos maximum par intervention  
**Taille par photo :** ~200-500 KB après compression  
**Taille totale max :** ~2.5 MB par intervention  

**Développé pour MCT Maintenance** 🔧📸✨
