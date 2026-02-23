# 🤖 SPÉCIFICATION TECHNIQUE
## Planification Automatique Interventions (Suggestions uniquement)

**Version :** 1.1  
**Date :** 13 Janvier 2026  
**Auteur :** Équipe Technique MCT  
**Statut :** 🟢 Actif (Mode suggestions uniquement)

> **Note :** La fonctionnalité d'auto-assignation automatique a été désactivée.  
> Le système fournit uniquement des **suggestions** de techniciens avec scores,  
> l'assignation finale reste **manuelle** via l'interface admin.

---

## 🎯 OBJECTIFS

### Business
- Aider à la décision d'assignation (suggestions intelligentes)
- Optimiser distance technicien → client : -40%
- Augmenter taux satisfaction client : +20%
- Réduire temps de recherche manuel : -70%

### Technique
- API suggestions < 500ms
- Scoring précis > 85%
- Évolutif vers ML (Q2 2026)
- Intégration mobile + dashboard
- **Assignation manuelle uniquement**

---

## 📐 ALGORITHME SCORING

### Formule Globale
```javascript
Score_Total = (
  w1 * Score_Distance +
  w2 * Score_Compétences +
  w3 * Score_Disponibilité +
  w4 * Score_Charge +
  w5 * Score_Performance
) / 100

// Poids par défaut
w1 = 30  // Distance (impact coûts)
w2 = 25  // Compétences (qualité service)
w3 = 20  // Disponibilité (rapidité)
w4 = 15  // Charge travail (équité)
w5 = 10  // Performance historique (qualité)
```

---

### 1. Score Distance (0-100)
**Objectif :** Minimiser distance technicien → client

**Calcul :**
```javascript
function calculateDistanceScore(technicianLat, technicianLng, clientLat, clientLng) {
  // Formule Haversine (distance géodésique)
  const R = 6371; // Rayon Terre en km
  const dLat = toRad(clientLat - technicianLat);
  const dLng = toRad(clientLng - technicianLng);
  
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(toRad(technicianLat)) * Math.cos(toRad(clientLat)) *
            Math.sin(dLng/2) * Math.sin(dLng/2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance_km = R * c;
  
  // Scoring inverse : plus proche = meilleur score
  if (distance_km <= 5) return 100;
  if (distance_km <= 10) return 80;
  if (distance_km <= 20) return 60;
  if (distance_km <= 50) return 40;
  return 20; // > 50km
}
```

**Pondération :** 30%

---

### 2. Score Compétences (0-100)
**Objectif :** Matcher compétences technicien avec type intervention

**Calcul :**
```javascript
function calculateSkillsScore(technicianSkills, interventionType) {
  // Mapping types interventions → compétences requises
  const requiredSkills = {
    'plumbing': ['plomberie', 'sanitaire'],
    'electrical': ['électricité', 'domotique'],
    'hvac': ['climatisation', 'chauffage'],
    'maintenance': ['maintenance générale'],
    'installation': ['installation', 'mise en service']
  };
  
  const required = requiredSkills[interventionType] || [];
  const techSkills = technicianSkills.map(s => s.toLowerCase());
  
  // Calcul intersection
  const matches = required.filter(skill => 
    techSkills.some(ts => ts.includes(skill))
  ).length;
  
  if (matches === 0) return 0;
  if (matches >= required.length) return 100;
  return Math.round((matches / required.length) * 100);
}
```

**Sources données :**
- Table `users.skills` (JSON array)
- `interventions.type` (enum)

**Pondération :** 25%

---

### 3. Score Disponibilité (0-100)
**Objectif :** Prioriser techniciens disponibles rapidement

