# 🔧 Correction Bug : Erreur lors de la mise à jour de réclamation

## ❌ Problème

Lors de la modification d'une réclamation depuis le dashboard web, erreur :
```
Erreur lors de la mise à jour de la réclamation
```

## 🔍 Cause

Dans le fichier `complaintController.js`, ligne 289, j'avais utilisé :
```javascript
model: CustomerProfile,  // ❌ Variable non définie
model: User,             // ❌ Variable non définie
```

Mais `CustomerProfile` et `User` n'étaient **pas importés** en haut du fichier.

Le reste du fichier utilise la syntaxe inline :
```javascript
model: require('../models/CustomerProfile'),  // ✅ Correct
```

## ✅ Solution

Correction ligne 289-295 :
```javascript
// AVANT (incorrect)
const updatedComplaint = await Complaint.findByPk(id, {
  include: [{
    model: CustomerProfile,  // ❌ Non défini
    as: 'customer',
    include: [{
      model: User,          // ❌ Non défini
      as: 'user'
    }]
  }]
});

// APRÈS (correct)
const updatedComplaint = await Complaint.findByPk(id, {
  include: [{
    model: require('../models/CustomerProfile'),  // ✅ Import inline
    as: 'customer',
    include: [{
      model: require('../models/User'),          // ✅ Import inline
      as: 'user'
    }]
  }]
});
```

## 🚀 Déploiement

```bash
# 1. Arrêter l'API
pkill -f "node.*app.js"

# 2. Redémarrer l'API
cd mct-maintenance-api
npm start
```

## ✅ Test

1. Ouvrir le dashboard web
2. Modifier une réclamation (résolution, description, etc.)
3. Sauvegarder
4. ✅ Devrait fonctionner maintenant
5. ✅ Client devrait recevoir une notification mobile

---

**Date** : 4 novembre 2025  
**Fichier corrigé** : `mct-maintenance-api/src/controllers/complaintController.js`  
**Ligne** : 289-295
