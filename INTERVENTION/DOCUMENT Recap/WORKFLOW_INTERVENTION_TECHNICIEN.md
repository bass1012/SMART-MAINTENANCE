# 🔧 Workflow Complet d'Intervention Technicien

## 📋 Vue d'Ensemble

Système de gestion complète du cycle de vie d'une intervention, depuis l'assignation jusqu'à la création du rapport final.

---

## 🎯 Workflow en 7 Étapes

```
1. 📩 ASSIGNÉE      → L'admin assigne l'intervention au technicien
2. ✅ ACCEPTÉE      → Le technicien accepte l'intervention
3. 🚗 EN ROUTE      → Le technicien signale qu'il est en route
4. 📍 ARRIVÉ        → Le technicien signale son arrivée sur les lieux
5. ⏱️ EN COURS      → Le technicien démarre l'intervention
6. ✅ TERMINÉE      → Le technicien termine l'intervention
7. 📝 RAPPORT       → Le technicien crée le rapport détaillé
```

---

## 🔄 Statuts et Transitions

### **Statuts Disponibles**

| Statut | Code | Description | Couleur |
|--------|------|-------------|---------|
| Assignée | `assigned` | Intervention assignée à un technicien | Gris |
| Acceptée | `accepted` | Technicien a accepté l'intervention | Vert |
| En route | `on_the_way` | Technicien en déplacement | Bleu |
| Arrivé | `arrived` | Technicien sur place | Orange |
| En cours | `in_progress` | Intervention en cours d'exécution | Vert |
| Terminée | `completed` | Intervention terminée | Vert foncé |
| Annulée | `cancelled` | Intervention annulée | Rouge |

### **Transitions Autorisées**

```
assigned → accepted
accepted → on_the_way
on_the_way → arrived
arrived → in_progress
in_progress → completed
```

**Règles :**
- ❌ Impossible de sauter une étape
- ❌ Impossible de revenir en arrière
- ✅ Chaque étape enregistre un timestamp

---

## 🎨 Interface Utilisateur (Mobile Flutter)

### **1. Écran de Liste d'Interventions**

**Fichier :** `/lib/screens/technician/interventions_screen.dart`

**Fonctionnalités :**
- Affichage de toutes les interventions assignées
- Filtrage par onglets (Toutes, En attente, En cours, Terminées)
- Badge de statut coloré
- Badge de priorité
- Clic sur une intervention → Écran de détail

**Onglets :**
```dart
Tab 0: Toutes
Tab 1: En attente (pending)
Tab 2: En cours (in_progress)
Tab 3: Terminées (completed)
```

---

### **2. Écran de Détail d'Intervention**

**Fichier :** `/lib/screens/technician/intervention_detail_screen.dart`

**Sections :**

#### **A. Carte d'Informations**
- Titre de l'intervention
- Client
- Adresse
- Date et heure
- Type de service
- Description détaillée

#### **B. Stepper Visuel**

Un indicateur visuel montrant la progression à travers les étapes :

```
[✓] Assignée       (vert, complété)
[✓] Acceptée       (vert, complété)
[●] En route       (orange, actuel)
[ ] Arrivé         (gris, à venir)
[ ] En cours       (gris, à venir)
[ ] Terminée       (gris, à venir)
```

**Légende :**
- ✅ Étape complétée (cercle vert avec check)
- 🟠 Étape actuelle (cercle orange avec icône)
- ⚪ Étape à venir (cercle gris avec icône)

#### **C. Bouton d'Action Contextuel**

Le bouton change selon le statut actuel :

| Statut | Bouton | Couleur | Action |
|--------|--------|---------|--------|
| `assigned` | ✅ Accepter l'intervention | Vert | POST /api/interventions/:id/accept |
| `accepted` | 🚗 Je suis en route | Bleu | POST /api/interventions/:id/on-the-way |
| `on_the_way` | 📍 Je suis arrivé | Orange | POST /api/interventions/:id/arrived |
| `arrived` | ▶️ Démarrer l'intervention | Vert | POST /api/interventions/:id/start |
| `in_progress` | ✅ Terminer l'intervention | Vert | POST /api/interventions/:id/complete |
| `completed` | 📝 Créer le rapport | Vert foncé | Navigation vers rapport |

---

## 🔌 Backend API (Node.js + Express)

### **Routes Implémentées**

**Fichier :** `/src/routes/interventionRoutes.js`

```javascript
// Workflow complet
POST /api/interventions/:id/accept        // Accepter
POST /api/interventions/:id/on-the-way    // En route
POST /api/interventions/:id/arrived       // Arrivé
POST /api/interventions/:id/start         // Démarrer
POST /api/interventions/:id/complete      // Terminer
POST /api/interventions/:id/report        // Soumettre rapport
```

