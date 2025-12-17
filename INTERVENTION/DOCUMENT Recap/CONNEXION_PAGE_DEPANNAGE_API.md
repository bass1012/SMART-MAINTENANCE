# 🔌 Connexion Page Dépannage à l'API

**Date :** 31 Octobre 2025  
**Objectif :** Connecter la page Dépannage du dashboard web à l'API réelle des interventions

---

## 📋 Résumé des Modifications

La page **DepannagePage.tsx** utilisait des données mockées. Elle est maintenant connectée à l'API réelle des interventions via le service **interventionsService**.

---

## 🔄 Changements Effectués

### 1. Remplacement des Imports

**Avant :**
```typescript
import axios from 'axios';
```

**Après :**
```typescript
import { interventionsService } from '../services/interventionsService';
```

---

### 2. Mise à Jour du Modèle de Données

**Interface `Depannage` - Avant :**
```typescript
interface Depannage {
  id: number;
  client_name: string;
  phone: string;
  address: string;
  equipment_type: string;
  fault_description: string;
  urgency: 'low' | 'medium' | 'high' | 'critical';
  status: 'pending' | 'assigned' | 'on_the_way' | 'in_progress' | 'completed' | 'cancelled';
  technician_name?: string;
  scheduled_date?: string;
  created_at: string;
  estimated_cost?: number;
  notes?: string;
}
```

**Interface `Depannage` - Après :**
```typescript
interface Depannage {
  id: number;
  title: string;
  description: string;
  address: string;
  priority: 'low' | 'medium' | 'high' | 'critical';
  status: 'pending' | 'in_progress' | 'completed' | 'cancelled';
  scheduled_date?: string;
  created_at: string;
  customer_id?: number;
  technician_id?: number;
  customer?: {
    id: number;
    first_name: string;
    last_name: string;
    email: string;
    phone?: string;
  };
  technician?: {
    id: number;
    first_name: string;
    last_name: string;
    email: string;
  };
  intervention_type?: string;
}
```

**Changements principaux :**
- ✅ `client_name` + `phone` → objet `customer` complet
- ✅ `fault_description` → `title` + `description`
- ✅ `equipment_type` → `intervention_type`
- ✅ `urgency` → `priority`
- ✅ `technician_name` → objet `technician` complet
- ✅ Suppression de `estimated_cost`, `notes` (non utilisés dans le modèle Intervention)
- ✅ Ajout de `customer_id`, `technician_id`

---

### 3. Connexion aux Données Réelles

#### Fonction `loadDepannages()`

**Avant :**
```typescript
const loadDepannages = async () => {
  try {
    setLoading(true);
    // Données mockées
    const mockData: Depannage[] = [...];
    setDepannages(mockData);
  } catch (error) {
    message.error('Erreur lors du chargement des dépannages');
  } finally {
    setLoading(false);
  }
};
```

**Après :**
```typescript
const loadDepannages = async () => {
  try {
    setLoading(true);
    const response = await interventionsService.getInterventions({});
    const interventions = response.data.interventions || [];
    
    // Mapper les interventions vers le format Depannage
    const mappedData: Depannage[] = interventions.map((intervention: any) => ({
      id: intervention.id,
      title: intervention.title,
      description: intervention.description,
      address: intervention.address || 'Non spécifiée',
      priority: intervention.priority,
      status: intervention.status,
      scheduled_date: intervention.scheduled_date,
      created_at: intervention.created_at,
      customer_id: intervention.customer_id,
      technician_id: intervention.technician_id,
      customer: intervention.customer,
      technician: intervention.technician,
      intervention_type: intervention.intervention_type
    }));
    
    setDepannages(mappedData);
  } catch (error) {
    message.error('Erreur lors du chargement des interventions');
    console.error('Erreur:', error);
  } finally {
    setLoading(false);
  }
};
```

---

#### Fonction `handleDelete()`

**Avant :**
```typescript
const handleDelete = async (id: number) => {
  try {
    // TODO: Appel API réel
    message.success('Dépannage supprimé avec succès');
    loadDepannages();
  } catch (error) {
    message.error('Erreur lors de la suppression');
  }
};
```

