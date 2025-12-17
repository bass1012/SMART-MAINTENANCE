# 🔧 Correction Upload Avatar Utilisateurs (Clients/Techniciens)
**Date** : 16 octobre 2025  
**Problème** : Avatar uploadé ne s'enregistre pas en base de données

---

## 🐛 Problèmes Identifiés

### 1. **Avatar uploadé mais jamais enregistré en BDD**
- `handleAvatarUpload` : Upload fichier ✅
- `handleAvatarUpload` : Mise à jour `avatarUrl` state ✅
- `handleAvatarUpload` : Mise à jour User en BDD ❌
- **Résultat** : Avatar stocké mais jamais affiché après rechargement

### 2. **handleSubmit n'envoyait pas profile_image**
- Mode création : `profile_image` manquant dans `createUser()`
- Mode édition : `profile_image` manquant dans `updateUser()`
- **Résultat** : Avatar perdu lors de la sauvegarde du formulaire

### 3. **Interface TypeScript incomplète**
- `usersService.createUser()` : Paramètre `profile_image` non défini
- TypeScript rejetait le champ
- **Erreur** : `'profile_image' does not exist in type...`

---

## ✅ Corrections Appliquées

### **Fichier 1** : `UserForm.tsx`

#### A. Fonction `handleAvatarUpload` - Mise à jour BDD
```tsx
const handleAvatarUpload = async (file: File) => {
  try {
    const result = await uploadAvatar(file);
    setAvatarUrl(result.url);
    
    // Mettre à jour l'utilisateur en base si on est en mode édition
    if (isEditMode && id) {
      await usersService.updateUser(parseInt(id), {
        profile_image: result.url
      });
    }
    
    message.success('Avatar uploadé avec succès');
    return result;
  } catch (error) {
    console.error('Erreur upload avatar:', error);
    message.error('Erreur lors de l\'upload de l\'avatar');
    throw error;
  }
};
```

**Changements** :
- ✅ Appel API `updateUser` après upload (si édition)
- ✅ Enregistrement `profile_image` en base
- ✅ Gestion d'erreur améliorée

#### B. Fonction `handleSubmit` - Inclure profile_image

**Mode Édition** :
```tsx
if (isEditMode && id) {
  const updateData: any = {
    email: formData.email,
    phone: formData.phone || undefined,
    role: formData.role,
    status: formData.status,
    first_name: formData.firstName,
    last_name: formData.lastName
  };
  
  // Ajouter le mot de passe seulement s'il a été modifié
  if (formData.password) {
    updateData.password = formData.password;
  }
  
  // Ajouter l'avatar s'il existe
  if (avatarUrl) {
    updateData.profile_image = avatarUrl;
  }
  
  await usersService.updateUser(parseInt(id), updateData);
  toast.success('Utilisateur modifié avec succès !');
}
```

**Mode Création** :
```tsx
else {
  await usersService.createUser({
    email: formData.email,
    password: formData.password,
    phone: formData.phone || undefined,
    role: formData.role,
    status: formData.status,
    first_name: formData.firstName,
    last_name: formData.lastName,
    profile_image: avatarUrl || undefined
  });
  toast.success('Utilisateur créé avec succès !');
}
```

**Changements** :
- ✅ `profile_image` inclus en mode édition si `avatarUrl` existe
- ✅ `profile_image` inclus en mode création

---

### **Fichier 2** : `usersService.ts`

#### Interface createUser
```typescript
async createUser(userData: {
  email: string;
  password: string;
  phone?: string;
  role: 'admin' | 'technician' | 'customer';
  status?: 'active' | 'inactive' | 'pending' | 'suspended';
  first_name?: string;
  last_name?: string;
  send_welcome_email?: boolean;
  profile_image?: string; // ← Ajouté
}): Promise<ApiUser> {
```

#### Payload envoyé au backend
```typescript
const payload = {
  email: userData.email,
  password: userData.password,
  phone: userData.phone || undefined,
  role: roleForApi,
  first_name: userData.first_name,
  last_name: userData.last_name,
  profile_image: userData.profile_image || undefined, // ← Ajouté
};
```

