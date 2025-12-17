# 🔧 Fix : Statuts des Commandes

## ❌ Problème

Sur l'application mobile, **tous les statuts des commandes affichent "En attente"** même si certaines commandes sont terminées ou annulées.

---

## 🔍 Cause

### **Mauvais Champ Utilisé**

**Fichier :** `/lib/screens/customer/history_screen.dart`

Le code cherchait les mauvais champs pour le statut :

```dart
// ❌ AVANT (Incorrect)
status: _mapOrderStatus(
  orderJson['statut_paiement'] ?? 
  orderJson['statut'] ?? 
  'pending'
),
```

**Problème :**
- L'API retourne `status` (en camelCase)
- Le code cherchait `statut_paiement` ou `statut` (en snake_case français)
- Résultat : Toujours `null` → Défaut à `'pending'`

---

## ✅ Solution

### **1. Correction du Champ Status**

```dart
// ✅ APRÈS (Correct)
status: _mapOrderStatus(orderJson['status'] ?? 'pending'),
```

**Changements :**
- ✅ Utilise `orderJson['status']` au lieu de `statut_paiement`
- ✅ Correspond au format de l'API

---

### **2. Mise à Jour du Mapping des Statuts**

**Avant :**
```dart
String _mapOrderStatus(String apiStatus) {
  switch (apiStatus.toLowerCase()) {
    case 'paye':
    case 'paid':
    case 'livre':
    case 'delivered':
      return 'delivered';  // ❌ Mauvais statut
    case 'en_cours':
    case 'processing':
      return 'pending';
    case 'annule':
    case 'cancelled':
      return 'cancelled';
    default:
      return 'pending';
  }
}
```

**Après :**
```dart
String _mapOrderStatus(String apiStatus) {
  switch (apiStatus.toLowerCase()) {
    case 'completed':      // ← Nouveau
    case 'delivered':
    case 'paid':
    case 'paye':
    case 'livre':
      return 'completed';  // ← Changé de 'delivered' à 'completed'
    case 'processing':
    case 'en_cours':
      return 'pending';
    case 'cancelled':
    case 'canceled':       // ← Ajouté
    case 'annule':
      return 'cancelled';
    case 'pending':        // ← Ajouté
    default:
      return 'pending';
  }
}
```

**Changements :**
- ✅ Ajout de `'completed'` (valeur principale de l'API)
- ✅ Retourne `'completed'` au lieu de `'delivered'`
- ✅ Ajout de `'canceled'` (variante anglaise)
- ✅ Ajout de `'pending'` explicite

---

### **3. Correction du Champ Description**

```dart
// ❌ AVANT
description: orderJson['notes'] ?? 
             orderJson['adresse_livraison'] ?? 
             'Commande #${orderJson['id']}',

// ✅ APRÈS
description: orderJson['notes'] ?? 
             orderJson['shippingAddress'] ?? 
             'Commande #${orderJson['id']}',
```

**Changement :**
- ✅ `adresse_livraison` → `shippingAddress` (format API)

---

## 📊 Statuts de l'API

### **Valeurs Retournées par l'API**

| Statut API | Signification | Affichage Mobile |
|------------|---------------|------------------|
| `pending` | En attente | 🟠 En attente |
| `processing` | En traitement | 🟠 En attente |
| `completed` | Terminée | 🟢 Terminé |
| `cancelled` | Annulée | 🔴 Annulé |

### **Exemple de Données API**

```json
{
  "id": 5,
  "status": "completed",
  "notes": null,
  "shippingAddress": "Cocody, Abidjan",
  "totalAmount": 350000
}
```

---

## 🎨 Affichage des Statuts

### **Badge de Statut**

Le badge affiche maintenant le bon statut avec la bonne couleur :

```
┌─────────────────────────────────┐
│  Commande #5                    │
│  📅 22/10/2025                  │
│  💰 350000 FCFA                 │
│  [Terminé] ← 🟢 Vert            │
├─────────────────────────────────┤
│  Commande #6                    │
│  📅 22/10/2025                  │
│  💰 750000 FCFA                 │
│  [En attente] ← 🟠 Orange       │
└─────────────────────────────────┘
```

### **Couleurs des Statuts**

**Fonction `_buildStatusBadge` :**

```dart
Widget _buildStatusBadge(String status) {
  Color color;
  String label;
  IconData icon;
  
  switch (status) {
    case 'completed':
      color = Colors.green;
      label = 'Terminé';
      icon = Icons.check_circle;
      break;
    case 'pending':
      color = Colors.orange;
      label = 'En attente';
      icon = Icons.pending;
      break;
    case 'cancelled':
      color = Colors.red;
      label = 'Annulé';
      icon = Icons.cancel;
      break;
    default:
      color = Colors.grey;
      label = 'Inconnu';
      icon = Icons.help;
  }
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
```

---

## 🧪 Test

### **Vérifier les Statuts**

1. **Relancer l'application mobile**
   ```bash
   cd mct_maintenance_mobile
   flutter run
   ```

2. **Naviguer vers les commandes**
   - Ouvrir "Commandes" ou "Historique"
   - Onglet "Commandes"

3. **Vérifier les statuts**
   - ✅ Commande #5 : **Terminé** (vert)
   - ✅ Commande #6 : **En attente** (orange)
   - ✅ Les couleurs correspondent aux statuts

---

## 📝 Fichier Modifié

**Fichier :** `/lib/screens/customer/history_screen.dart`

**Changements :**
1. ✅ Ligne 206 : `orderJson['status']` au lieu de `statut_paiement`
2. ✅ Ligne 208 : `orderJson['shippingAddress']` au lieu de `adresse_livraison`
3. ✅ Lignes 218-236 : Fonction `_mapOrderStatus` mise à jour
   - Ajout de `'completed'`
   - Retourne `'completed'` au lieu de `'delivered'`
   - Ajout de `'canceled'` et `'pending'`

---

## 📊 Comparaison

### **Avant**

| Commande | Statut API | Statut Affiché | Couleur |
|----------|------------|----------------|---------|
| #5 | `completed` | ❌ En attente | 🟠 Orange |
| #6 | `pending` | ✅ En attente | 🟠 Orange |

**Problème :** Toutes les commandes affichent "En attente"

---

### **Après**

| Commande | Statut API | Statut Affiché | Couleur |
|----------|------------|----------------|---------|
| #5 | `completed` | ✅ Terminé | 🟢 Vert |
| #6 | `pending` | ✅ En attente | 🟠 Orange |

**Solution :** Chaque commande affiche son vrai statut

---

## ✅ Résultat

**Avant :**
- ❌ Tous les statuts affichent "En attente"
- ❌ Impossible de distinguer les commandes terminées
- ❌ Mauvais champ utilisé (`statut_paiement`)

**Après :**
- ✅ Statuts corrects affichés
- ✅ Commandes terminées en vert
- ✅ Commandes en attente en orange
- ✅ Commandes annulées en rouge
- ✅ Bon champ utilisé (`status`)

**Le problème est résolu !** 🎉 Les statuts des commandes s'affichent maintenant correctement avec les bonnes couleurs.