**Après :**
```typescript
const handleDelete = async (id: number) => {
  try {
    await interventionsService.deleteIntervention(id);
    message.success('Intervention supprimée avec succès');
    loadDepannages();
  } catch (error) {
    message.error('Erreur lors de la suppression');
    console.error('Erreur:', error);
  }
};
```

---

#### Fonction `handleSubmit()`

**Avant :**
```typescript
const handleSubmit = async (values: any) => {
  try {
    setLoading(true);
    const formData = {
      ...values,
      scheduled_date: values.scheduled_date ? values.scheduled_date.toISOString() : null
    };

    if (editMode && selectedDepannage) {
      // TODO: Appel API réel
      message.success('Dépannage modifié avec succès');
    } else {
      // TODO: Appel API réel
      message.success('Dépannage créé avec succès');
    }

    setOpenModal(false);
    loadDepannages();
    form.resetFields();
  } catch (error) {
    message.error('Erreur lors de l\'enregistrement');
  } finally {
    setLoading(false);
  }
};
```

**Après :**
```typescript
const handleSubmit = async (values: any) => {
  try {
    setLoading(true);
    const formData = {
      title: values.title,
      description: values.description,
      address: values.address,
      priority: values.priority,
      status: values.status || 'pending',
      scheduled_date: values.scheduled_date 
        ? values.scheduled_date.toISOString() 
        : dayjs().add(1, 'day').toISOString(),
      customer_id: values.customer_id,
      technician_id: values.technician_id || null,
      intervention_type: values.intervention_type,
      product_id: 1 // Valeur par défaut requise par l'API
    };

    if (editMode && selectedDepannage) {
      await interventionsService.updateIntervention(selectedDepannage.id, formData);
      message.success('Intervention modifiée avec succès');
    } else {
      await interventionsService.createIntervention(formData);
      message.success('Intervention créée avec succès');
    }

    setOpenModal(false);
    loadDepannages();
    form.resetFields();
  } catch (error: any) {
    message.error(error.response?.data?.message || 'Erreur lors de l\'enregistrement');
    console.error('Erreur:', error);
  } finally {
    setLoading(false);
  }
};
```

---

### 4. Mise à Jour des Colonnes du Tableau

#### Colonne "Client"

**Avant :**
```typescript
{
  title: 'Client',
  key: 'client',
  render: (_, record) => (
    <Space direction="vertical" size={0}>
      <strong>{record.client_name}</strong>
      <span style={{ fontSize: '12px', color: '#666' }}>
        <PhoneOutlined /> {record.phone}
      </span>
    </Space>
  )
}
```

**Après :**
```typescript
{
  title: 'Client',
  key: 'client',
  render: (_, record) => {
    const customerName = record.customer 
      ? `${record.customer.first_name} ${record.customer.last_name}`
      : 'Client inconnu';
    const customerEmail = record.customer?.email || '-';
    return (
      <Space direction="vertical" size={0}>
        <strong>{customerName}</strong>
        <span style={{ fontSize: '12px', color: '#666' }}>
          {customerEmail}
        </span>
      </Space>
    );
  }
}
```

---

#### Colonne "Type" (Equipment → Intervention)

**Avant :**
```typescript
{
  title: 'Équipement',
  dataIndex: 'equipment_type',
  key: 'equipment_type',
  render: (type) => (
    <Tag icon={<ToolOutlined />} color="blue">{type}</Tag>
  ),
  filters: equipmentTypes.map(type => ({ text: type, value: type })),
  onFilter: (value, record) => record.equipment_type === value
}
```

**Après :**
```typescript
{
  title: 'Type',
  dataIndex: 'intervention_type',
  key: 'intervention_type',
  render: (type) => type ? (
    <Tag icon={<ToolOutlined />} color="blue">{type}</Tag>
  ) : <Tag color="default">Non spécifié</Tag>,
  filters: equipmentTypes.map(type => ({ text: type, value: type })),
  onFilter: (value, record) => record.intervention_type === value
}
```

---

#### Colonne "Priorité" (Urgence)