**Authentification :** Toutes les routes nécessitent un token JWT
**Autorisation :** Role `technician` uniquement

---

### **Contrôleur**

**Fichier :** `/src/controllers/intervention/interventionController.js`

#### **1. acceptIntervention**

```javascript
const acceptIntervention = async (req, res, next) => {
  // Vérifier que l'intervention est assignée au technicien
  // Vérifier le statut (doit être 'assigned' ou 'pending')
  // Mettre à jour le statut à 'accepted'
  // Enregistrer accepted_at = now()
  // Retourner l'intervention mise à jour
};
```

**Validation :**
- ✅ Intervention assignée au technicien connecté
- ✅ Statut actuel = `assigned` ou `pending`
- ❌ Erreur 404 si intervention non trouvée
- ❌ Erreur 400 si statut incompatible

#### **2. markOnTheWay**

```javascript
const markOnTheWay = async (req, res, next) => {
  // Vérifier que l'intervention est acceptée
  // Mettre à jour le statut à 'on_the_way'
  // Enregistrer departed_at = now()
};
```

**Validation :**
- ✅ Statut actuel = `accepted`
- ❌ Erreur 400 si intervention pas encore acceptée

#### **3. markArrived**

```javascript
const markArrived = async (req, res, next) => {
  // Vérifier que le technicien est en route
  // Mettre à jour le statut à 'arrived'
  // Enregistrer arrived_at = now()
};
```

**Validation :**
- ✅ Statut actuel = `on_the_way`
- ❌ Erreur 400 si technicien pas encore en route

#### **4. startIntervention**

```javascript
const startIntervention = async (req, res, next) => {
  // Vérifier que le technicien est arrivé
  // Mettre à jour le statut à 'in_progress'
  // Enregistrer started_at = now()
};
```

**Validation :**
- ✅ Statut actuel = `arrived`
- ❌ Erreur 400 si technicien pas encore arrivé

#### **5. completeIntervention**

```javascript
const completeIntervention = async (req, res, next) => {
  // Vérifier que l'intervention est en cours
  // Mettre à jour le statut à 'completed'
  // Enregistrer completed_at = now()
  // TODO: Notifier le client
};
```

**Validation :**
- ✅ Statut actuel = `in_progress`
- ❌ Erreur 400 si intervention pas encore démarrée

---

### **Champs de Timestamp**

La table `interventions` doit avoir ces champs :

```sql
accepted_at    DATETIME    -- Date d'acceptation
departed_at    DATETIME    -- Date de départ (en route)
arrived_at     DATETIME    -- Date d'arrivée
started_at     DATETIME    -- Date de début
completed_at   DATETIME    -- Date de fin
```

**Migration SQL :**

```sql
ALTER TABLE interventions 
ADD COLUMN accepted_at DATETIME NULL AFTER status,
ADD COLUMN departed_at DATETIME NULL AFTER accepted_at,
ADD COLUMN arrived_at DATETIME NULL AFTER departed_at,
ADD COLUMN started_at DATETIME NULL AFTER arrived_at,
ADD COLUMN completed_at DATETIME NULL AFTER started_at;
```

---

## 📱 Service API Mobile (Flutter)

**Fichier :** `/lib/services/api_service.dart`

### **Méthodes Ajoutées**

```dart
// Accepter une intervention
Future<Map<String, dynamic>> acceptIntervention(int interventionId)

// Signaler "En route"
Future<Map<String, dynamic>> markInterventionOnTheWay(int interventionId)

// Signaler "Arrivé sur les lieux"
Future<Map<String, dynamic>> markInterventionArrived(int interventionId)

// Démarrer l'intervention
Future<Map<String, dynamic>> startIntervention(int interventionId)

// Terminer une intervention
Future<Map<String, dynamic>> completeIntervention(int interventionId)
```

**Exemple d'utilisation :**

```dart
try {
  final response = await _apiService.acceptIntervention(interventionId);
  
  setState(() {
    _intervention['status'] = response['data']['status'];
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(response['message']),
      backgroundColor: Colors.green,
    ),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## 🧪 Tests

### **Test du Workflow Complet**

**1. Assignation (Admin Dashboard)**

```bash
# Se connecter en tant qu'admin
POST http://localhost:3001/login

# Assigner une intervention
PATCH /api/interventions/1/assign
Body: { "technician_id": 8 }
```

**2. Acceptation (App Mobile)**

```bash
# Le technicien reçoit une notification push
# Ouvre l'app → Voit l'intervention
# Clique sur l'intervention → Écran de détail
# Clique sur "Accepter l'intervention"

