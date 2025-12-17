# 🔧 Ajout du Champ "Nombre d'Équipements" aux Interventions

## ✅ Modifications Effectuées

L'intervention peut maintenant spécifier le nombre d'équipements concernés.

---

## 📋 **Frontend (Dashboard React)**

### **1. Interface TypeScript**
**Fichier:** `/mct-maintenance-dashboard/src/services/interventionsService.ts`

```typescript
export interface Intervention {
  // ... autres champs
  equipment_count?: number;  // Ajouté
  // ...
}
```

### **2. État du Formulaire**
**Fichier:** `/mct-maintenance-dashboard/src/pages/InterventionsPage.tsx`

```typescript
const [newIntervention, setNewIntervention] = useState({
  title: '',
  description: '',
  customer_id: undefined,
  technician_id: undefined,
  scheduled_date: null,
  priority: 'medium',
  status: 'pending',
  equipment_count: 1  // ✅ Ajouté avec valeur par défaut
});
```

### **3. Formulaire de Création/Édition**

**Nouveau champ ajouté après "Priorité" :**

```tsx
<Col span={12}>
  <label style={{ display: 'block', marginBottom: '4px', fontWeight: 'bold' }}>
    Nombre d'équipements *
  </label>
  <Input
    type="number"
    min={1}
    placeholder="Nombre d'équipements"
    value={newIntervention.equipment_count}
    onChange={e => setNewIntervention({ 
      ...newIntervention, 
      equipment_count: parseInt(e.target.value) || 1 
    })}
    size="large"
  />
</Col>
```

**Caractéristiques :**
- Type: `number`
- Minimum: 1
- Valeur par défaut: 1
- Validation: Parse entier avec fallback à 1

### **4. Modal Détails**

**Nouvelle ligne ajoutée :**

```tsx
<Col span={12}>
  <strong>Nombre d'équipements:</strong>
  <div style={{ marginTop: '4px' }}>
    {selectedIntervention.equipment_count || 1}
  </div>
</Col>
```

---

## 🗄️ **Backend (Node.js + Sequelize)**

### **1. Modèle Sequelize**
**Fichier:** `/mct-maintenance-api/src/models/Intervention.js`

```javascript
equipment_count: {
  type: DataTypes.INTEGER,
  allowNull: true,
  defaultValue: 1
}
```

**Propriétés :**
- Type: INTEGER
- Nullable: Oui (pour compatibilité avec données existantes)
- Valeur par défaut: 1

### **2. Migration SQL**
**Fichier:** `/mct-maintenance-api/migrations/add_equipment_count_to_interventions.sql`

```sql
-- Ajouter la colonne
ALTER TABLE interventions ADD COLUMN equipment_count INTEGER DEFAULT 1;

-- Mettre à jour les interventions existantes
UPDATE interventions SET equipment_count = 1 WHERE equipment_count IS NULL;
```

---

## 🔄 **Flux de Données**

### **Création d'Intervention**

```
Frontend                    Backend                     Database
──────────                  ──────────                  ──────────
[Formulaire]
 ↓ equipment_count: 3
[POST /api/interventions]
                      →    [Validation]
                      →    [Création]
                                                   →   INSERT equipment_count = 3
                      ←    { success: true, data: {...} }
 ← [Affichage: 3 équipements]
```

### **Affichage d'Intervention**

```
Frontend                    Backend                     Database
──────────                  ──────────                  ──────────
[Clic sur intervention]
[GET /api/interventions/:id]
                      →    [Récupération]
                                                   ←   SELECT * FROM interventions
                      ←    { data: { equipment_count: 3 } }
[Modal Détails]
 ↓
[Affiche: "Nombre d'équipements: 3"]
```

---

## 🎯 **Cas d'Usage**

### **Exemple 1 : Climatisation Multiple**
```
Titre: Maintenance annuelle climatisation
Client: Société ABC
Nombre d'équipements: 5
Description: 5 climatiseurs à réviser (bureaux étage 2)
```

### **Exemple 2 : Intervention Unique**
```
Titre: Réparation chaudière
Client: M. Dupont
Nombre d'équipements: 1 (valeur par défaut)
Description: Fuite sur chaudière principale
```

### **Exemple 3 : Installation Complète**
```
Titre: Installation système chauffage
Client: Résidence Neuve
Nombre d'équipements: 12
Description: 12 radiateurs + 1 chaudière centrale
```

---

## 🧪 **Tests à Effectuer**

### **Test 1 : Création avec Nombre Spécifique**
1. Ouvrir le formulaire "Nouvelle intervention"
2. Remplir tous les champs obligatoires
3. Définir "Nombre d'équipements" à 5
4. Créer l'intervention
5. ✅ Vérifier que 5 s'affiche dans les détails

### **Test 2 : Valeur par Défaut**
1. Ouvrir le formulaire "Nouvelle intervention"
2. Ne pas toucher au champ "Nombre d'équipements"
3. Vérifier qu'il affiche 1
4. Créer l'intervention
5. ✅ Vérifier que 1 s'affiche dans les détails