**Avant :**
```typescript
const urgencyMap = {
  low: { label: 'Faible', color: 'green' },
  medium: { label: 'Moyenne', color: 'orange' },
  high: { label: 'Élevée', color: 'red' },
  critical: { label: 'Critique', color: 'magenta' }
};

{
  title: 'Urgence',
  dataIndex: 'urgency',
  key: 'urgency',
  render: (urgency) => (
    <Tag color={urgencyMap[urgency].color}>
      {urgencyMap[urgency].label}
    </Tag>
  )
}
```

**Après :**
```typescript
const priorityMap = {
  low: { label: 'Faible', color: 'green' },
  medium: { label: 'Moyenne', color: 'orange' },
  high: { label: 'Élevée', color: 'red' },
  critical: { label: 'Critique', color: 'magenta' }
};

{
  title: 'Priorité',
  dataIndex: 'priority',
  key: 'priority',
  render: (priority) => (
    <Tag color={priorityMap[priority].color}>
      {priorityMap[priority].label}
    </Tag>
  )
}
```

---

#### Colonne "Technicien"

**Avant :**
```typescript
{
  title: 'Technicien',
  dataIndex: 'technician_name',
  key: 'technician_name',
  render: (name) => name || <Tag color="default">Non assigné</Tag>
}
```

**Après :**
```typescript
{
  title: 'Technicien',
  key: 'technician',
  render: (_, record) => {
    if (record.technician) {
      return `${record.technician.first_name} ${record.technician.last_name}`;
    }
    return <Tag color="default">Non assigné</Tag>;
  }
}
```

---

### 5. Mise à Jour du Formulaire

**Champs supprimés :**
- ❌ `client_name`
- ❌ `phone`
- ❌ `fault_description`
- ❌ `equipment_type`
- ❌ `urgency`
- ❌ `estimated_cost`
- ❌ `notes`

**Champs ajoutés :**
- ✅ `title` (requis)
- ✅ `description` (requis)
- ✅ `intervention_type` (optionnel)
- ✅ `priority` (requis)
- ✅ `customer_id` (requis)
- ✅ `technician_id` (optionnel)

**Exemple de formulaire :**
```tsx
<Form.Item
  label="Titre"
  name="title"
  rules={[{ required: true, message: 'Le titre est requis' }]}
>
  <Input placeholder="Titre de l'intervention" />
</Form.Item>

<Form.Item
  label="Description"
  name="description"
  rules={[{ required: true, message: 'La description est requise' }]}
>
  <TextArea rows={4} placeholder="Décrire le problème..." />
</Form.Item>

<Form.Item
  label="ID Client"
  name="customer_id"
  rules={[{ required: true, message: 'L\'ID du client est requis' }]}
>
  <Input type="number" placeholder="ID du client" />
</Form.Item>

<Form.Item
  label="Priorité"
  name="priority"
  rules={[{ required: true, message: 'La priorité est requise' }]}
>
  <Select placeholder="Niveau de priorité">
    {Object.keys(priorityMap).map(key => (
      <Select.Option key={key} value={key}>
        {priorityMap[key].label}
      </Select.Option>
    ))}
  </Select>
</Form.Item>
```

---

### 6. Mise à Jour des Statistiques

**Avant :**
```typescript
const getStatistics = () => {
  return {
    total: depannages.length,
    pending: depannages.filter(d => d.status === 'pending').length,
    in_progress: depannages.filter(d => d.status === 'in_progress' || d.status === 'on_the_way').length,
    completed: depannages.filter(d => d.status === 'completed').length,
    critical: depannages.filter(d => d.urgency === 'critical').length
  };
};
```

**Après :**
```typescript
const getStatistics = () => {
  return {
    total: depannages.length,
    pending: depannages.filter(d => d.status === 'pending').length,
    in_progress: depannages.filter(d => d.status === 'in_progress').length,
    completed: depannages.filter(d => d.status === 'completed').length,
    critical: depannages.filter(d => d.priority === 'critical').length
  };
};
```