**Calcul :**
```javascript
function calculateAvailabilityScore(technicianId, interventionDate, interventionTime) {
  // Vérifier calendrier technicien
  const existingInterventions = await Intervention.findAll({
    where: {
      technician_id: technicianId,
      scheduled_date: interventionDate,
      status: ['assigned', 'accepted', 'on_the_way', 'in_progress']
    }
  });
  
  // Aucune intervention ce jour = disponible
  if (existingInterventions.length === 0) return 100;
  
  // Vérifier conflits horaires
  const hasConflict = existingInterventions.some(int => {
    const startTime = parseTime(int.scheduled_time);
    const endTime = addHours(startTime, int.estimated_duration || 2);
    const requestedTime = parseTime(interventionTime);
    
    return isTimeOverlap(startTime, endTime, requestedTime);
  });
  
  if (hasConflict) return 0;
  
  // Disponible mais déjà occupé (capacité limitée)
  const occupancyRate = existingInterventions.length / MAX_DAILY_INTERVENTIONS;
  return Math.round(100 * (1 - occupancyRate));
}

const MAX_DAILY_INTERVENTIONS = 6; // Par défaut
```

**Pondération :** 20%

---

### 4. Score Charge Travail (0-100)
**Objectif :** Équilibrer charge entre techniciens

**Calcul :**
```javascript
function calculateWorkloadScore(technicianId) {
  const now = new Date();
  const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  
  // Compter interventions 7 derniers jours
  const recentInterventions = await Intervention.count({
    where: {
      technician_id: technicianId,
      created_at: { [Op.gte]: last7Days },
      status: { [Op.ne]: 'cancelled' }
    }
  });
  
  // Scoring inverse : moins chargé = meilleur score
  if (recentInterventions === 0) return 100;
  if (recentInterventions <= 5) return 80;
  if (recentInterventions <= 10) return 60;
  if (recentInterventions <= 15) return 40;
  return 20; // > 15 interventions/semaine
}
```

**Pondération :** 15%

---

### 5. Score Performance (0-100)
**Objectif :** Prioriser techniciens performants

**Calcul :**
```javascript
function calculatePerformanceScore(technicianId) {
  // Moyenne notes évaluations client
  const avgRating = await Intervention.findOne({
    attributes: [
      [sequelize.fn('AVG', sequelize.col('client_rating')), 'avg_rating'],
      [sequelize.fn('COUNT', sequelize.col('id')), 'count']
    ],
    where: {
      technician_id: technicianId,
      client_rating: { [Op.ne]: null }
    }
  });
  
  if (!avgRating || avgRating.count < 5) return 50; // Données insuffisantes
  
  // Conversion note 0-5 vers score 0-100
  const rating = parseFloat(avgRating.avg_rating);
  return Math.round((rating / 5) * 100);
}
```

**Sources données :**
- `interventions.client_rating` (0-5)
- Minimum 5 évaluations pour fiabilité

**Pondération :** 10%

---

## 🏗️ ARCHITECTURE

### Backend Structure

```
mct-maintenance-api/
├── services/
│   └── schedulingService.js  (NOUVEAU)
│       ├── suggestTechnicians()
│       ├── autoAssignIntervention()
│       ├── calculateScore()
│       ├── calculateDistanceScore()
│       ├── calculateSkillsScore()
│       ├── calculateAvailabilityScore()
│       ├── calculateWorkloadScore()
│       └── calculatePerformanceScore()
│
├── controllers/
│   └── interventionController.js  (MODIFIÉ)
│       ├── suggestTechnicians()  (NOUVEAU)
│       └── autoAssignIntervention()  (NOUVEAU)
│
├── routes/
│   └── interventions.js  (MODIFIÉ)
│       ├── POST /api/interventions/:id/suggest-technicians
│       └── POST /api/interventions/:id/auto-assign (⚠️ DÉSACTIVÉ)
│
└── tests/
    └── services/
        └── schedulingService.test.js  (NOUVEAU)
```

---

### API Endpoints

#### 1. Suggestions Techniciens
```
POST /api/interventions/:id/suggest-technicians
```

