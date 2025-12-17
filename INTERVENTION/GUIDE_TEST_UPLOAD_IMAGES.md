# 🧪 Guide de Test - Upload Images

**Date** : 16 octobre 2025  
**Objectif** : Tester l'upload d'images dans les 3 formulaires

---

## 🚀 Préparation

### 1. Démarrer les serveurs

#### Backend API
```bash
cd mct-maintenance-api
npm start
# Doit afficher : 🚀 MCT Maintenance API server running on port 3000
```

#### Frontend Dashboard
```bash
cd mct-maintenance-dashboard
npm start
# Doit ouvrir : http://localhost:3001
```

### 2. Se connecter
- Ouvrir : `http://localhost:3001`
- Login avec un compte admin

---

## ✅ TEST 1 : Upload Image Produit

### Étapes
1. **Aller dans** : Menu → **Produits**
2. **Cliquer** : Bouton **"Nouveau produit"**
3. **Remplir** le formulaire :
   - Nom : `Test Climatiseur`
   - Référence : `TEST-001`
   - Description : `Produit de test`
   - Prix : `500000 FCFA`
   - Coût : `400000 FCFA`
   - Stock : `10`
   - Marque : `Daikin`
   - Catégorie : `Climatisation`
4. **Créer** le produit
5. **Modifier** le produit créé
6. **Faire défiler** vers le bas jusqu'à "Image du produit"
7. **Tester l'upload** :
   - Option A : **Drag & drop** une image sur la zone
   - Option B : **Cliquer** sur "Télécharger une image" et choisir

### Résultat Attendu
```
✅ Preview de l'image apparaît immédiatement
✅ Message : "Image uploadée avec succès"
✅ Image visible dans le formulaire
✅ Boutons "Supprimer" et "Changer" disponibles
```

### Test Suppression
1. **Cliquer** : Bouton **"Supprimer"**
2. **Confirmer** la suppression

### Résultat Attendu
```
✅ Image disparaît
✅ Message : "Image supprimée"
✅ Zone d'upload redevient vide
```

---

## ✅ TEST 2 : Upload Image Équipement

### Étapes
1. **Aller dans** : Menu → **Équipements**
2. **Cliquer** : **"Ajouter un équipement"**
3. **Remplir** le formulaire :
   - Nom : `Climatiseur Bureau`
   - Type : `climatiseur`
   - Marque : `CARRIER`
   - Modèle : `XYZ-123`
   - Client : Sélectionner un client
   - Emplacement : `Bureau principal`
   - Statut : `active`
4. **Créer** l'équipement
5. **Modifier** l'équipement créé
6. **Faire défiler** vers le bas jusqu'à "Image de l'équipement"
7. **Note** : Message affiché "💡 Créez d'abord l'équipement, puis vous pourrez ajouter une photo"
8. **Après création**, cliquer "Modifier" à nouveau
9. **Uploader** une photo :
   - Drag & drop OU cliquer

### Résultat Attendu
```
✅ Upload fonctionne après création équipement
✅ Preview s'affiche
✅ Message succès
✅ Photo visible dans liste équipements
```

---

## ✅ TEST 3 : Upload Avatar Utilisateur

### Étapes
1. **Aller dans** : Menu → **Utilisateurs**
2. **Cliquer** : **"Ajouter un utilisateur"**
3. **Remplir** le formulaire :
   - Prénom : `Jean`
   - Nom : `Dupont`
   - Email : `jean.dupont@test.com`
   - Téléphone : `+237 600 00 00 00`
   - Rôle : `Client`
   - Statut : `Actif`
   - Mot de passe : `Test1234!`
   - Confirmer : `Test1234!`
4. **Faire défiler** vers le bas jusqu'à "Photo de profil"
5. **Uploader** un avatar :
   - Drag & drop OU cliquer

### Résultat Attendu
```
✅ Preview CIRCULAIRE de l'avatar
✅ Message succès
✅ Avatar visible dans formulaire
✅ Boutons supprimer/changer disponibles
```

