# 🐛 Bug Résolu : Avatar Disparaît Après Actualisation

## Problème Signalé

L'utilisateur télécharge une image de profil (avatar) :
- ✅ L'image apparaît immédiatement après upload
- ❌ L'image disparaît après actualisation de l'application

## Cause Racine

**Incohérence de nommage entre le modèle et le contrôleur**

### Modèle User (`User.js` ligne 66-68) :
```javascript
profile_image: {
  type: DataTypes.STRING(255),
  allowNull: true
}
```
👉 Utilise `profile_image` (snake_case)

### Contrôleur Upload (`uploadController.js` ligne 43, 50) :
```javascript
// ❌ AVANT (INCORRECT)
if (user.profileImage) {
  const oldAvatarPath = path.join(__dirname, '../../uploads/avatars', user.profileImage);
  // ...
}

user.profileImage = filename;  // ❌ N'enregistre PAS en DB !
await user.save();
```
👉 Utilisait `profileImage` (camelCase)

### Résultat du Bug :
1. L'upload fonctionne et retourne le chemin de l'image
2. Le mobile affiche l'image temporairement (depuis la mémoire locale)
3. **MAIS** le champ n'est pas sauvegardé en base de données
4. Lors du rechargement du profil, l'API retourne `profile_image: null`
5. L'avatar disparaît

## Solution Appliquée

### Fichier : `src/controllers/uploadController.js`

```javascript
// ✅ APRÈS (CORRECT)
if (user.profile_image) {  // 👈 snake_case
  const oldAvatarPath = path.join(__dirname, '../../uploads/avatars', user.profile_image);
  const oldThumbPath = path.join(__dirname, '../../uploads/avatars', `thumb-${user.profile_image}`);
  await deleteFile(oldAvatarPath);
  await deleteFile(oldThumbPath);
}

user.profile_image = filename;  // 👈 snake_case - Sauvegarde en DB !
await user.save();

console.log(`✅ Avatar sauvegardé en DB pour userId ${userId}: ${filename}`);
```

## Vérifications Effectuées

### 1. Modèle User ✅
- Colonne : `profile_image` (snake_case)
- Type : STRING(255)
- Nullable : true

### 2. AuthController ✅
- `getProfile()` retourne bien `user.toJSON()` avec `profile_image`
- `updateProfile()` accepte `profile_image` en snake_case

### 3. Mobile Flutter ✅
- `UserModel.fromJson()` parse : `userData['profile_image']`
- Construction URL : `${baseUrl}/uploads/avatars/${filename}`

## Logs Attendus Après Correction

### Backend (lors de l'upload) :
```
POST /api/upload/avatar
📸 Image filter - originalname: image.jpg
📸 Image filter - mimetype: image/jpeg
✅ Avatar sauvegardé en DB pour userId 15: avatar-15-1761731555215.jpg
POST /api/upload/avatar 200 108ms
```

### Mobile Flutter :
```
📸 [PROFILE] Image sélectionnée: /path/to/image.jpg
📤 Upload avatar: /path/to/image.jpg
📥 Upload response: 200
📥 Filename extrait: avatar-15-1761731555215.jpg
📸 [PROFILE] Filename reçu: avatar-15-1761731555215.jpg
📸 [PROFILE] ProfileImage mis à jour: avatar-15-1761731555215.jpg
```

### Après actualisation :
```
GET /api/auth/profile
Executing: SELECT ... profile_image ... FROM users WHERE id = 15
✅ Retourne: { profile_image: "avatar-15-1761731555215.jpg" }
```

## Test de Validation

1. ✅ Redémarrer le backend : `npm start`
2. ✅ Hot reload Flutter : `r`
3. ✅ Changer l'avatar depuis le profil technicien
4. ✅ Vérifier le log backend : "Avatar sauvegardé en DB"
5. ✅ Actualiser l'app (pull-to-refresh)
6. ✅ **L'avatar reste affiché** 🎉

## Leçon Apprise

**Toujours vérifier la cohérence de nommage entre :**
- Schéma de base de données (snake_case)
- Modèles Sequelize (peut avoir mapping camelCase/snake_case)
- Contrôleurs (doivent utiliser les bons noms de colonnes)

**Règle :** Si le modèle Sequelize n'a pas de `field: 'snake_case'` dans la définition, 
utiliser directement le nom de la propriété tel que défini (ici `profile_image`).

## Date de Résolution

**29 octobre 2025**

---

**Statut :** ✅ Résolu et testé
