# 📝 Système de Rapport d'Intervention

## 🎯 Vue d'Ensemble

Système complet de création de rapport d'intervention par le technicien après avoir terminé une intervention.

---

## 📱 Interface Mobile (Flutter)

### **Écran : CreateReportScreen**

**Fichier :** `/lib/screens/technician/create_report_screen.dart`

**Accès :** 
- Après avoir terminé une intervention (statut `completed`)
- Bouton "Créer le rapport" dans l'écran de détail

---

## 🎨 Sections de l'Écran

### **1. Carte d'Informations**

Affiche les informations de l'intervention :
- Titre de l'intervention
- Nom du client
- Adresse

**Design :** Carte grise avec bordure arrondie

---

### **2. Travail Effectué** *(Obligatoire)*

**Type :** TextFormField multi-ligne (5 lignes)

**Validation :**
- Obligatoire
- Ne peut pas être vide

**Placeholder :** "Décrivez en détail le travail effectué..."

**Exemple :**
```
- Remplacement du tuyau d'évacuation principale
- Installation d'un nouveau robinet mélangeur
- Vérification et nettoyage du siphon
- Test d'étanchéité réussi
```

---

### **3. Durée**

**Type :** TextFormField numérique

**Unité :** Minutes

**Optionnel**

**Placeholder :** "Ex: 120"

**Affichage :** Suffixe "min"

---

### **4. Matériaux Utilisés**

**Gestion :** Liste dynamique avec bouton "Ajouter"

**Dialog d'ajout avec 3 champs :**
- **Nom du matériau** (Ex: Tuyau PVC)
- **Quantité** (nombre)
- **Unité** (Ex: mètre, pièce, litre)

**Affichage :**
- Carte par matériau
- Icône 📦 inventory_2
- Bouton supprimer (icône poubelle rouge)

**Exemple :**
```
[📦] Tuyau PVC 50mm        [🗑️]
     2 mètres

[📦] Coude PVC 90°         [🗑️]
     3 pièces

[📦] Robinet mélangeur     [🗑️]
     1 unité
```

**Si vide :** Message "Aucun matériau ajouté"

---

### **5. Photos**

**Gestion :** Grid 3 colonnes avec 2 boutons

**Boutons :**
- 📷 **"Photo"** (bleu) → Prendre une photo avec la caméra
- 🖼️ **"Galerie"** (vert MCT) → Sélectionner depuis la galerie

**Affichage :**
- Grid 3x3 avec images
- Bouton ✖️ en haut à droite pour supprimer
- Overlay rouge sur le bouton de suppression

**Si vide :** Message "Aucune photo ajoutée"

**Format supporté :** JPG, PNG (via `image_picker`)

---

### **6. Observations / Recommandations**

**Type :** TextFormField multi-ligne (4 lignes)

**Optionnel**

**Placeholder :** "Observations, recommandations pour le client..."

**Exemple :**
```
Recommandation : Vérifier l'étanchéité tous les 3 mois.
Observation : Traces de calcaire, prévoir un détartrage annuel.
```

---

### **7. Bouton de Soumission**

**Texte :** "Soumettre le rapport"

**Icône :** 📤 send