### **Test 3 : Modification**
1. Ouvrir une intervention existante
2. Modifier le nombre d'équipements (ex: 1 → 3)
3. Enregistrer
4. ✅ Vérifier la mise à jour

### **Test 4 : Validation Minimum**
1. Essayer de saisir 0 ou une valeur négative
2. ✅ Vérifier que le champ reste à 1 minimum

### **Test 5 : Compatibilité Anciennes Données**
1. Charger une intervention créée avant cette mise à jour
2. ✅ Vérifier qu'elle affiche 1 par défaut

---

## 📊 **Impact sur les Rapports**

### **Statistiques Possibles**

**Nombre total d'équipements traités :**
```sql
SELECT SUM(equipment_count) as total_equipments
FROM interventions
WHERE status = 'completed';
```

**Moyenne d'équipements par intervention :**
```sql
SELECT AVG(equipment_count) as avg_equipments
FROM interventions;
```

**Top clients par équipements :**
```sql
SELECT 
  customer_id,
  SUM(equipment_count) as total_equipments,
  COUNT(*) as interventions
FROM interventions
GROUP BY customer_id
ORDER BY total_equipments DESC
LIMIT 10;
```

---

## 🔌 **Intégration API**

### **Création d'Intervention**

**Requête :**
```http
POST /api/interventions
Content-Type: application/json
Authorization: Bearer {token}

{
  "title": "Maintenance climatisation",
  "description": "Révision annuelle",
  "customer_id": 9,
  "technician_id": 15,
  "scheduled_date": "2025-11-01T09:00:00Z",
  "priority": "medium",
  "equipment_count": 3
}
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "id": 45,
    "title": "Maintenance climatisation",
    "equipment_count": 3,
    ...
  }
}
```

### **Récupération d'Intervention**

**Requête :**
```http
GET /api/interventions/45
Authorization: Bearer {token}
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "id": 45,
    "title": "Maintenance climatisation",
    "equipment_count": 3,
    "customer": { ... },
    "technician": { ... }
  }
}
```

---

## 📱 **Mobile Flutter (Prochaine Étape)**

### **Interface à Ajouter**

**Modèle Dart :**
```dart
class Intervention {
  final int id;
  final String title;
  final int equipmentCount;  // À ajouter
  
  Intervention.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      title = json['title'],
      equipmentCount = json['equipment_count'] ?? 1;
}
```

**Formulaire Flutter :**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Nombre d\'équipements',
    prefixIcon: Icon(Icons.format_list_numbered),
  ),
  keyboardType: TextInputType.number,
  initialValue: '1',
  validator: (value) {
    if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
      return 'Minimum 1 équipement';
    }
    return null;
  },
  onSaved: (value) {
    _equipmentCount = int.parse(value!);
  },
)
```

---

## 🚀 **Déploiement**

### **1. Backend**

```bash
# Appliquer la migration
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
sqlite3 database.sqlite < migrations/add_equipment_count_to_interventions.sql

# Redémarrer le serveur
npm start
```

### **2. Dashboard Web**

Le dashboard devrait se mettre à jour automatiquement avec hot-reload.

```bash
# Si nécessaire
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard
npm start
```

### **3. Vérification**

```bash
# Vérifier que la colonne existe
sqlite3 database.sqlite "PRAGMA table_info(interventions);"

# Vérifier les valeurs
sqlite3 database.sqlite "SELECT id, title, equipment_count FROM interventions LIMIT 5;"
```

---

## 📝 **Résumé des Fichiers Modifiés**

| Fichier | Action | Description |
|---------|--------|-------------|
| `interventionsService.ts` | Modifié | Ajout champ interface |
| `InterventionsPage.tsx` | Modifié | État + formulaire + détails |
| `Intervention.js` | Modifié | Modèle Sequelize |
| `add_equipment_count_to_interventions.sql` | Créé | Migration SQL |
| `AJOUT_NOMBRE_EQUIPEMENTS.md` | Créé | Documentation |

---

## ✅ **Checklist**

- [x] Interface TypeScript mise à jour
- [x] État du formulaire React mis à jour
- [x] Champ ajouté au formulaire (création/édition)
- [x] Affichage dans modal détails
- [x] Modèle Sequelize mis à jour
- [x] Migration SQL créée
- [x] Validation frontend (min: 1)
- [x] Valeur par défaut (1)
- [x] Documentation rédigée
- [ ] Migration appliquée en DB
- [ ] Tests manuels effectués
- [ ] Déploiement en production

---

## 🎯 **Avantages**

✅ **Précision** : Savoir exactement combien d'équipements sont concernés
✅ **Planification** : Mieux estimer le temps d'intervention
✅ **Facturation** : Calculer les coûts en fonction du nombre
✅ **Statistiques** : Analyser le volume d'équipements traités
✅ **Historique** : Tracer l'évolution du parc client
✅ **Compatibilité** : Valeur par défaut pour anciennes données

---

**Date de création :** 30 octobre 2025  
**Statut :** ✅ Implémenté (frontend + backend)  
**Prochaine étape :** Appliquer la migration et tester  

**Développé pour MCT Maintenance** 🔧
