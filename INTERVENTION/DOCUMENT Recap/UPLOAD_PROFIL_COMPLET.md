# 📸 Upload et Affichage Photo de Profil - Solution Complète

## 🎯 Résumé

Implémentation complète de l'upload et de l'affichage de la photo de profil dans l'application mobile Flutter MCT Maintenance.

---

## ✅ Fonctionnalités Implémentées

### **1. Upload de l'Image**
- ✅ Sélection depuis la caméra ou la galerie
- ✅ Redimensionnement automatique (512x512)
- ✅ Compression (85% qualité)
- ✅ Upload multipart avec MIME type explicite
- ✅ Sauvegarde sur le serveur

### **2. Affichage de l'Image**
- ✅ Écran de profil (ProfileScreen)
- ✅ Menu latéral (Drawer)
- ✅ Construction automatique de l'URL complète
- ✅ Gestion des erreurs avec fallback sur initiales

---

## 🔧 Corrections Appliquées

### **Problème 1 : MIME Type Non Détecté**

**Cause :** Flutter ne détectait pas toujours le bon MIME type

**Solution :**
```dart
// Détection explicite du MIME type
final extension = imagePath.toLowerCase().split('.').last;
String mimeType;
switch (extension) {
  case 'jpg':
  case 'jpeg':
    mimeType = 'image/jpeg';
    break;
  case 'png':
    mimeType = 'image/png';
    break;
  // ...
}

// Upload avec MIME type explicite
request.files.add(await http.MultipartFile.fromPath(
  'avatar',
  imagePath,
  contentType: http_parser.MediaType.parse(mimeType),
));
```

---

### **Problème 2 : Backend Rejetait l'Image**

**Cause :** Filtre trop strict (AND au lieu de OR)

**Solution :**
```javascript
// Backend - uploadRoutes.js
const imageFilter = (req, file, cb) => {
  const allowedExtensions = /jpeg|jpg|png|gif|webp/;
  const allowedMimetypes = /image\/(jpeg|jpg|png|gif|webp)/;
  
  const extname = allowedExtensions.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedMimetypes.test(file.mimetype);
  
  // OR au lieu de AND
  if (mimetype || extname) {
    return cb(null, true);
  } else {
    cb(new Error('Seules les images sont autorisées'));
  }
};
```

---

### **Problème 3 : Format de Réponse**

**Cause :** Flutter cherchait `data['data']['url']` mais backend retournait `data['url']`

**Solution :**
```dart
if (response.statusCode == 200 || response.statusCode == 201) {
  final data = json.decode(response.body);
  // Gestion des deux formats
  if (data['data'] != null) {
    return data['data']['url'] ?? data['data']['path'] ?? '';
  } else {
    return data['url'] ?? data['path'] ?? '';
  }
}
```

---

### **Problème 4 : Image Pas Affichée**

**Cause :** URL relative au lieu d'URL complète

**Solution :**
```dart
// ProfileScreen et CustomDrawer
final imageUrl = _user!.profileImage!.startsWith('http')
    ? _user!.profileImage!
    : '${AppConfig.baseUrl}${_user!.profileImage!}';

Image.network(
  imageUrl,  // URL complète : http://localhost:3000/uploads/avatars/...
  errorBuilder: (context, error, stackTrace) {
    print('❌ Erreur chargement image: $error');
    print('🔗 URL tentée: $imageUrl');
    return _buildInitialsAvatar();
  },
)
```

---

## 📁 Fichiers Modifiés

### **Backend**

**1. `/src/routes/uploadRoutes.js`**
- Filtre d'images amélioré (OR au lieu de AND)
- Regex MIME type plus précise
- Logs de debug

---

### **Flutter**

**1. `/lib/services/api_service.dart`**
- Import `http_parser`
- Méthode `uploadAvatar()` avec MIME type explicite
- Gestion des deux formats de réponse

**2. `/lib/screens/customer/profile_screen.dart`**
- Import `AppConfig`
- Construction URL complète pour l'affichage
- Logs de debug

**3. `/lib/widgets/common/custom_drawer.dart`**
- Import `AppConfig`
- Construction URL complète pour l'affichage
- Logs de debug

---

## 🔄 Flux Complet

### **1. Sélection de l'Image**

```
Utilisateur clique sur 📷
  ↓
ImagePicker : Caméra ou Galerie
  ↓
Image sélectionnée : /tmp/image_picker_XXX.jpg
  ↓
Redimensionnement : 512x512
  ↓
Compression : 85%
```

---

### **2. Upload**

```
Détection extension : jpg
  ↓
MIME type : image/jpeg
  ↓
POST /api/upload/avatar
  Headers: Authorization: Bearer {token}
  Body: multipart/form-data
    - avatar: [fichier]
    - contentType: image/jpeg
  ↓
Backend valide (extension OU mimetype)
  ↓
Sauvegarde : /uploads/avatars/avatar-9-1761207572402.jpg
  ↓
Réponse : {"url": "/uploads/avatars/avatar-9-1761207572402.jpg"}
```

