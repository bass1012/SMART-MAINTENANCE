# 💰 Gestion du Diagnostic Gratuit/Payant pour les Interventions

**Date :** 31 Octobre 2025  
**Objectif :** Implémenter une tarification différenciée du diagnostic selon le statut du client

---

## 📋 Règles de Tarification

### 🎯 Principe

**Client avec Contrat d'Entretien :**
- ✅ Diagnostic **GRATUIT** (0 FCFA)
- Le client a souscrit à une offre d'entretien
- Il bénéficie du diagnostic sans frais supplémentaires

**Client sans Contrat :**
- 💵 Diagnostic **PAYANT** : **4 000 FCFA**
- Le client contacte MCT Maintenance directement
- Le diagnostic est facturé avant toute intervention

---

## 🔧 Implémentation Backend

### 1. Mise à Jour du Modèle `Intervention`

**Fichier :** `/src/models/Intervention.js`

**Nouveaux champs ajoutés :**

```javascript
// Gestion du diagnostic
diagnostic_fee: {
  type: DataTypes.DECIMAL(10, 2),
  allowNull: true,
  defaultValue: 0.00,
  comment: 'Coût du diagnostic (0 si gratuit, 4000 si payant)'
},
is_free_diagnosis: {
  type: DataTypes.BOOLEAN,
  allowNull: true,
  defaultValue: false,
  comment: 'true si le client a un contrat (diagnostic gratuit), false sinon (4000 FCFA)'
}
```

---

### 2. Migration de Base de Données

**Fichier :** `/migrations/add_diagnostic_fee_to_interventions.sql`

```sql
-- Ajouter le champ pour le coût du diagnostic
ALTER TABLE interventions ADD COLUMN diagnostic_fee DECIMAL(10, 2) DEFAULT 0.00;

-- Ajouter le champ pour indiquer si le diagnostic est gratuit
ALTER TABLE interventions ADD COLUMN is_free_diagnosis BOOLEAN DEFAULT 0;
```

**Script d'application :** `/apply-diagnostic-fee-migration.js`

```bash
node apply-diagnostic-fee-migration.js
```

**Ce script :**
1. ✅ Ajoute les colonnes `diagnostic_fee` et `is_free_diagnosis`
2. ✅ Met à jour les interventions existantes avec contrat → diagnostic gratuit
3. ✅ Met à jour les interventions sans contrat → diagnostic 4000 FCFA
4. ✅ Affiche un résumé des modifications

---

### 3. Logique dans le Contrôleur

**Fichier :** `/src/controllers/intervention/interventionController.js`

**Fonction `createIntervention` - Calcul automatique :**

```javascript
// 💰 Calcul du coût du diagnostic
// Si le client a un contrat d'entretien actif, le diagnostic est gratuit
// Sinon, le diagnostic coûte 4000 FCFA
let diagnosticFee = 4000.00;
let isFreeDiagnosis = false;

if (interventionData.contract_id) {
  // Client avec contrat d'entretien = diagnostic gratuit
  diagnosticFee = 0.00;
  isFreeDiagnosis = true;
  console.log('✅ Client avec contrat d\'entretien → Diagnostic GRATUIT');
} else {
  // Client sans contrat = diagnostic payant
  console.log('💵 Client sans contrat → Diagnostic payant: 4000 FCFA');
}

// Créer l'intervention avec les frais de diagnostic
const intervention = await Intervention.create({
  ...interventionData,
  diagnostic_fee: diagnosticFee,
  is_free_diagnosis: isFreeDiagnosis
}, { transaction });
```

**Logique :**
1. Vérifier si `contract_id` est présent dans les données
2. Si oui → `is_free_diagnosis = true`, `diagnostic_fee = 0`
3. Si non → `is_free_diagnosis = false`, `diagnostic_fee = 4000`
4. Enregistrer l'intervention avec ces valeurs

---

## 🖥️ Implémentation Frontend

### 1. Interface TypeScript

**Fichier :** `/src/pages/DepannagePage.tsx`

**Interface `Depannage` mise à jour :**