### Vérification
1. **Enregistrer** l'utilisateur
2. **Éditer** à nouveau
3. **Vérifier** que l'avatar est bien chargé

---

## 🧪 Tests Avancés

### Test Validation Taille
1. **Essayer** d'uploader un fichier > 5MB

#### Résultat Attendu
```
❌ Erreur : "La taille du fichier ne doit pas dépasser 5MB"
```

### Test Validation Type
1. **Essayer** d'uploader un fichier PDF ou TXT

#### Résultat Attendu
```
❌ Erreur : "Seuls les fichiers images sont autorisés"
```

### Test Drag & Drop
1. **Glisser** une image depuis le bureau
2. **Déposer** sur la zone d'upload

#### Résultat Attendu
```
✅ Zone change de couleur au survol
✅ Upload démarre automatiquement
✅ Preview s'affiche
```

---

## 🔍 Vérifications Backend

### Vérifier Fichiers Stockés
```bash
cd mct-maintenance-api
ls -la uploads/avatars/
ls -la uploads/products/
ls -la uploads/equipments/
```

#### Résultat Attendu
```
✅ Fichiers images présents
✅ Noms uniques (timestamp)
✅ Permissions correctes
```

### Vérifier API
```bash
# Test upload avatar
curl -X POST http://localhost:3000/api/upload/avatar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "avatar=@/path/to/image.jpg"

# Résultat attendu :
# { "message": "Avatar uploaded", "url": "/uploads/avatars/xxx.jpg" }
```

---

## 🐛 Problèmes Possibles

### Erreur : "Product ID required"
**Cause** : Tentative d'upload avant création du produit  
**Solution** : Créer d'abord le produit, puis modifier pour ajouter l'image

### Erreur : "Unauthorized"
**Cause** : Token JWT expiré ou manquant  
**Solution** : Se reconnecter

### Image ne s'affiche pas
**Cause** : Chemin incorrect ou serveur uploads/ pas accessible  
**Solution** : Vérifier que le dossier uploads/ existe et permissions

### Erreur 500
**Cause** : Problème backend (dossier uploads/ manquant)  
**Solution** : Créer les dossiers :
```bash
mkdir -p mct-maintenance-api/uploads/{avatars,products,equipments,documents}
```

---

## 📊 Checklist Finale

### ProductForm
- [ ] Upload fonctionne
- [ ] Preview s'affiche
- [ ] Suppression fonctionne
- [ ] Drag & drop fonctionne
- [ ] Validation taille (5MB)
- [ ] Validation type (images)

### EquipmentForm
- [ ] Upload après création équipement
- [ ] Preview s'affiche
- [ ] Suppression fonctionne
- [ ] Message avant création visible

### UserForm
- [ ] Upload fonctionne
- [ ] Preview circulaire
- [ ] Suppression fonctionne
- [ ] Avatar chargé lors édition

---

## ✅ Critères de Succès

```
✅ 3/3 formulaires testés
✅ Upload fonctionne pour tous
✅ Preview fonctionne
✅ Suppression fonctionne
✅ Validation fonctionne
✅ Pas d'erreurs console
✅ Fichiers stockés sur serveur
```

---

## 📝 Rapport de Test

Après les tests, noter :

```
ProductForm     : ✅ ❌ Commentaires : _________________
EquipmentForm   : ✅ ❌ Commentaires : _________________
UserForm        : ✅ ❌ Commentaires : _________________

Problèmes rencontrés :
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

Améliorations suggérées :
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________
```

---

## 🎯 Prochaines Étapes

Après validation des tests :

1. **Si tout fonctionne** ✅
   - Marquer "Upload Images" comme terminé
   - Passer à la prochaine fonctionnalité
   - Déployer en production

2. **Si problèmes** ❌
   - Noter les erreurs
   - Demander corrections
   - Re-tester

---

**Bonne chance pour les tests ! 🚀**

*N'hésite pas à me faire un retour sur ce qui fonctionne ou pas !*