**Request :**
```json
{
  "intervention_id": 142,
  "max_results": 5,
  "weights": {  // Optionnel, override poids par défaut
    "distance": 30,
    "skills": 25,
    "availability": 20,
    "workload": 15,
    "performance": 10
  }
}
```

**Response (200) :**
```json
{
  "success": true,
  "data": {
    "intervention_id": 142,
    "suggestions": [
      {
        "technician_id": 15,
        "name": "Ouattara Hamid",
        "avatar": "https://...",
        "total_score": 87,
        "details": {
          "distance_score": 95,
          "distance_km": 3.2,
          "skills_score": 100,
          "matched_skills": ["plomberie", "sanitaire"],
          "availability_score": 80,
          "next_available": "2026-01-06T09:00:00Z",
          "workload_score": 75,
          "recent_interventions": 8,
          "performance_score": 90,
          "avg_rating": 4.5,
          "total_ratings": 23
        }
      },
      // ... 4 autres techniciens
    ],
    "computed_at": "2026-01-05T14:30:00Z",
    "computation_time_ms": 247
  }
}
```

**Errors :**
- `400` : Intervention not found
- `400` : Intervention already assigned
- `500` : Computation error

---

#### 2. Auto-Assignation ⚠️ DÉSACTIVÉE

> **Note :** Cette fonctionnalité est temporairement désactivée.  
> L'endpoint existe toujours dans le backend mais n'est plus accessible depuis les interfaces utilisateur.

```
POST /api/interventions/:id/auto-assign
```

**Request :**
```json
{
  "intervention_id": 142,
  "force_top_score": true  // Optionnel, assigner automatiquement meilleur score
}
```

**Response (200) :**
```json
{
  "success": true,
  "data": {
    "intervention_id": 142,
    "assigned_technician": {
      "id": 15,
      "name": "Ouattara Hamid",
      "email": "ouat.hamed@gmail.com",
      "phone": "+2250099778866"
    },
    "score": 87,
    "assigned_at": "2026-01-05T14:35:00Z",
    "notification_sent": true
  },
  "message": "Intervention assignée automatiquement à Ouattara Hamid"
}
```

**Errors :**
- `400` : No available technician found
- `400` : Intervention already assigned
- `500` : Assignment error

---

## 📱 INTÉGRATION MOBILE

### UI Dashboard Technicien

**Ajout onglet "Suggestions"**

```dart
// lib/screens/technician/dashboard_screen.dart

Widget _buildSuggestionsCard() {
  return Card(
    child: ListTile(
      leading: Icon(Icons.auto_awesome, color: Colors.orange),
      title: Text('Interventions suggérées pour vous'),
      subtitle: Text('3 nouvelles suggestions'),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () => Navigator.pushNamed(context, '/suggestions'),
    ),
  );
}
```

---

### Screen Liste Suggestions

```dart
// lib/screens/technician/suggestions_screen.dart (NOUVEAU)

class SuggestionsScreen extends StatefulWidget {
  @override
  _SuggestionsScreenState createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    // API GET /api/technician/suggestions
    // Retourne interventions non assignées avec score technicien
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Card(
      child: ExpansionTile(
        title: Text(suggestion['intervention']['title']),
        subtitle: Row(
          children: [
            Icon(Icons.location_on, size: 16),
            SizedBox(width: 4),
            Text('${suggestion['distance_km']} km'),
            SizedBox(width: 16),
            Icon(Icons.star, size: 16, color: Colors.amber),
            SizedBox(width: 4),
            Text('Score: ${suggestion['score']}/100'),
          ],
        ),
        children: [
          ListTile(
            title: Text('Détails scoring'),
            subtitle: Column(
              children: [
                _buildScoreBar('Distance', suggestion['distance_score']),
                _buildScoreBar('Compétences', suggestion['skills_score']),
                _buildScoreBar('Disponibilité', suggestion['availability_score']),
              ],
            ),
          ),
          ButtonBar(
            children: [
              TextButton(
                child: Text('Accepter'),
                onPressed: () => _acceptIntervention(suggestion['intervention_id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 75 ? Colors.green : 
                score >= 50 ? Colors.orange : Colors.red
              ),
            ),
          ),
          SizedBox(width: 8),
          Text('$score'),
        ],
      ),
    );
  }
}
```