```typescript
interface Depannage {
  id: number;
  title: string;
  description: string;
  // ... autres champs
  contract_id?: number;           // ✅ ID du contrat d'entretien
  diagnostic_fee?: number;         // ✅ Coût du diagnostic
  is_free_diagnosis?: boolean;     // ✅ Diagnostic gratuit ou non
  // ...
}
```

---

### 2. Colonne dans le Tableau

**Nouvelle colonne "Diagnostic" :**

```tsx
{
  title: 'Diagnostic',
  key: 'diagnostic',
  render: (_, record) => {
    if (record.is_free_diagnosis) {
      return <Tag color="green">GRATUIT</Tag>;
    }
    return (
      <Tooltip title="Client sans contrat d'entretien">
        <Tag color="gold">{(record.diagnostic_fee || 4000).toLocaleString()} FCFA</Tag>
      </Tooltip>
    );
  },
  filters: [
    { text: 'Gratuit', value: 'free' },
    { text: 'Payant (4000 FCFA)', value: 'paid' }
  ],
  onFilter: (value, record) => {
    if (value === 'free') return record.is_free_diagnosis === true;
    return record.is_free_diagnosis === false;
  }
}
```

**Affichage :**
- 🟢 Tag vert "GRATUIT" si client avec contrat
- 🟡 Tag doré "4 000 FCFA" si client sans contrat (avec tooltip explicatif)
- Filtres pour trier par type de diagnostic

---

### 3. Formulaire de Création/Modification

**Champ ajouté :**

```tsx
<Form.Item
  label="ID Contrat (optionnel)"
  name="contract_id"
  tooltip="Si le client a un contrat d'entretien, le diagnostic sera GRATUIT. Sinon, il coûtera 4000 FCFA."
>
  <Input type="number" placeholder="ID du contrat d'entretien" />
</Form.Item>
```

**Caractéristiques :**
- Champ optionnel
- Tooltip explicatif sur la tarification
- Si rempli → diagnostic gratuit automatiquement

---

### 4. Modal de Détails

**Affichage enrichi :**

```tsx
<Descriptions.Item label="Contrat d'entretien">
  {selectedDepannage.contract_id ? (
    <Tag color="blue">Contrat #{selectedDepannage.contract_id}</Tag>
  ) : (
    <Tag color="default">Aucun contrat</Tag>
  )}
</Descriptions.Item>

<Descriptions.Item label="Coût diagnostic">
  {selectedDepannage.is_free_diagnosis ? (
    <Tag color="green" style={{ fontSize: '14px', padding: '4px 12px' }}>
      <strong>GRATUIT</strong>
    </Tag>
  ) : (
    <Tag color="gold" style={{ fontSize: '14px', padding: '4px 12px' }}>
      <strong>{(selectedDepannage.diagnostic_fee || 4000).toLocaleString()} FCFA</strong>
    </Tag>
  )}
</Descriptions.Item>
```

**Affichage :**
- Indication claire du statut du contrat
- Coût du diagnostic en gras et coloré

---

## 📊 Workflow Complet

### Cas 1 : Client avec Contrat d'Entretien

```
Dashboard Admin
     │
     ├─► Créer intervention
     │   ├─ Titre: "Réparation climatisation"
     │   ├─ Client ID: 14
     │   ├─ Contrat ID: 3  ← Client a un contrat
     │   └─ Date: 01/11/2025 14:00
     │
     ↓
Backend calcule:
  ✅ contract_id = 3 (présent)
  ✅ is_free_diagnosis = true
  ✅ diagnostic_fee = 0.00
     │
     ↓
Intervention créée:
  📋 Diagnostic: GRATUIT
  💰 Coût: 0 FCFA
     │
     ↓
Dashboard affiche:
  🟢 Tag vert "GRATUIT"
```

---

### Cas 2 : Client sans Contrat

```
Dashboard Admin
     │
     ├─► Créer intervention
     │   ├─ Titre: "Diagnostic panne"
     │   ├─ Client ID: 18
     │   ├─ Contrat ID: (vide)  ← Pas de contrat
     │   └─ Date: 01/11/2025 10:00
     │
     ↓
Backend calcule:
  ❌ contract_id = null (absent)
  ❌ is_free_diagnosis = false
  💵 diagnostic_fee = 4000.00
     │
     ↓
Intervention créée:
  📋 Diagnostic: PAYANT
  💰 Coût: 4000 FCFA
     │
     ↓
Dashboard affiche:
  🟡 Tag doré "4 000 FCFA"
```