---

### **3. Mise à Jour du Profil**

```
Extraction URL : "/uploads/avatars/avatar-9-1761207572402.jpg"
  ↓
PUT /api/auth/profile
  Body: {
    first_name: "Bakary Madou",
    last_name: "CISSE",
    profile_image: "/uploads/avatars/avatar-9-1761207572402.jpg"
  }
  ↓
Backend sauvegarde dans users.profile_image
  ↓
Réponse : {"success": true, "data": {...}}
```

---

### **4. Affichage**

```
GET /api/auth/profile
  ↓
Réponse : {
  "profile_image": "/uploads/avatars/avatar-9-1761207572402.jpg"
}
  ↓
Construction URL complète :
  "/uploads/avatars/..." 
    → "http://localhost:3000/uploads/avatars/avatar-9-1761207572402.jpg"
  ↓
Image.network("http://localhost:3000/uploads/avatars/...")
  ↓
✅ Image affichée dans ProfileScreen
✅ Image affichée dans Drawer
```

---

## 🧪 Test Complet

### **1. Upload**

```bash
flutter run
```

1. Profil → ✏️ (éditer)
2. 📷 sur l'avatar
3. Sélectionner une image
4. ✅ Aperçu immédiat
5. Enregistrer
6. ✅ Message de succès

**Logs attendus :**
```
flutter: 📤 Upload avatar: /tmp/image_picker_XXX.jpg
flutter: 📤 Extension: jpg, MIME type: image/jpeg
flutter: 📥 Upload response: 200
flutter: 📥 Upload body: {"url": "/uploads/avatars/avatar-9-1761207572402.jpg"}
flutter: 🔵 API Request: PUT /api/auth/profile
flutter: 📦 Request Body: {..., profile_image: /uploads/avatars/avatar-9-1761207572402.jpg}
flutter: 🟢 API Response (200): {"success": true, ...}
```

---

### **2. Affichage**

**ProfileScreen :**
1. Aller sur Profil
2. ✅ Avatar personnalisé visible
3. ✅ Image ronde

**Drawer :**
1. Ouvrir le menu latéral (☰)
2. ✅ Avatar personnalisé visible en haut
3. ✅ Image ronde

**Logs attendus :**
```
flutter: 🔗 URL tentée: http://localhost:3000/uploads/avatars/avatar-9-1761207572402.jpg
✅ Image chargée
```

---

### **3. Persistance**

1. Fermer l'app
2. Rouvrir l'app
3. ✅ Avatar toujours visible
4. ✅ Image chargée depuis le serveur

---

### **4. Vérification Serveur**

**Fichier :**
```bash
ls -la /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/uploads/avatars/
```
✅ `avatar-9-1761207572402.jpg` présent

**URL directe :**
```
http://localhost:3000/uploads/avatars/avatar-9-1761207572402.jpg
```
✅ Image s'affiche dans le navigateur

**Base de données :**
```sql
SELECT id, email, profile_image FROM users WHERE id = 9;
```
✅ `profile_image: "/uploads/avatars/avatar-9-1761207572402.jpg"`

---

## 📊 Résumé des Corrections

| Problème | Fichier | Solution |
|----------|---------|----------|
| MIME type non détecté | `api_service.dart` | MIME type explicite |
| Backend rejette l'image | `uploadRoutes.js` | Condition OR |
| Format de réponse | `api_service.dart` | Gestion des 2 formats |
| Image pas affichée (profil) | `profile_screen.dart` | URL complète |
| Image pas affichée (drawer) | `custom_drawer.dart` | URL complète |

---

## ✅ Résultat Final

**Upload :**
- ✅ Sélection caméra/galerie
- ✅ Redimensionnement automatique
- ✅ Compression
- ✅ MIME type correct
- ✅ Upload réussi (200)
- ✅ Sauvegarde serveur
- ✅ Mise à jour profil

**Affichage :**
- ✅ ProfileScreen
- ✅ Drawer
- ✅ URL complète construite
- ✅ Image visible
- ✅ Persistance

**Gestion des erreurs :**
- ✅ Logs de debug
- ✅ Fallback sur initiales
- ✅ Messages d'erreur clairs

**L'upload et l'affichage de la photo de profil fonctionnent parfaitement !** 📸✨

---

## 🌐 Production

Pour la production, modifier `AppConfig.baseUrl` :

```dart
// Développement
static const String baseUrl = 'http://localhost:3000';

// Production
static const String baseUrl = 'https://api.mct-maintenance.com';
```

Les URLs seront automatiquement construites avec le bon domaine !