**Changements :**
- ✅ Suppression du filtre `on_the_way` (n'existe plus dans le nouveau modèle)
- ✅ `d.urgency` → `d.priority`

---

### 7. Mise à Jour de la Modal de Détails

**Champs mis à jour :**

```tsx
<Descriptions bordered column={2}>
  <Descriptions.Item label="ID">#{selectedDepannage.id}</Descriptions.Item>
  <Descriptions.Item label="Statut">
    <Tag color={statusMap[selectedDepannage.status].color}>
      {statusMap[selectedDepannage.status].label}
    </Tag>
  </Descriptions.Item>
  
  <Descriptions.Item label="Titre" span={2}>
    <strong>{selectedDepannage.title}</strong>
  </Descriptions.Item>
  
  <Descriptions.Item label="Description" span={2}>
    {selectedDepannage.description}
  </Descriptions.Item>
  
  <Descriptions.Item label="Client">
    {selectedDepannage.customer 
      ? `${selectedDepannage.customer.first_name} ${selectedDepannage.customer.last_name}`
      : 'Client inconnu'
    }
  </Descriptions.Item>
  
  <Descriptions.Item label="Email">
    {selectedDepannage.customer?.email || '-'}
  </Descriptions.Item>
  
  <Descriptions.Item label="Adresse" span={2}>
    {selectedDepannage.address || 'Non spécifiée'}
  </Descriptions.Item>
  
  <Descriptions.Item label="Type d'intervention">
    {selectedDepannage.intervention_type || 'Non spécifié'}
  </Descriptions.Item>
  
  <Descriptions.Item label="Priorité">
    <Tag color={priorityMap[selectedDepannage.priority].color}>
      {priorityMap[selectedDepannage.priority].label}
    </Tag>
  </Descriptions.Item>
  
  <Descriptions.Item label="Technicien" span={2}>
    {selectedDepannage.technician
      ? `${selectedDepannage.technician.first_name} ${selectedDepannage.technician.last_name}`
      : 'Non assigné'
    }
  </Descriptions.Item>
  
  <Descriptions.Item label="Date planifiée">
    {selectedDepannage.scheduled_date 
      ? dayjs(selectedDepannage.scheduled_date).format('DD/MM/YYYY HH:mm') 
      : '-'}
  </Descriptions.Item>
  
  <Descriptions.Item label="Date création">
    {dayjs(selectedDepannage.created_at).format('DD/MM/YYYY HH:mm')}
  </Descriptions.Item>
</Descriptions>
```

---

## 🔌 Routes API Utilisées

### GET /api/interventions
**Description :** Récupérer la liste des interventions  
**Méthode Service :** `interventionsService.getInterventions({})`  
**Réponse :**
```json
{
  "success": true,
  "data": {
    "interventions": [
      {
        "id": 1,
        "title": "Réparation climatisation",
        "description": "Climatisation ne refroidit plus",
        "address": "123 Rue Example",
        "priority": "high",
        "status": "pending",
        "scheduled_date": "2025-11-01T10:00:00.000Z",
        "customer_id": 14,
        "technician_id": null,
        "customer": {
          "id": 14,
          "first_name": "Bakary",
          "last_name": "CISSE",
          "email": "bakary@example.com"
        },
        "technician": null,
        "intervention_type": "Climatisation"
      }
    ],
    "total": 1,
    "page": 1,
    "limit": 50,
    "totalPages": 1
  }
}
```

---

### POST /api/interventions
**Description :** Créer une nouvelle intervention  
**Méthode Service :** `interventionsService.createIntervention(data)`  
**Body :**
```json
{
  "title": "Réparation chaudière",
  "description": "Chaudière ne démarre plus",
  "address": "456 Avenue Test",
  "priority": "critical",
  "status": "pending",
  "scheduled_date": "2025-11-02T14:00:00.000Z",
  "customer_id": 15,
  "technician_id": null,
  "intervention_type": "Chaudière",
  "product_id": 1
}
```

---

### PUT /api/interventions/:id
**Description :** Mettre à jour une intervention  
**Méthode Service :** `interventionsService.updateIntervention(id, data)`  

---

### DELETE /api/interventions/:id
**Description :** Supprimer une intervention  
**Méthode Service :** `interventionsService.deleteIntervention(id)`  

---

## 🧪 Tests de Validation

### Test 1 : Chargement des Interventions

**Étapes :**
1. Ouvrir le dashboard : `http://localhost:3001`
2. Aller sur "Dépannages"
3. Vérifier que la liste se charge

**Résultat attendu :**
- ✅ Interventions affichées depuis l'API
- ✅ Statistiques mises à jour (Total, En attente, En cours, Critiques)
- ✅ Clients affichés avec nom/prénom/email
- ✅ Techniciens affichés si assignés

---

### Test 2 : Création d'Intervention

**Étapes :**
1. Cliquer "Nouveau Dépannage"
2. Remplir le formulaire :
   - Titre : "Test intervention"
   - Description : "Description test"
   - Priorité : "Élevée"
   - ID Client : 14 (ou un ID valide)
   - Date planifiée : Demain 10h00
3. Cliquer "Créer"

**Résultat attendu :**
- ✅ Message de succès
- ✅ Intervention créée dans l'API
- ✅ Liste rechargée avec la nouvelle intervention

---

### Test 3 : Modification d'Intervention

**Étapes :**
1. Cliquer "Modifier" sur une intervention
2. Changer le titre
3. Cliquer "Modifier"

**Résultat attendu :**
- ✅ Message de succès
- ✅ Intervention mise à jour dans l'API
- ✅ Changements visibles dans la liste

---

### Test 4 : Suppression d'Intervention

**Étapes :**
1. Cliquer "Supprimer" sur une intervention
2. Confirmer

**Résultat attendu :**
- ✅ Message de succès
- ✅ Intervention supprimée de l'API
- ✅ Liste mise à jour

---

### Test 5 : Affichage des Détails

**Étapes :**
1. Cliquer "Voir" sur une intervention

**Résultat attendu :**
- ✅ Modal avec tous les détails
- ✅ Client avec nom complet et email
- ✅ Technicien si assigné
- ✅ Dates formatées correctement

---

## ⚠️ Points d'Attention

### 1. Champ `product_id` Obligatoire

L'API requiert un `product_id` lors de la création. Une valeur par défaut `1` est utilisée :

```typescript
const formData = {
  // ... autres champs
  product_id: 1 // Valeur par défaut requise par l'API
};
```

**Solution à long terme :** Ajouter un sélecteur de produit dans le formulaire.

---

### 2. ID Client Manuel

Le formulaire demande l'`customer_id` en saisie manuelle. 

**Solution à long terme :** Ajouter un sélecteur de clients avec recherche.

---

### 3. Statuts Simplifiés

Le nouveau modèle utilise 4 statuts :
- `pending` : En attente
- `in_progress` : En cours
- `completed` : Terminé
- `cancelled` : Annulé

Les anciens statuts `assigned`, `on_the_way`, `arrived` ont été retirés.

---

## 📋 Checklist de Déploiement

### Backend
- [x] API `/api/interventions` fonctionnelle
- [x] Service `interventionsService.ts` configuré
- [ ] Backend démarré : `npm start`

### Frontend
- [x] Imports mis à jour
- [x] Interface `Depannage` corrigée
- [x] Fonctions connectées à l'API
- [x] Colonnes du tableau mises à jour
- [x] Formulaire adapté
- [x] Statistiques corrigées
- [x] Modal de détails mise à jour
- [ ] Dashboard web rechargé

### Tests
- [ ] Test chargement liste
- [ ] Test création intervention
- [ ] Test modification
- [ ] Test suppression
- [ ] Test affichage détails

---

## 🚀 Démarrage

```bash
# Backend
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Frontend (autre terminal)
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-dashboard
npm start

# Ouvrir le dashboard
open http://localhost:3001
```

---

## 🎯 Prochaines Améliorations

### Court Terme
- [ ] Sélecteur de clients avec recherche autocomplete
- [ ] Sélecteur de techniciens avec disponibilité
- [ ] Sélecteur de produits
- [ ] Filtres avancés (date, client, technicien)

### Moyen Terme
- [ ] Assignation en masse de techniciens
- [ ] Export Excel/PDF de la liste
- [ ] Calendrier des interventions
- [ ] Tableau de bord avec graphiques

### Long Terme
- [ ] Notifications temps réel (Socket.IO)
- [ ] Chat en direct client-technicien
- [ ] Suivi GPS du technicien
- [ ] Évaluation client après intervention

---

**Version :** 1.0  
**Date :** 31 Octobre 2025  
**Statut :** ✅ Connexion API complète  
**Fichier modifié :** `/src/pages/DepannagePage.tsx`  
**Service utilisé :** `/src/services/interventionsService.ts`