---

## 🧪 Tests de Validation

### Test 1 : Création avec Contrat

**Étapes :**
```bash
1. Dashboard → Dépannages → "Nouveau Dépannage"
2. Remplir:
   - Titre: "Test diagnostic gratuit"
   - Description: "Test"
   - Client ID: 9 (Bakary CISSE)
   - Contrat ID: 1
   - Priorité: Normale
   - Date: Demain 10h00
3. Cliquer "Créer"
```

**Résultat attendu :**
```
✅ Message: "Intervention créée avec succès"
✅ Logs backend:
   "✅ Client avec contrat d'entretien → Diagnostic GRATUIT"
✅ Tableau:
   - Colonne Diagnostic: Tag vert "GRATUIT"
✅ Détails:
   - Contrat: Tag bleu "Contrat #1"
   - Coût diagnostic: Tag vert "GRATUIT"
```

---

### Test 2 : Création sans Contrat

**Étapes :**
```bash
1. Dashboard → Dépannages → "Nouveau Dépannage"
2. Remplir:
   - Titre: "Test diagnostic payant"
   - Description: "Test"
   - Client ID: 18
   - Contrat ID: (laisser vide)
   - Priorité: Élevée
   - Date: Demain 14h00
3. Cliquer "Créer"
```

**Résultat attendu :**
```
✅ Message: "Intervention créée avec succès"
✅ Logs backend:
   "💵 Client sans contrat → Diagnostic payant: 4000 FCFA"
✅ Tableau:
   - Colonne Diagnostic: Tag doré "4 000 FCFA"
✅ Détails:
   - Contrat: Tag gris "Aucun contrat"
   - Coût diagnostic: Tag doré "4 000 FCFA"
```

---

### Test 3 : Filtre Tableau

**Étapes :**
```bash
1. Dashboard → Dépannages
2. Cliquer sur filtre colonne "Diagnostic"
3. Sélectionner "Gratuit"
```

**Résultat attendu :**
```
✅ Affichage uniquement des interventions avec diagnostic gratuit
✅ Toutes ont un contract_id
```

**Étapes :**
```bash
4. Sélectionner "Payant (4000 FCFA)"
```

**Résultat attendu :**
```
✅ Affichage uniquement des interventions avec diagnostic payant
✅ Aucune n'a de contract_id
```

---

### Test 4 : Vérification Base de Données

```bash
# Se connecter à la base
sqlite3 database.sqlite

# Vérifier les diagnostics gratuits
SELECT 
  id, 
  title, 
  contract_id, 
  is_free_diagnosis, 
  diagnostic_fee 
FROM interventions 
WHERE is_free_diagnosis = 1;

# Résultat attendu:
# id|title|contract_id|is_free_diagnosis|diagnostic_fee
# 1|Réparation...|3|1|0.00

# Vérifier les diagnostics payants
SELECT 
  id, 
  title, 
  contract_id, 
  is_free_diagnosis, 
  diagnostic_fee 
FROM interventions 
WHERE is_free_diagnosis = 0;

# Résultat attendu:
# id|title|contract_id|is_free_diagnosis|diagnostic_fee
# 2|Diagnostic...|NULL|0|4000.00
```

---

## 📝 Migration des Données Existantes

### Commandes

```bash
# 1. Appliquer la migration
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node apply-diagnostic-fee-migration.js
```

**Sortie attendue :**
```
🔧 Application de la migration: diagnostic_fee pour interventions
📝 Ajout des colonnes diagnostic_fee et is_free_diagnosis...
✅ Colonne diagnostic_fee ajoutée
✅ Colonne is_free_diagnosis ajoutée
🔄 Mise à jour des interventions existantes avec contrat...
✅ Interventions avec contrat mises à jour (diagnostic gratuit)
🔄 Mise à jour des interventions sans contrat...
✅ Interventions sans contrat mises à jour (diagnostic 4000 FCFA)

📊 Résumé:
   Total interventions: 10
   Diagnostics gratuits: 4
   Diagnostics payants: 6

✅ Migration terminée avec succès!
```

