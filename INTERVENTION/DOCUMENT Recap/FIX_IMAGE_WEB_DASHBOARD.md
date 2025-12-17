# 🌐 Fix : Affichage Image de Profil - Dashboard Web

## ❌ Problème

L'image de profil n'est pas affichée sur le dashboard web (React).

---

## 🔍 Cause

Même problème que sur mobile : **URL relative** au lieu d'URL complète.

```tsx
// Avant
<Avatar src={currentUser?.profile_image} />
// profile_image = "/uploads/avatars/avatar-9-1761207572402.jpg"
// ❌ URL relative ne fonctionne pas
```

---

## ✅ Solution

Le dashboard a déjà une fonction `getImageUrl()` dans `uploadService.ts` qui construit l'URL complète !

### **Fonction Existante**

**Fichier :** `/src/services/uploadService.ts`

```typescript
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

export const getImageUrl = (path: string): string => {
  if (!path) return '';
  if (path.startsWith('http')) return path;
  return `${API_BASE_URL}${path}`;
};
```

**Utilisation :**
```typescript
import { getImageUrl } from '../services/uploadService';

// Avant
<Avatar src={currentUser?.profile_image} />

// Après
<Avatar src={currentUser?.profile_image ? getImageUrl(currentUser.profile_image) : undefined} />
```

---

## 📁 Fichiers Modifiés

### **1. Layout Principal**

**Fichier :** `/src/components/Layout/NewLayout.tsx`

**Ligne 25 :** Import
```typescript
import { getImageUrl } from '../../services/uploadService';
```

**Ligne 343 :** Utilisation
```typescript
<Avatar 
  sx={{ width: { xs: 32, sm: 40 }, height: { xs: 32, sm: 40 } }}
  src={currentUser?.profile_image ? getImageUrl(currentUser.profile_image) : undefined}
>
  {(!currentUser?.profile_image && (
    currentUser?.first_name?.charAt(0) || 
    currentUser?.name?.charAt(0) || 
    'A'
  ))}
</Avatar>
```

---

### **2. Page Paramètres**

**Fichier :** `/src/pages/ParametresPage.tsx`

**Ligne 27 :** Import
```typescript
import { getImageUrl } from '../services/uploadService';
```

**Ligne 200 :** Utilisation
```typescript
<Avatar 
  size={100} 
  src={avatarUrl ? getImageUrl(avatarUrl) : (currentUser?.profile_image ? getImageUrl(currentUser.profile_image) : undefined)}
  icon={!avatarUrl && !currentUser?.profile_image && <UserOutlined />} 
  style={{ 
    marginBottom: 16, 
    border: '3px solid #f0f0f0',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
  }}
/>
```

---

## 🔄 Transformation de l'URL

### **Exemple**

**Entrée :**
```
profile_image: "/uploads/avatars/avatar-9-1761207572402.jpg"
```

**Sortie :**
```typescript
getImageUrl("/uploads/avatars/avatar-9-1761207572402.jpg")
  ↓
"http://localhost:3000/uploads/avatars/avatar-9-1761207572402.jpg"
```

---

## 🧪 Test

### **1. Relancer le Dashboard**

```bash
cd mct-maintenance-dashboard
npm start
```

---

### **2. Vérifier l'Affichage**

**Layout (Header) :**
1. Ouvrir le dashboard
2. ✅ Avatar visible en haut à droite
3. ✅ Image ronde

**Page Paramètres :**
1. Aller sur Paramètres
2. Onglet "Profil"
3. ✅ Avatar visible (grand)
4. ✅ Image ronde avec bordure

---

### **3. Vérifier dans la Console**

**Ouvrir DevTools (F12) → Network :**

**Avant :**
```
❌ GET /uploads/avatars/avatar-9-1761207572402.jpg → 404
```

**Après :**
```
✅ GET http://localhost:3000/uploads/avatars/avatar-9-1761207572402.jpg → 200
```

---

### **4. Vérifier l'URL Directement**

**Dans le navigateur :**
```
http://localhost:3000/uploads/avatars/avatar-9-1761207572402.jpg
```
✅ L'image s'affiche

---

## 📊 Résumé des Corrections

| Composant | Fichier | Ligne | Correction |
|-----------|---------|-------|------------|
| Layout Header | `NewLayout.tsx` | 343 | `getImageUrl(currentUser.profile_image)` |
| Page Paramètres | `ParametresPage.tsx` | 200 | `getImageUrl(avatarUrl)` |

---

## 🌐 Configuration

### **Variables d'Environnement**

**Fichier :** `.env`

```env
REACT_APP_API_URL=http://localhost:3000
```

**Développement :**
```
http://localhost:3000
```

**Production :**
```
https://api.mct-maintenance.com
```

La fonction `getImageUrl()` s'adapte automatiquement !

---

## ✅ Résultat

**Avant :**
- ❌ Initiales affichées
- ❌ URL relative non fonctionnelle
- ❌ 404 dans la console

**Après :**
- ✅ Image de profil visible
- ✅ URL complète construite automatiquement
- ✅ 200 dans la console
- ✅ Cohérence avec le mobile

**L'image de profil est maintenant visible partout sur le dashboard web !** 🌐✨

---

## 💡 Bonus : Autres Endroits

Si l'image de profil est affichée ailleurs, utiliser la même logique :

```typescript
import { getImageUrl } from '../services/uploadService';

// Avant
<img src={user.profile_image} />

// Après
<img src={user.profile_image ? getImageUrl(user.profile_image) : defaultAvatar} />
```

**Fichiers potentiels :**
- `UsersList.tsx` (ligne 157) ✅ Déjà utilise `UserAvatar` qui gère ça
- `UserDetail.tsx` - À vérifier si nécessaire
- Autres composants affichant des avatars

---

## 🔗 Fonction getImageUrl

**Avantages :**
- ✅ Gère les URLs relatives et absolues
- ✅ Retourne une chaîne vide si pas d'image
- ✅ Vérifie si l'URL commence déjà par `http`
- ✅ Ajoute `API_BASE_URL` si nécessaire
- ✅ Réutilisable partout

**Code :**
```typescript
export const getImageUrl = (path: string): string => {
  if (!path) return '';
  if (path.startsWith('http')) return path;
  return `${API_BASE_URL}${path}`;
};
```

**Parfait pour :**
- Avatars
- Images de produits
- Images d'équipements
- Toute image uploadée sur le serveur