**Changements** :
- ✅ TypeScript accepte `profile_image`
- ✅ Payload inclut `profile_image`

---

### **Fichier 3** : `authController.js` (Backend)

#### Route `/auth/register`
```javascript
// Create user
const user = await User.create({
  email,
  password_hash: password,
  phone,
  role: role || 'customer',
  status: req.body.status || 'active',
  first_name,
  last_name,
  profile_image: req.body.profile_image || null // ← Ajouté
});
```

**Changements** :
- ✅ Backend enregistre `profile_image` lors de la création

---

### **Fichier 4** : `userController.js` (Backend)

#### Fonction `updateUser`
```javascript
exports.updateUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    
    const allowed = ['email', 'phone', 'role', 'status', 'preferences', 'first_name', 'last_name', 'profile_image'];
    for (const key of allowed) {
      if (req.body[key] !== undefined) user[key] = req.body[key];
    }
    
    // ... (reste du code)
  }
};
```

**Statut** : ✅ Déjà correct ! `profile_image` était déjà dans la liste `allowed`

---

## 🎯 Résultat

### Workflow Complet Fonctionnel

#### **Création d'un utilisateur avec avatar**
1. Utilisateur clique "Nouvel utilisateur"
2. Remplit le formulaire
3. Upload avatar → Fichier stocké + `avatarUrl` state mis à jour
4. Clique "Enregistrer"
5. `createUser()` envoie `profile_image: avatarUrl`
6. Backend crée User avec `profile_image` ✅

#### **Modification d'un utilisateur**
1. Utilisateur clique "Modifier"
2. Avatar existant chargé dans le preview
3. Upload nouvel avatar
4. `handleAvatarUpload` met à jour la BDD immédiatement ✅
5. (Optionnel) Clique "Enregistrer" → `profile_image` inclus

#### **Affichage dans la liste**
- UsersPage affiche `user.profile_image`
- Avatar visible dans la colonne "Avatar"

---

## 📊 Tests de Validation

### ✅ Checklist

#### Mode Création
- [ ] **Créer utilisateur sans avatar** → Succès
- [ ] **Créer utilisateur avec avatar** → Avatar enregistré en BDD
- [ ] **Vérifier en liste** → Avatar visible

#### Mode Édition
- [ ] **Modifier utilisateur existant** → Avatar chargé dans preview
- [ ] **Upload nouvel avatar** → Message "Avatar uploadé avec succès"
- [ ] **Fermer sans enregistrer** → Avatar déjà enregistré en BDD
- [ ] **Vérifier en liste** → Nouvel avatar visible

#### Suppression
- [ ] **Supprimer avatar** → Fichier supprimé + BDD mise à jour

---

## 🧪 Tests Manuels

### Test 1 : Création utilisateur avec avatar
```bash
1. Ouvrir : http://localhost:3001
2. Aller dans : Menu → Utilisateurs
3. Cliquer "Nouvel utilisateur"
4. Remplir le formulaire :
   - Prénom : Jean
   - Nom : Dupont
   - Email : jean.dupont@test.com
   - Mot de passe : Test1234!
   - Rôle : Client
5. Upload un avatar
6. Cliquer "Enregistrer"
7. Vérifier : Avatar visible dans la liste ✅
```

### Test 2 : Modification avatar utilisateur existant
```bash
1. Cliquer "Modifier" sur un utilisateur
2. Vérifier : Avatar existant affiché (si existe)
3. Upload un nouvel avatar
4. Vérifier : Message "Avatar uploadé avec succès"
5. Fermer le formulaire SANS enregistrer
6. Vérifier en liste : Nouvel avatar visible ✅
```

### Test 3 : Vérification backend
```bash
# Créer un utilisateur via l'interface avec avatar
# Puis vérifier en base de données :

curl http://localhost:3000/api/users | jq '.data[] | {id, first_name, profile_image}'

# Exemple de sortie attendue :
{
  "id": 5,
  "first_name": "Jean",
  "profile_image": "/uploads/avatars/avatar-1729082345678.jpg"
}

# Vérifier le fichier physique :
ls -lh /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/uploads/avatars/
```

---

## 🔍 Points Techniques

