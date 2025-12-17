# 👁️ Écran de Visualisation du Rapport d'Intervention

## 🎯 Vue d'Ensemble

Écran en lecture seule pour consulter un rapport d'intervention déjà soumis.

---

## 📱 Écran : ViewReportScreen

**Fichier :** `/lib/screens/technician/view_report_screen.dart`

**Type :** StatelessWidget (lecture seule, pas de modification)

**Accès :** 
- Depuis InterventionDetailScreen
- Bouton "Voir le rapport" (bleu) si `report_submitted_at` n'est pas null

---

## 🎨 Structure de l'Écran

### **1. AppBar**

**Titre :** "Rapport d'Intervention"

**Couleur :** Vert MCT (#0a543d)

**Actions :**
- 🔗 Bouton partage/export (placeholder, à implémenter)

---

### **2. Badge de Statut** (en haut)

Affiche le statut actuel du rapport avec couleur et icône :

**Statuts possibles :**

| Statut | Couleur | Icône | Label |
|--------|---------|-------|-------|
| `submitted` | Bleu | send | Soumis |
| `approved` | Vert | check_circle | Approuvé |
| `draft` | Orange | edit | Brouillon |
| Autre | Gris | info | (statut brut) |

**Design :**
```
┌─────────────────────────┐
│  [📤] Soumis            │  ← Badge avec fond coloré
└─────────────────────────┘
```

---

### **3. Carte d'Informations Intervention**

Affiche les détails de l'intervention concernée :

- 📋 Titre
- 👤 Client
- 📍 Adresse
- 📅 Date prévue

**Design :** Carte blanche avec bordure verte et icône assignment

---

### **4. Date de Soumission**

```
📅 Rapport soumis le: 28/10/2025 à 14:30
```

Format : `dd/MM/yyyy à HH:mm`

Source : `intervention['report_submitted_at']`

---

### **5. Travail Effectué** *(Section principale)*

**Icône :** 🔧 construction

**Titre :** "Travail Effectué"

**Contenu :** Texte multi-ligne dans une boîte grise

**Source :** `report_data.work_description`

**Exemple :**
```
┌────────────────────────────────────┐
│ 🔧 Travail Effectué                │
├────────────────────────────────────┤
│  - Remplacement du tuyau principal │
│  - Installation nouveau robinet    │
│  - Test d'étanchéité réussi        │
└────────────────────────────────────┘
```

---

### **6. Durée** *(Optionnel)*

**Icône :** ⏱️ access_time

**Titre :** "Durée de l'Intervention"

**Affichage :** "120 minutes"

**Source :** `report_data.duration`

**Condition :** Affiché seulement si `duration > 0`

---

### **7. Matériaux Utilisés** *(Optionnel)*

**Icône :** 📦 inventory_2

**Titre :** "Matériaux Utilisés"

**Affichage :** Liste de cartes blanches avec bordure

**Source :** `report_data.materials_used` (Array)

**Condition :** Affiché seulement si la liste n'est pas vide

**Design par matériau :**
```
┌────────────────────────────────────┐
│ [📦]  Tuyau PVC 50mm               │
│       2 mètres                     │
└────────────────────────────────────┘
```

**Exemple complet :**
```
📦 Matériaux Utilisés

┌────────────────────────────────────┐
│ [📦]  Tuyau PVC 50mm               │
│       2 mètres                     │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ [📦]  Coude PVC 90°                │
│       3 pièces                     │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ [📦]  Robinet mélangeur            │
│       1 unité                      │
└────────────────────────────────────┘
```

---

### **8. Photos** *(Optionnel)*

**Icône :** 📷 photo_library

**Titre :** "Photos"

**Affichage :** Badge bleu avec compteur

**Source :** `report_data.photos_count`

**Condition :** Affiché seulement si `photos_count > 0`

**Design :**
```
┌────────────────────────────────────┐
│ 📷 Photos                          │
├────────────────────────────────────┤
│ [🖼️] 3 photos jointes              │
│                                    │
│ Les photos sont stockées sur le    │
│ serveur (texte gris italique)      │
└────────────────────────────────────┘
```

**Note :** Pour l'instant, affichage du compteur uniquement. Dans une version future, on pourrait afficher une galerie d'images.

---

### **9. Observations / Recommandations** *(Optionnel)*

**Icône :** 💬 comment

**Titre :** "Observations / Recommandations"

**Contenu :** Texte multi-ligne dans une boîte grise

**Source :** `report_data.observations`

**Condition :** Affiché seulement si non vide

**Exemple :**
```
┌────────────────────────────────────┐
│ 💬 Observations / Recommandations  │
├────────────────────────────────────┤
│  Vérifier l'étanchéité tous les    │
│  3 mois. Prévoir un détartrage     │
│  annuel.                           │
└────────────────────────────────────┘
```

---

## 🗄️ Source des Données

### **Structure de `report_data` (JSON)**

```json
{
  "intervention_id": 123,
  "technician_id": 8,
  "work_description": "Description détaillée...",
  "materials_used": [
    {
      "name": "Tuyau PVC 50mm",
      "quantity": "2",
      "unit": "mètres"
    }
  ],
  "duration": 120,
  "observations": "Vérifier mensuellement...",
  "photos_count": 3,
  "status": "submitted",
  "submitted_at": "2025-10-28T10:30:00.000Z"
}
```

### **Parsing Flexible**

Le code supporte plusieurs formats :

```dart
// String JSON
if (intervention['report_data'] is String) {
  // TODO: parse JSON string
}

// Objet Map
else if (intervention['report_data'] is Map) {
  return intervention['report_data'] as Map<String, dynamic>;
}
```

---

## 📐 Design

### **Palette de Couleurs**

| Élément | Couleur |
|---------|---------|
| Primary | #0a543d (Vert MCT) |
| Statut Soumis | Bleu (#1976D2) |
| Statut Approuvé | Vert (#388E3C) |
| Statut Brouillon | Orange (#F57C00) |
| Fond sections | Gris clair (#F5F5F5) |
| Bordures | Gris moyen (#E0E0E0) |

### **Icônes Utilisées**

- assignment (carte info)
- construction (travail)
- access_time (durée)
- inventory_2 (matériaux)
- photo_library (photos)
- comment (observations)
- send, check_circle, edit, info (badges statut)

### **Espacements**

- Padding écran : 16px
- Espace entre sections : 24px
- Padding interne cartes : 16px
- Espace entre matériaux : 8px

---

## 🔄 Navigation

### **Flux Complet**

```
Liste des Interventions
  ↓ (Clic sur intervention)
  
Écran de Détail (InterventionDetailScreen)
  ↓ (Clic sur "Voir le rapport")
  
Écran de Visualisation (ViewReportScreen)
  ↓ (Bouton retour)
  
Retour à l'écran de détail
```

### **Condition d'Affichage**

Le bouton "Voir le rapport" apparaît uniquement si :

```dart
intervention['status'] == 'completed' 
  && 
intervention['report_submitted_at'] != null
```

**Sinon :** Bouton "Créer le rapport" (vert) est affiché à la place

---

## 🚀 État Vide

Si aucun rapport n'est disponible (`report_data` vide ou null) :

```
┌────────────────────────────────────┐
│                                    │
│         📋 (icône grise)           │
│                                    │
│    Aucun rapport disponible        │
│                                    │
│  Le rapport n'a pas encore été     │
│  soumis                            │
│                                    │
└────────────────────────────────────┘
```

**Design :** Centré verticalement, icône assignment_outlined grise, texte gris

---

## 📝 Exemple Complet d'Écran

```
┌───────────────────────────────────────┐
│ ← Rapport d'Intervention        🔗    │
├───────────────────────────────────────┤
│                                       │
│ [📤 Soumis]                           │
│                                       │
│ ┌─────────────────────────────────┐  │
│ │ 📋 Intervention                 │  │
│ │ ─────────────────────────────── │  │
│ │ Titre: Fuite principale         │  │
│ │ Client: Bakary CISSE            │  │
│ │ Adresse: Abobo, Abidjan         │  │
│ │ Date: 28/10/2025                │  │
│ └─────────────────────────────────┘  │
│                                       │
│ 📅 Rapport soumis le:                 │
│    28/10/2025 à 14:30                 │
│                                       │
│ 🔧 Travail Effectué                   │
│ ┌─────────────────────────────────┐  │
│ │ - Remplacement tuyau principal  │  │
│ │ - Installation robinet          │  │
│ │ - Test d'étanchéité OK          │  │
│ └─────────────────────────────────┘  │
│                                       │
│ ⏱️ Durée de l'Intervention            │
│ ┌─────────────────────────────────┐  │
│ │ 120 minutes                     │  │
│ └─────────────────────────────────┘  │
│                                       │
│ 📦 Matériaux Utilisés                 │
│ ┌─────────────────────────────────┐  │
│ │ [📦] Tuyau PVC 50mm             │  │
│ │      2 mètres                   │  │
│ └─────────────────────────────────┘  │
│ ┌─────────────────────────────────┐  │
│ │ [📦] Robinet                    │  │
│ │      1 unité                    │  │
│ └─────────────────────────────────┘  │
│                                       │
│ 📷 Photos                             │
│ ┌─────────────────────────────────┐  │
│ │ [🖼️] 3 photos jointes            │  │
│ │ Les photos sont stockées sur le │  │
│ │ serveur                         │  │
│ └─────────────────────────────────┘  │
│                                       │
│ 💬 Observations / Recommandations     │
│ ┌─────────────────────────────────┐  │
│ │ Vérifier l'étanchéité tous les  │  │
│ │ 3 mois                          │  │
│ └─────────────────────────────────┘  │
│                                       │
└───────────────────────────────────────┘
```

---

## 🔮 Améliorations Futures

### **Phase 1 : Galerie de Photos**

- Afficher les photos en miniatures (grid)
- Clic pour agrandir en plein écran
- Swipe entre les photos
- Téléchargement local de chaque photo

### **Phase 2 : Export PDF**

- Bouton "Télécharger PDF" dans l'AppBar
- Génération PDF côté serveur
- Téléchargement et ouverture automatique
- Logo MCT, mise en page professionnelle

### **Phase 3 : Signature Client**

- Afficher la signature du client (si disponible)
- Image de signature sous les observations
- Date et heure de signature

### **Phase 4 : Partage**

- Bouton "Partager" fonctionnel
- Partage par email, WhatsApp, SMS
- Génération d'un lien de consultation web
- Envoi automatique au client

### **Phase 5 : Historique des Modifications**

- Timeline des changements (si éditions autorisées)
- Qui a modifié quoi et quand
- Version précédentes accessibles

### **Phase 6 : Commentaires Admin**

- Section pour commentaires admin
- Workflow d'approbation
- Demandes de modification
- Statut rejeté avec raisons

---

## 🧪 Tests

### **Test Complet**

1. ✅ Se connecter en technicien
2. ✅ Créer un rapport complet (avec tous les champs)
3. ✅ Soumettre le rapport
4. ✅ Revenir à la liste des interventions
5. ✅ Cliquer sur l'intervention
6. ✅ Vérifier que le bouton dit "Voir le rapport" (et non "Créer")
7. ✅ Cliquer sur "Voir le rapport"
8. ✅ Vérifier l'affichage de toutes les sections
9. ✅ Vérifier le badge "Soumis" en haut
10. ✅ Vérifier que les matériaux s'affichent correctement
11. ✅ Vérifier le compteur de photos
12. ✅ Vérifier les observations
13. ✅ Cliquer sur retour → Retour à l'écran de détail

### **Test État Vide**

1. ✅ Supprimer manuellement `report_data` en DB
2. ✅ Recharger l'écran
3. ✅ Vérifier affichage "Aucun rapport disponible"

### **Test Données Manquantes**

1. ✅ Rapport sans matériaux → Section matériaux masquée
2. ✅ Rapport sans photos → Section photos masquée
3. ✅ Rapport sans observations → Section observations masquée
4. ✅ Rapport sans durée → Section durée masquée

---

## 📊 Comparaison Création vs Visualisation

| Aspect | Création (CreateReportScreen) | Visualisation (ViewReportScreen) |
|--------|-------------------------------|----------------------------------|
| Type | StatefulWidget | StatelessWidget |
| Éditable | ✅ Oui | ❌ Non |
| Formulaire | ✅ Avec validation | ❌ Lecture seule |
| Photos | ✅ Upload + preview | 📊 Compteur seulement |
| Matériaux | ✅ Ajout/suppression | 📋 Liste fixe |
| Bouton | "Soumettre" (vert) | Aucun |
| AppBar action | Aucune | Partage (placeholder) |
| Navigation retour | Pop x2 après soumission | Pop x1 |
| Loader | ✅ Pendant soumission | ❌ Pas de loader |
| État vide | "Aucun matériau ajouté" | "Aucun rapport disponible" |

---

## ✅ Checklist de Déploiement

- [x] Écran ViewReportScreen créé
- [x] Import ajouté dans InterventionDetailScreen
- [x] Méthode _viewReport() ajoutée
- [x] Condition d'affichage du bouton implémentée
- [x] Parsing du JSON report_data
- [x] Toutes les sections implémentées
- [x] Design professionnel MCT
- [x] Gestion de l'état vide
- [ ] Tester sur appareil réel
- [ ] Vérifier avec données backend réelles
- [ ] Ajouter galerie photos (TODO)
- [ ] Implémenter export PDF (TODO)

---

**Statut : ✅ Écran de Visualisation Complet**

**Dernière mise à jour :** 28 octobre 2025