---

## 🖥️ INTÉGRATION DASHBOARD

### Bouton Dashboard Admin

**Page Détail Intervention**

```jsx
// mct-maintenance-dashboard/src/pages/Interventions/InterventionDetail.jsx

const InterventionDetail = () => {
  const [suggestions, setSuggestions] = useState([]);
  const [showSuggestions, setShowSuggestions] = useState(false);

  const handleSuggestTechnicians = async () => {
    try {
      const response = await api.post(
        `/api/interventions/${interventionId}/suggest-technicians`,
        { max_results: 5 }
      );
      setSuggestions(response.data.suggestions);
      setShowSuggestions(true);
    } catch (error) {
      message.error('Erreur chargement suggestions');
    }
  };

  // ⚠️ Feature auto-assignation désactivée
  // const handleAutoAssign = async (technicianId) => {
  //   try {
  //     await api.post(`/api/interventions/${interventionId}/auto-assign`, {
  //       force_top_score: true
  //     });
  //     message.success('Intervention assignée automatiquement');
  //     navigate('/interventions');
  //   } catch (error) {
  //     message.error('Erreur assignation automatique');
  //   }
  // };

  return (
    <Card>
      {!intervention.technician_id && (
        <Button
          type="primary"
          icon={<RobotOutlined />}
          onClick={handleSuggestTechnicians}
        >
          Suggérer Techniciens
        </Button>
      )}

      <Modal
        title="Suggestions Techniciens"
        visible={showSuggestions}
        onCancel={() => setShowSuggestions(false)}
        footer={null}
        width={800}
      >
        <List
          dataSource={suggestions}
          renderItem={(suggestion) => (
            <List.Item
              actions={[
                <Button
                  type="primary"
                  onClick={() => handleAutoAssign(suggestion.technician_id)}
                >
                  Assigner
                </Button>
              ]}
            >
              <List.Item.Meta
                avatar={<Avatar src={suggestion.avatar} />}
                title={
                  <Space>
                    {suggestion.name}
                    <Tag color="green">Score: {suggestion.total_score}/100</Tag>
                  </Space>
                }
                description={
                  <Space direction="vertical" style={{width: '100%'}}>
                    <Progress
                      percent={suggestion.details.distance_score}
                      format={() => `${suggestion.details.distance_km} km`}
                    />
                    <Progress
                      percent={suggestion.details.skills_score}
                      format={() => `Compétences`}
                    />
                    <Progress
                      percent={suggestion.details.availability_score}
                      format={() => `Disponibilité`}
                    />
                  </Space>
                }
              />
            </List.Item>
          )}
        />
      </Modal>
    </Card>
  );
};
```

---

## 🧪 TESTS

### Tests Unitaires Backend

```javascript
// tests/services/schedulingService.test.js

describe('SchedulingService', () => {
  describe('calculateDistanceScore', () => {
    it('should return 100 for distance <= 5km', () => {
      const score = schedulingService.calculateDistanceScore(
        5.64, -3.97,  // Abidjan centre
        5.65, -3.98   // 1.5 km
      );
      expect(score).toBe(100);
    });

    it('should return 80 for distance 5-10km', () => {
      const score = schedulingService.calculateDistanceScore(
        5.64, -3.97,
        5.72, -4.03  // ~8 km
      );
      expect(score).toBe(80);
    });
  });

  describe('calculateSkillsScore', () => {
    it('should return 100 for perfect match', () => {
      const skills = ['plomberie', 'sanitaire', 'chauffage'];
      const score = schedulingService.calculateSkillsScore(skills, 'plumbing');
      expect(score).toBe(100);
    });

    it('should return 0 for no match', () => {
      const skills = ['électricité'];
      const score = schedulingService.calculateSkillsScore(skills, 'plumbing');
      expect(score).toBe(0);
    });
  });

  describe('suggestTechnicians', () => {
    it('should return top 5 technicians sorted by score', async () => {
      const suggestions = await schedulingService.suggestTechnicians(142);
      
      expect(suggestions).toHaveLength(5);
      expect(suggestions[0].total_score).toBeGreaterThanOrEqual(suggestions[1].total_score);
      expect(suggestions[0]).toHaveProperty('technician_id');
      expect(suggestions[0]).toHaveProperty('details');
    });
  });
});
```