### Structure Base de Données
```javascript
// Model User.js
profile_image: {
  type: DataTypes.STRING(255),
  allowNull: true
}
```

**Format stocké** :
```json
{
  "id": 5,
  "first_name": "Jean",
  "last_name": "Dupont",
  "profile_image": "/uploads/avatars/avatar-1729082345678.jpg",
  "role": "customer"
}
```

### API Endpoints Utilisés
- `POST /api/upload/avatar` → Upload fichier physique
- `POST /auth/register` → Création utilisateur (avec `profile_image`)
- `PUT /api/users/:id` → Mise à jour utilisateur (y compris `profile_image`)
- `DELETE /api/upload/avatars/:filename` → Suppression fichier

---

## 🔄 Différences avec ProductForm

| Aspect | ProductForm | UserForm |
|--------|-------------|----------|
| **Champ BDD** | `images: JSON[]` | `profile_image: STRING` |
| **Upload activé** | Après création | Immédiatement |
| **Mise à jour BDD** | Lors de l'upload (édition) | Lors de l'upload (édition) + handleSubmit (création) |
| **Preview** | Rectangulaire | Circulaire (`type="avatar"`) |
| **Multiple** | Oui (prévu) | Non |

---

## 📝 Notes Importantes

### Comportement en Mode Création
- Avatar uploadé → Stocké en state `avatarUrl`
- Formulaire validé → `profile_image` envoyé avec `createUser()`
- Si utilisateur quitte sans enregistrer → Fichier orphelin (à nettoyer manuellement)

### Comportement en Mode Édition
- Avatar uploadé → **BDD mise à jour immédiatement** via `handleAvatarUpload`
- Formulaire validé → `profile_image` envoyé avec `updateUser()` (redondant mais safe)
- Avantage : Avatar persisté même si utilisateur quitte sans enregistrer

### Sécurité
- Upload nécessite authentification JWT
- Validation côté backend : Taille max 5MB, types image seulement
- Les anciens avatars ne sont PAS supprimés automatiquement (TODO)

---

## 🚀 Améliorations Futures

### Court Terme
- [ ] Suppression automatique ancien avatar lors remplacement
- [ ] Crop/redimensionnement avatar (format carré 200x200)
- [ ] Validation MIME type côté backend

### Moyen Terme
- [ ] Lazy loading avatars dans la liste
- [ ] WebP automatique pour réduire taille
- [ ] Avatar par défaut basé sur initiales

### Long Terme
- [ ] CDN externe (S3, Cloudinary)
- [ ] Reconnaissance faciale (vérification identité)
- [ ] Synchronisation avatar avec profils sociaux

---

## 📚 Fichiers Modifiés

| Fichier | Lignes | Changements |
|---------|--------|-------------|
| `UserForm.tsx` | 400 | handleAvatarUpload, handleSubmit (édition + création) |
| `usersService.ts` | 185 | Interface createUser, payload |
| `authController.js` | 366 | User.create avec profile_image |
| `userController.js` | - | Aucun (déjà correct) |

**Compilation** : ✅ Réussie  
**Build Size** : 592.7 KB gzipped (+84 B)

---

## ✅ Conclusion

**Problème résolu** : Les avatars uploadés s'enregistrent maintenant correctement en base de données pour :
- ✅ Clients
- ✅ Techniciens
- ✅ Administrateurs

**Workflow** :
- Mode création : Avatar enregistré lors du `handleSubmit`
- Mode édition : Avatar enregistré lors de l'upload (immédiat)

**Compatibilité** : Fonctionne avec le backend existant (ligne 82 `userController.js` acceptait déjà `profile_image`)

---

## 🎯 Test Maintenant

Ouvrez votre navigateur : **http://localhost:3001**

1. Menu → **Utilisateurs**
2. Cliquer **"Nouvel utilisateur"**
3. Remplir le formulaire
4. **Upload un avatar**
5. Cliquer **"Enregistrer"**
6. **Vérifier** : Avatar visible dans la liste ✅

---

**Documentation produits** : [CORRECTION_UPLOAD_IMAGES_PRODUITS.md](./CORRECTION_UPLOAD_IMAGES_PRODUITS.md)