---

## 🔍 Requêtes Utiles

### Statistiques Globales

```sql
SELECT 
  COUNT(*) as total,
  SUM(CASE WHEN is_free_diagnosis = 1 THEN 1 ELSE 0 END) as diagnostics_gratuits,
  SUM(CASE WHEN is_free_diagnosis = 0 THEN 1 ELSE 0 END) as diagnostics_payants,
  SUM(diagnostic_fee) as revenus_diagnostics
FROM interventions;
```

---

### Clients avec Contrats

```sql
SELECT 
  i.id,
  i.title,
  i.contract_id,
  c.first_name || ' ' || c.last_name as client,
  i.diagnostic_fee,
  i.is_free_diagnosis
FROM interventions i
LEFT JOIN users u ON i.customer_id = u.id
LEFT JOIN customer_profiles c ON u.id = c.user_id
WHERE i.contract_id IS NOT NULL
ORDER BY i.created_at DESC;
```

---

### Revenus Mensuels des Diagnostics

```sql
SELECT 
  strftime('%Y-%m', created_at) as mois,
  COUNT(*) as total_interventions,
  SUM(CASE WHEN is_free_diagnosis = 0 THEN 1 ELSE 0 END) as diagnostics_payants,
  SUM(diagnostic_fee) as revenus_diagnostics
FROM interventions
GROUP BY strftime('%Y-%m', created_at)
ORDER BY mois DESC;
```

---

## 💡 Améliorations Futures

### Court Terme
- [ ] Sélecteur de contrats au lieu de saisie manuelle d'ID
- [ ] Validation automatique : vérifier que le contract_id appartient au customer_id
- [ ] Notification au client du coût du diagnostic avant création

### Moyen Terme
- [ ] Tarification variable selon le type d'équipement
- [ ] Remise si plusieurs équipements à diagnostiquer
- [ ] Facturation automatique du diagnostic payant
- [ ] Tableau de bord des revenus de diagnostics

### Long Terme
- [ ] Contrats avec X diagnostics gratuits par an
- [ ] Historique des diagnostics par client
- [ ] Génération automatique de facture de diagnostic
- [ ] Paiement en ligne du diagnostic avant intervention

---

## 📋 Checklist de Déploiement

### Backend
- [x] Modèle Intervention mis à jour
- [x] Migration SQL créée
- [x] Script d'application de migration créé
- [x] Logique dans createIntervention implémentée
- [ ] Migration appliquée : `node apply-diagnostic-fee-migration.js`
- [ ] Backend redémarré

### Frontend
- [x] Interface Depannage mise à jour
- [x] Colonne Diagnostic ajoutée au tableau
- [x] Champ contract_id ajouté au formulaire
- [x] Affichage dans modal de détails
- [x] Filtres de diagnostic fonctionnels
- [ ] Dashboard rechargé

### Tests
- [ ] Test création avec contrat
- [ ] Test création sans contrat
- [ ] Test filtres tableau
- [ ] Test affichage détails
- [ ] Vérification base de données

---

## 🎯 Résumé Visuel

```
┌─────────────────────────────────────────────────────────────┐
│                    CRÉATION INTERVENTION                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Contrat présent? │
                    └──────────────────┘
                         │         │
                    OUI  │         │  NON
                         │         │
         ┌───────────────┘         └───────────────┐
         ▼                                         ▼
┌──────────────────────┐                 ┌──────────────────────┐
│  Diagnostic GRATUIT  │                 │  Diagnostic PAYANT   │
│                      │                 │                      │
│  is_free: true       │                 │  is_free: false      │
│  fee: 0.00 FCFA      │                 │  fee: 4000.00 FCFA   │
│                      │                 │                      │
│  🟢 Tag vert         │                 │  🟡 Tag doré         │
└──────────────────────┘                 └──────────────────────┘
```

---

**Version :** 1.0  
**Date :** 31 Octobre 2025  
**Statut :** ✅ Implémenté, migration à appliquer  
**Impact :** Backend + Frontend  
**Prochaine action :** Appliquer la migration et tester