**Couleur :** Vert MCT (#0a543d)

**Taille :** Pleine largeur, hauteur 50px

**État désactivé :** Si `_isLoading = true`

---

## 🔌 API Backend

### **Route**

```
POST /api/interventions/:id/report
```

**Authentification :** JWT Token (technicien)

**Autorisation :** Role `technician` uniquement

---

### **Body de la Requête**

```json
{
  "intervention_id": 123,
  "work_description": "Description détaillée...",
  "materials_used": [
    {
      "name": "Tuyau PVC 50mm",
      "quantity": "2",
      "unit": "mètres"
    },
    {
      "name": "Robinet mélangeur",
      "quantity": "1",
      "unit": "unité"
    }
  ],
  "duration": 120,
  "observations": "Recommandation de vérification mensuelle",
  "photos": [
    "base64_photo_1...",
    "base64_photo_2..."
  ]
}
```

---

### **Validation Backend**

```javascript
✅ Intervention existe
✅ Intervention assignée au technicien connecté
✅ Statut = 'completed' (terminée)
✅ work_description obligatoire et non vide
✅ materials_used est un array (peut être vide)
✅ duration est un nombre (0 par défaut)
✅ observations optionnel
✅ photos est un array (peut être vide)
```

---

### **Réponse Succès (200)**

```json
{
  "success": true,
  "message": "Rapport soumis avec succès",
  "data": {
    "intervention_id": 123,
    "report": {
      "intervention_id": 123,
      "technician_id": 8,
      "work_description": "...",
      "materials_used": [...],
      "duration": 120,
      "observations": "...",
      "photos_count": 3,
      "status": "submitted",
      "submitted_at": "2025-10-28T10:30:00.000Z"
    }
  }
}
```

---

### **Erreurs Possibles**

**404 - Intervention non trouvée**
```json
{
  "success": false,
  "message": "Intervention non trouvée ou non assignée à ce technicien"
}
```

**400 - Statut invalide**
```json
{
  "success": false,
  "message": "L'intervention doit être terminée pour soumettre un rapport"
}
```

**400 - Données manquantes**
```json
{
  "success": false,
  "message": "La description du travail effectué est obligatoire"
}
```

---

## 🗄️ Base de Données

### **Migration SQL**

**Fichier :** `/migrations/add_intervention_report_fields.sql`

```sql
ALTER TABLE interventions 
ADD COLUMN report_data JSON NULL,
ADD COLUMN report_submitted_at DATETIME NULL;

CREATE INDEX idx_interventions_report_submitted 
ON interventions(report_submitted_at);
```

---

### **Structure JSON du Rapport**

Stocké dans `interventions.report_data` :

```json
{
  "intervention_id": 123,
  "technician_id": 8,
  "work_description": "Remplacement tuyau...",
  "materials_used": [
    {
      "name": "Tuyau PVC",
      "quantity": "2",
      "unit": "mètres"
    }
  ],
  "duration": 120,
  "observations": "Vérifier mensuellement",
  "photos_count": 3,
  "status": "submitted",
  "submitted_at": "2025-10-28T10:30:00.000Z"
}
```

---

## 🔄 Workflow Complet

```
1. Technicien termine l'intervention
   ↓ (Statut → completed)
   
2. Bouton "Créer le rapport" apparaît
   ↓ (Navigation)
   
3. Écran CreateReportScreen
   ↓ (Remplir formulaire)
   
4. Ajouter travail effectué (obligatoire)
   ↓
   
5. Ajouter durée (optionnel)
   ↓
   
6. Ajouter matériaux (optionnel)
   - Dialog pour chaque matériau
   - Affichage en liste
   ↓
   
7. Ajouter photos (optionnel)
   - Caméra OU galerie
   - Grid 3x3
   - Supprimer si besoin
   ↓
   
8. Ajouter observations (optionnel)
   ↓
   
9. Cliquer "Soumettre le rapport"
   ↓ (Validation)
   
10. API POST /api/interventions/:id/report
    ↓ (Traitement backend)
    
11. Mise à jour dans la DB
    - report_data (JSON)
    - report_submitted_at (timestamp)
    ↓
    
12. Réponse succès
    ↓
    
13. SnackBar "Rapport soumis avec succès"
    ↓
    
14. Navigation automatique
    - Pop CreateReportScreen
    - Pop InterventionDetailScreen
    - Retour à la liste des interventions
```

---

## 📸 Photos - Gestion Technique

### **Upload**

```dart
// Sélection depuis la galerie (multi)
final List<XFile> images = await _picker.pickMultiImage();

// Prise de photo
final XFile? photo = await _picker.pickImage(
  source: ImageSource.camera
);

// Conversion en base64 (pour l'instant)
for (var photo in _photos) {
  final bytes = await File(photo.path).readAsBytes();
  final base64String = bytes.toString();
  photoBase64.add(base64String);
}
```

### **Affichage**

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemBuilder: (context, index) {
    return Stack(
      children: [
        // Image
        Image.file(File(_photos[index].path)),
        
        // Bouton supprimer
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  },
)
```

---

## 🚀 Améliorations Futures

### **Phase 1 : Stockage Photos**

- ❌ Actuellement : Base64 dans le JSON (lourd)
- ✅ À faire : Upload vers serveur/cloud
  - Service de stockage (AWS S3, Firebase Storage, etc.)
  - Retourner URL des photos
  - Stocker uniquement les URLs dans le rapport

### **Phase 2 : Table Dédiée**

Créer une table `intervention_reports` :

```sql
CREATE TABLE intervention_reports (
  id INT PRIMARY KEY AUTO_INCREMENT,
  intervention_id INT NOT NULL,
  technician_id INT NOT NULL,
  work_description TEXT NOT NULL,
  duration INT DEFAULT 0,
  observations TEXT,
  status ENUM('draft', 'submitted', 'approved') DEFAULT 'submitted',
  submitted_at DATETIME,
  approved_at DATETIME,
  approved_by INT,
  created_at DATETIME,
  updated_at DATETIME,
  FOREIGN KEY (intervention_id) REFERENCES interventions(id),
  FOREIGN KEY (technician_id) REFERENCES users(id)
);

CREATE TABLE report_materials (
  id INT PRIMARY KEY AUTO_INCREMENT,
  report_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  quantity VARCHAR(50) NOT NULL,
  unit VARCHAR(50) NOT NULL,
  FOREIGN KEY (report_id) REFERENCES intervention_reports(id)
);

CREATE TABLE report_photos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  report_id INT NOT NULL,
  url VARCHAR(500) NOT NULL,
  type ENUM('before', 'during', 'after') DEFAULT 'during',
  uploaded_at DATETIME,
  FOREIGN KEY (report_id) REFERENCES intervention_reports(id)
);
```

### **Phase 3 : Signature Client**

- Ajout d'un canvas pour signature digitale
- Package : `signature: ^5.4.0`
- Capture de la signature en image
- Upload avec les photos

### **Phase 4 : Génération PDF**

- Générer un PDF professionnel côté serveur
- Inclure toutes les infos du rapport
- Photos en miniature
- Signature client
- Logo MCT
- Envoi automatique par email au client

### **Phase 5 : Validation Admin**

- Workflow d'approbation
- Statuts : draft → submitted → approved
- Notifications à l'admin
- Interface d'approbation dans le dashboard web

---

## ✅ Checklist de Déploiement

- [x] Écran CreateReportScreen créé
- [x] Méthode API submitInterventionReport ajoutée
- [x] Navigation depuis InterventionDetailScreen
- [x] Controller submitReport implémenté
- [x] Route POST /api/interventions/:id/report configurée
- [x] Migration SQL créée (report_data, report_submitted_at)
- [ ] Migration SQL exécutée en DB
- [ ] Tests sur appareil physique
- [ ] Validation de tous les champs
- [ ] Gestion d'erreurs complète
- [ ] Upload de photos testé
- [ ] Notifications client/admin (TODO)

---

## 🧪 Tests

### **Test Mobile**

1. Se connecter en tant que technicien
2. Aller dans "Mes Interventions"
3. Cliquer sur une intervention avec statut `completed`
4. Cliquer sur "Créer le rapport"
5. Remplir le formulaire :
   - ✅ Travail effectué (obligatoire)
   - ✅ Durée : 90 min
   - ✅ Ajouter 2-3 matériaux
   - ✅ Prendre 2-3 photos
   - ✅ Observations
6. Cliquer "Soumettre le rapport"
7. Vérifier :
   - ✅ Loader affiché
   - ✅ SnackBar succès
   - ✅ Retour automatique à la liste
   - ✅ Intervention mise à jour

### **Test Backend**

```bash
# Avec curl
curl -X POST http://localhost:3000/api/interventions/1/report \
  -H "Authorization: Bearer <token_technicien>" \
  -H "Content-Type: application/json" \
  -d '{
    "work_description": "Test rapport",
    "materials_used": [
      {"name": "Test", "quantity": "1", "unit": "pièce"}
    ],
    "duration": 60,
    "observations": "Test obs",
    "photos": []
  }'
```

### **Vérification DB**

```sql
-- Voir le rapport soumis
SELECT 
  id,
  status,
  report_data,
  report_submitted_at,
  completed_at
FROM interventions 
WHERE id = 1;

-- Extraire les données JSON
SELECT 
  id,
  JSON_EXTRACT(report_data, '$.work_description') as travail,
  JSON_EXTRACT(report_data, '$.duration') as duree,
  JSON_EXTRACT(report_data, '$.photos_count') as nb_photos,
  report_submitted_at
FROM interventions 
WHERE report_data IS NOT NULL;
```

---

## 📊 Statistiques

Métriques à tracker :

- ⏱️ Temps moyen de soumission du rapport (completed_at → report_submitted_at)
- 📸 Nombre moyen de photos par rapport
- 🔧 Nombre moyen de matériaux utilisés
- ⭐ Taux de soumission de rapport (completed avec rapport / completed total)

---

**Statut : ✅ Implémentation Complète**

**Dernière mise à jour :** 28 octobre 2025