---

### Tests E2E Mobile

```dart
// test_driver/suggestions_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Technician can view and accept suggestions', (tester) async {
    // Launch app
    await tester.pumpWidget(MyApp());
    
    // Login as technician
    await tester.enterText(find.byKey(Key('email')), 'tech@test.com');
    await tester.enterText(find.byKey(Key('password')), 'test123');
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();
    
    // Navigate to suggestions
    await tester.tap(find.text('Suggestions'));
    await tester.pumpAndSettle();
    
    // Verify suggestions displayed
    expect(find.text('Interventions suggérées'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    
    // Tap first suggestion
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();
    
    // Verify details displayed
    expect(find.text('Score:'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    
    // Accept intervention
    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();
    
    // Verify success message
    expect(find.text('Intervention acceptée'), findsOneWidget);
  });
}
```

---

## 📊 MONITORING & MÉTRIQUES

### Métriques à Tracker

```javascript
// Prometheus metrics (Backend)

const suggestionsCounter = new Counter({
  name: 'scheduling_suggestions_total',
  help: 'Total suggestions computed',
  labelNames: ['intervention_type']
});

const suggestionsDuration = new Histogram({
  name: 'scheduling_suggestions_duration_seconds',
  help: 'Duration of suggestions computation',
  buckets: [0.1, 0.5, 1.0, 2.0, 5.0]
});

// ⚠️ Métriques auto-assignation désactivées
// const autoAssignSuccess = new Counter({
//   name: 'scheduling_auto_assign_success_total',
//   help: 'Successful auto-assignments'
// });
// 
// const autoAssignFailure = new Counter({
//   name: 'scheduling_auto_assign_failure_total',
//   help: 'Failed auto-assignments',
//   labelNames: ['reason']
// });
```

---

## 🚀 DÉPLOIEMENT

### Checklist Production

- [ ] Tests unitaires 100% coverage
- [ ] Tests E2E mobile passed
- [ ] Tests E2E dashboard passed
- [ ] Performance API < 500ms (p95)
- [ ] Documentation API Swagger
- [ ] Guide utilisateur mobile
- [ ] Guide utilisateur dashboard
- [ ] Monitoring Prometheus configuré
- [ ] Alertes Slack configurées
- [ ] Feature flag activé (rollout progressif)

### Rollout Strategy

**Phase 1 (Semaine 1) :** 10% utilisateurs  
**Phase 2 (Semaine 2) :** 50% utilisateurs  
**Phase 3 (Semaine 3) :** 100% utilisateurs  

---

## 🔮 ÉVOLUTIONS FUTURES (Q2 2026)

### Machine Learning
- Modèle ML prédictif (TensorFlow.js)
- Features : historique complet interventions
- Prédiction : durée, succès, satisfaction
- Auto-tuning poids algorithme

### Optimisation Routes
- Planification journée complète
- Algorithme voyageur de commerce (TSP)
- Minimisation distance totale
- Respect fenêtres horaires clients

---

**Auteur :** Équipe Technique MCT  
**Date :** 5 Janvier 2026  
**Version :** 1.0  
**Statut :** 📝 Draft → Review