POST /api/interventions/1/accept
Status: 200 OK
Response: { "success": true, "data": { "status": "accepted" } }
```

**3. En Route**

```bash
# Bouton "Je suis en route" apparaît
POST /api/interventions/1/on-the-way
Status: 200 OK
```

**4. Arrivé**

```bash
# Bouton "Je suis arrivé" apparaît
POST /api/interventions/1/arrived
Status: 200 OK
```

**5. Démarrage**

```bash
# Bouton "Démarrer l'intervention" apparaît
POST /api/interventions/1/start
Status: 200 OK
```

**6. Fin**

```bash
# Bouton "Terminer l'intervention" apparaît
POST /api/interventions/1/complete
Status: 200 OK

# → Retour automatique à la liste
# → Bouton "Créer le rapport" visible
```

---

## 📝 Création de Rapport

**TODO - À implémenter**

Après avoir terminé l'intervention, le technicien doit créer un rapport contenant :

**Informations Requises :**
- ✅ Travail effectué (description détaillée)
- ✅ Matériaux utilisés (liste avec quantités)
- ✅ Temps passé (durée)
- ✅ Photos (avant/après)
- ✅ Signature du client (optionnel)
- ✅ Observations / Recommandations

**Écran à Créer :**
- `/lib/screens/technician/create_report_screen.dart`

**Route Backend :**
```javascript
POST /api/interventions/:id/report
Body: {
  work_description: string,
  materials_used: [{ name, quantity, unit }],
  duration: number, // en minutes
  photos: [base64],
  client_signature: base64,
  observations: string
}
```

---

## 🔔 Notifications

### **Notifications Push Existantes**

1. **Assignation → Technicien**
   - Titre: "Nouvelle intervention assignée"
   - Message: "Une intervention vous a été assignée"
   - Action: Ouvre l'écran de détail

### **Notifications à Ajouter**

2. **Acceptation → Client**
   - "Votre intervention a été acceptée par le technicien"

3. **En route → Client**
   - "Le technicien est en route"

4. **Arrivé → Client**
   - "Le technicien est arrivé sur place"

5. **Démarrage → Client**
   - "L'intervention a démarré"

6. **Fin → Client**
   - "Votre intervention est terminée"
   - Action: Voir le rapport / Laisser un avis

---

## 📊 Analytics & Métriques

### **Données à Tracker**

```dart
// Temps moyen par étape
accepted_at - created_at         // Temps d'acceptation
departed_at - accepted_at        // Temps de préparation
arrived_at - departed_at         // Temps de trajet
started_at - arrived_at          // Temps d'installation
completed_at - started_at        // Durée de l'intervention
```

### **KPIs**

- ⏱️ Temps de réponse moyen (assignation → acceptation)
- 🚗 Temps de trajet moyen
- ⏰ Durée moyenne d'intervention
- ✅ Taux de complétion
- ⭐ Satisfaction client par technicien

---

## 🚀 Prochaines Étapes

### **Phase 1 : Complétée ✅**
- [x] Backend : Routes workflow complet
- [x] Backend : Contrôleurs avec validation
- [x] Mobile : Méthodes API service
- [x] Mobile : Écran de détail avec stepper
- [x] Mobile : Navigation et rechargement

### **Phase 2 : En Cours**
- [ ] Migration SQL : Ajouter les champs timestamp
- [ ] Backend : Route de création de rapport
- [ ] Mobile : Écran de création de rapport
- [ ] Mobile : Upload de photos
- [ ] Backend : Notifications aux clients

### **Phase 3 : À Venir**
- [ ] Signature numérique client
- [ ] Géolocalisation en temps réel
- [ ] Chat technicien-client
- [ ] Historique des interventions
- [ ] Tableau de bord analytics

---

## 📚 Ressources

**Fichiers Backend :**
- `/src/routes/interventionRoutes.js` - Routes API
- `/src/controllers/intervention/interventionController.js` - Logique métier

**Fichiers Mobile :**
- `/lib/services/api_service.dart` - Service API
- `/lib/screens/technician/interventions_screen.dart` - Liste
- `/lib/screens/technician/intervention_detail_screen.dart` - Détail

**Documentation :**
- `/WORKFLOW_INTERVENTION_TECHNICIEN.md` - Ce document
- `/NOTIFICATIONS_TECHNICIEN.md` - Système de notifications
- `/TEST_NOTIFICATIONS_TECHNICIEN.md` - Guide de test

---

## ✅ Checklist de Validation

Avant de déployer en production :

- [ ] Migration SQL appliquée (champs timestamp)
- [ ] Tests backend : Toutes les routes testées
- [ ] Tests mobile : Workflow complet testé
- [ ] Notifications FCM testées
- [ ] Gestion d'erreurs complète
- [ ] Logs de débogage en place
- [ ] Documentation API à jour
- [ ] Tests sur appareil physique Android/iOS

---

**Statut : ✅ Workflow Base Implémenté - Rapport en Attente**

**Dernière mise à jour :** 28 octobre 2025
