# 🔧 Fonctionnalité: Workflow Complet de Diagnostic et Devis

## 📋 Vue d'ensemble

Cette fonctionnalité implémente un workflow complet pour les interventions de diagnostic, depuis la soumission du rapport par le technicien jusqu'à l'approbation finale après paiement du devis par le client.

### 🔄 Flux de Travail

```
1. Client crée une demande d'intervention (diagnostic)
   └─> Paiement des frais de diagnostic (4000 FCFA)
   
2. Technicien reçoit l'intervention assignée
   └─> Se rend sur place et effectue le diagnostic
   
3. Technicien soumet un rapport de diagnostic détaillé
   ├─> Problème identifié
   ├─> Solution recommandée
   ├─> Pièces nécessaires (avec prix)
   ├─> Coût de la main d'œuvre
   ├─> Total estimé
   ├─> Urgence (low/medium/high/critical)
   ├─> Durée estimée
   ├─> Photos (optionnel)
   └─> Notes additionnelles
   
4. Admin (back-office) reçoit notification du rapport
   └─> Examine le rapport et crée un devis officiel
   
5. Admin envoie le devis au client
   ├─> Le client reçoit une notification
   └─> Le client consulte le devis dans l'app mobile
   
6. Client décide d'accepter ou refuser
   
   ┌─ Si ACCEPTATION:
   │  └─> Client est redirigé vers le paiement (CinetPay)
   │     └─> Après paiement confirmé:
   │        ├─> Intervention marquée comme "approved"
   │        ├─> Technicien reçoit notification d'approbation
   │        └─> Technicien peut exécuter l'intervention
   
   └─ Si REFUS:
      └─> Client doit fournir un motif de refus
         ├─> Admin reçoit notification avec le motif
         └─> Technicien reçoit notification du refus
```

---

## 🗄️ Structure de la Base de Données

### Table: `diagnostic_reports`

Stocke les rapports de diagnostic soumis par les techniciens.

```sql
CREATE TABLE diagnostic_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  intervention_id INTEGER NOT NULL,  -- Lien vers l'intervention
  technician_id INTEGER NOT NULL,    -- Technicien qui a fait le diagnostic
  problem_description TEXT NOT NULL, -- Description du problème
  recommended_solution TEXT,         -- Solution proposée
  parts_needed TEXT,                 -- JSON: [{name, quantity, unit_price}]
  labor_cost REAL DEFAULT 0,         -- Coût de la main d'œuvre
  estimated_total REAL DEFAULT 0,    -- Total estimé
  urgency_level TEXT DEFAULT 'medium', -- low, medium, high, critical
  estimated_duration TEXT,           -- Durée estimée (ex: "2-3 heures")
  photos TEXT,                       -- JSON: ["url1", "url2", ...]
  notes TEXT,                        -- Notes additionnelles
  status TEXT DEFAULT 'submitted',   -- submitted, reviewed, quote_sent, approved, rejected
  submitted_at DATETIME,
  reviewed_by INTEGER,               -- Admin qui a examiné
  reviewed_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (intervention_id) REFERENCES interventions(id),
  FOREIGN KEY (technician_id) REFERENCES users(id),
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
);
```

### Extensions de la Table: `quotes`

Ajout de colonnes pour supporter le workflow de diagnostic.

```sql
-- Nouvelles colonnes ajoutées:
ALTER TABLE quotes ADD COLUMN intervention_id INTEGER;         -- Lien vers intervention
ALTER TABLE quotes ADD COLUMN diagnostic_report_id INTEGER;    -- Lien vers rapport
ALTER TABLE quotes ADD COLUMN line_items TEXT;                 -- JSON: lignes du devis
ALTER TABLE quotes ADD COLUMN sent_at DATETIME;                -- Quand envoyé au client
ALTER TABLE quotes ADD COLUMN viewed_at DATETIME;              -- Quand consulté par client
ALTER TABLE quotes ADD COLUMN responded_at DATETIME;           -- Quand client a répondu
ALTER TABLE quotes ADD COLUMN payment_status TEXT DEFAULT 'pending'; -- pending, paid
ALTER TABLE quotes ADD COLUMN paid_at DATETIME;                -- Date de paiement
ALTER TABLE quotes ADD COLUMN payment_method TEXT;             -- Méthode de paiement
ALTER TABLE quotes ADD COLUMN payment_transaction_id TEXT;     -- ID transaction CinetPay
```

### Statuts des Rapports de Diagnostic

| Statut | Description |
|--------|-------------|
| `submitted` | Rapport soumis par le technicien |
| `reviewed` | Rapport examiné par l'admin |
| `quote_sent` | Devis envoyé au client |
| `approved` | Devis accepté et payé, intervention approuvée |
| `rejected` | Devis rejeté par le client |

### Statuts des Interventions (mis à jour)

| Statut | Description |
|--------|-------------|
| `diagnostic_submitted` | Technicien a soumis le rapport |
| `quote_pending` | Devis envoyé, en attente de la décision du client |
| `quote_accepted` | Client a accepté le devis, en attente du paiement |
| `quote_rejected` | Client a rejeté le devis |
| `approved` | Paiement confirmé, technicien peut exécuter |

---

## 🔌 API Endpoints

### 1. Rapports de Diagnostic

#### **POST** `/api/diagnostic-reports`
Technicien soumet un rapport de diagnostic.

**Headers:**
```json
{
  "Authorization": "Bearer <token>"
}
```

**Body:**
```json
{
  "intervention_id": 123,
  "problem_description": "Le compresseur ne démarre pas. Condensateur défectueux.",
  "recommended_solution": "Remplacement du condensateur et vérification du circuit électrique",
  "parts_needed": [
    {"name": "Condensateur 40µF", "quantity": 1, "unit_price": 5000},
    {"name": "Fusible 10A", "quantity": 2, "unit_price": 500}
  ],
  "labor_cost": 15000,
  "estimated_total": 21000,
  "urgency_level": "high",
  "estimated_duration": "2-3 heures",
  "photos": ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"],
  "notes": "Le client souhaite une intervention rapide"
}
```

**Response:**
```json
{
  "message": "Rapport de diagnostic soumis avec succès",
  "report": {
    "id": 1,
    "intervention_id": 123,
    "technician_id": 5,
    "problem_description": "...",
    "status": "submitted",
    "submitted_at": "2024-01-15T10:30:00Z",
    "intervention": {...},
    "technician": {...}
  }
}
```

---

#### **GET** `/api/diagnostic-reports/:id`
Obtenir un rapport de diagnostic par ID.

**Response:**
```json
{
  "id": 1,
  "intervention_id": 123,
  "technician_id": 5,
  "problem_description": "...",
  "recommended_solution": "...",
  "parts_needed": [...],
  "labor_cost": 15000,
  "estimated_total": 21000,
  "urgency_level": "high",
  "status": "submitted",
  "intervention": {...},
  "technician": {...},
  "reviewer": null,
  "quotes": []
}
```

---

#### **GET** `/api/diagnostic-reports`
Lister les rapports avec filtres.

**Query Params:**
- `status`: submitted | reviewed | quote_sent | approved | rejected
- `technician_id`: ID du technicien
- `intervention_id`: ID de l'intervention
- `page`: Numéro de page (défaut: 1)
- `limit`: Nombre de résultats par page (défaut: 20)

**Response:**
```json
{
  "reports": [...],
  "pagination": {
    "total": 50,
    "page": 1,
    "limit": 20,
    "totalPages": 3
  }
}
```

---

#### **PATCH** `/api/diagnostic-reports/:id/status`
Admin met à jour le statut d'un rapport (réservé aux admins).

**Body:**
```json
{
  "status": "reviewed",
  "notes": "Rapport bien détaillé, création du devis en cours"
}
```

**Response:**
```json
{
  "message": "Statut du rapport mis à jour",
  "report": {...}
}
```

---

### 2. Workflow des Devis

#### **POST** `/api/quotes/from-report`
Admin crée un devis à partir d'un rapport de diagnostic (réservé aux admins).

**Body:**
```json
{
  "diagnostic_report_id": 1,
  "line_items": [
    {
      "description": "Condensateur 40µF",
      "quantity": 1,
      "unit_price": 5000,
      "total": 5000
    },
    {
      "description": "Fusible 10A",
      "quantity": 2,
      "unit_price": 500,
      "total": 1000
    },
    {
      "description": "Main d'œuvre - Remplacement condensateur",
      "quantity": 1,
      "unit_price": 15000,
      "total": 15000
    }
  ],
  "subtotal": 21000,
  "taxAmount": 0,
  "discountAmount": 0,
  "total": 21000,
  "notes": "Intervention urgente recommandée",
  "termsAndConditions": "Paiement avant intervention. Garantie 6 mois.",
  "expiryDays": 7
}
```

**Response:**
```json
{
  "message": "Devis créé et envoyé au client",
  "quote": {
    "id": 45,
    "reference": "QTE-1705320000-1",
    "customerId": 10,
    "customerName": "Jean Kouassi",
    "issueDate": "2024-01-15",
    "expiryDate": "2024-01-22",
    "status": "sent",
    "total": 21000,
    "intervention_id": 123,
    "diagnostic_report_id": 1,
    "sent_at": "2024-01-15T11:00:00Z",
    "payment_status": "pending"
  }
}
```

---

#### **GET** `/api/quotes/:id/details`
Obtenir les détails complets d'un devis (client, technicien ou admin).

**Response:**
```json
{
  "id": 45,
  "reference": "QTE-1705320000-1",
  "total": 21000,
  "status": "sent",
  "line_items": [...],
  "sent_at": "2024-01-15T11:00:00Z",
  "viewed_at": null,
  "responded_at": null,
  "payment_status": "pending",
  "intervention": {...},
  "diagnosticReport": {...}
}
```

---

#### **POST** `/api/quotes/:id/accept`
Client accepte un devis (déclenche la redirection vers le paiement).

**Response:**
```json
{
  "message": "Devis accepté. Veuillez procéder au paiement.",
  "quote": {...},
  "payment_required": true,
  "amount": 21000
}
```

---

#### **POST** `/api/quotes/:id/reject`
Client rejette un devis (motif obligatoire).

**Body:**
```json
{
  "rejection_reason": "Le prix est trop élevé. J'ai trouvé un autre prestataire."
}
```

**Response:**
```json
{
  "message": "Devis rejeté",
  "quote": {
    "id": 45,
    "status": "rejected",
    "rejection_reason": "Le prix est trop élevé. J'ai trouvé un autre prestataire.",
    "responded_at": "2024-01-15T14:30:00Z"
  }
}
```

---

### 3. Paiement des Devis

#### **POST** `/api/payments/cinetpay/initialize-quote`
Initialiser le paiement d'un devis accepté.

**Body:**
```json
{
  "quoteId": 45
}
```

**Response:**
```json
{
  "success": true,
  "payment_url": "https://checkout.cinetpay.com/payment/...",
  "transaction_id": "QTE-45-1705323456789",
  "amount": 21000
}
```

---

#### **POST** `/api/payments/cinetpay/notify-quote` (Webhook)
Webhook CinetPay pour confirmer le paiement du devis.

**Body** (envoyé par CinetPay):
```json
{
  "transaction_id": "QTE-45-1705323456789",
  "cpm_trans_id": "123456789"
}
```

**Actions automatiques après paiement confirmé:**
1. ✅ Devis marqué comme `payment_status: 'paid'`
2. ✅ Intervention marquée comme `status: 'approved'`
3. ✅ Rapport de diagnostic marqué comme `status: 'approved'`
4. 🔔 Notification envoyée au **technicien** (peut exécuter l'intervention)
5. 🔔 Notification envoyée au **client** (paiement confirmé)

---

## 🔔 Système de Notifications

### Notifications Envoyées

| Événement | Destinataire | Type | Titre |
|-----------|--------------|------|-------|
| Rapport soumis | Admins | `diagnostic_report_submitted` | "Nouveau rapport de diagnostic" |
| Rapport examiné | Technicien | `diagnostic_report_reviewed` | "Rapport de diagnostic examiné" |
| Devis envoyé | Client | `quote_received` | "Nouveau devis disponible" |
| Devis accepté | Admins + Technicien | `quote_accepted` | "Devis accepté" |
| Devis rejeté | Admins + Technicien | `quote_rejected` | "Devis rejeté" |
| Paiement confirmé | Client | `payment_confirmed` | "Paiement confirmé" |
| Intervention approuvée | Technicien | `intervention_approved` | "✅ Intervention approuvée" |

### Format des Notifications

```javascript
await notificationService.create({
  userId: 123,
  type: 'quote_received',
  title: 'Nouveau devis disponible',
  message: 'Un devis de 21000 FCFA a été créé pour votre intervention #123',
  data: {
    quote_id: 45,
    intervention_id: 123,
    total: 21000
  },
  priority: 'high', // low | medium | high | urgent
  actionUrl: '/quotes/45/details'
});
```

---

## 📱 Implémentation Mobile (À faire)

### Écrans à créer

1. **TechnicianDiagnosticReportScreen**
   - Formulaire de soumission du rapport
   - Champs: problème, solution, pièces, coûts, urgence, durée
   - Upload de photos
   - Bouton "Soumettre le rapport"

2. **ClientQuoteDetailsScreen**
   - Affichage du devis complet
   - Liste des lignes (pièces + main d'œuvre)
   - Total avec TVA/remise
   - Boutons: "Accepter" / "Refuser"
   - Si refus: modal pour saisir le motif

3. **QuotePaymentScreen** (similaire à DiagnosticPaymentScreen)
   - Affichage du montant à payer
   - Redirection vers CinetPay
   - Gestion du retour après paiement

4. **TechnicianApprovedInterventionsScreen**
   - Liste des interventions approuvées (payées)
   - Le technicien peut marquer comme "en cours" puis "terminée"

### Exemple d'appel API (Flutter)

```dart
// Technicien soumet un rapport
Future<void> submitDiagnosticReport(int interventionId) async {
  final response = await ApiService.post(
    '/diagnostic-reports',
    body: {
      'intervention_id': interventionId,
      'problem_description': _problemController.text,
      'recommended_solution': _solutionController.text,
      'parts_needed': _partsList,
      'labor_cost': _laborCost,
      'estimated_total': _calculateTotal(),
      'urgency_level': _selectedUrgency,
      'estimated_duration': _durationController.text,
      'photos': _uploadedPhotos,
      'notes': _notesController.text,
    },
  );
  
  if (response['success']) {
    // Afficher message de succès
    // Retourner à la liste des interventions
  }
}

// Client accepte un devis
Future<void> acceptQuote(int quoteId) async {
  final response = await ApiService.post('/quotes/$quoteId/accept');
  
  if (response['payment_required']) {
    // Rediriger vers le paiement
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotePaymentScreen(
          quoteId: quoteId,
          amount: response['amount'],
        ),
      ),
    );
  }
}
```

---

## 🖥️ Implémentation Dashboard (À faire)

### Pages à créer

1. **DiagnosticReportsPage** (page `/diagnostic-reports`)
   - Tableau des rapports avec filtres (statut, technicien, date)
   - Colonnes: ID, Intervention, Technicien, Problème, Total estimé, Urgence, Statut, Date
   - Actions: Voir détails, Créer devis, Changer statut

2. **DiagnosticReportDetailsPage** (modal ou page `/diagnostic-reports/:id`)
   - Affichage complet du rapport
   - Informations intervention et client
   - Liste des pièces nécessaires
   - Photos
   - Bouton "Créer un devis à partir de ce rapport"

3. **CreateQuoteFromReportPage** (modal ou page `/quotes/create-from-report/:reportId`)
   - Formulaire pré-rempli avec les données du rapport
   - Possibilité d'ajuster les lignes, ajouter des remises
   - Conditions générales
   - Bouton "Envoyer le devis au client"

4. **QuotesPage** (extension de la page existante)
   - Ajouter colonne "Intervention" et "Rapport"
   - Ajouter filtre "Type de devis" (standard / diagnostic workflow)
   - Afficher statut de paiement

### Exemple de composant React

```tsx
// DiagnosticReportsTable.tsx
const DiagnosticReportsTable: React.FC = () => {
  const [reports, setReports] = useState<DiagnosticReport[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchReports();
  }, []);

  const fetchReports = async () => {
    const response = await api.get('/diagnostic-reports');
    setReports(response.data.reports);
    setLoading(false);
  };

  const handleCreateQuote = (reportId: number) => {
    navigate(`/quotes/create-from-report/${reportId}`);
  };

  return (
    <Table
      columns={[
        { title: 'ID', dataIndex: 'id' },
        { title: 'Intervention', dataIndex: ['intervention', 'id'] },
        { title: 'Technicien', render: (record) => 
          `${record.technician.firstName} ${record.technician.lastName}` 
        },
        { title: 'Problème', dataIndex: 'problem_description', ellipsis: true },
        { title: 'Total estimé', render: (record) => 
          `${record.estimated_total} FCFA` 
        },
        { title: 'Urgence', dataIndex: 'urgency_level', render: (level) => 
          <Tag color={getUrgencyColor(level)}>{level.toUpperCase()}</Tag> 
        },
        { title: 'Statut', dataIndex: 'status', render: (status) => 
          <Badge status={getStatusType(status)} text={status} /> 
        },
        { title: 'Date', dataIndex: 'submitted_at', render: (date) => 
          dayjs(date).format('DD/MM/YYYY HH:mm') 
        },
        { title: 'Actions', render: (record) => (
          <Space>
            <Button onClick={() => viewDetails(record.id)}>Détails</Button>
            {record.status === 'submitted' && (
              <Button type="primary" onClick={() => handleCreateQuote(record.id)}>
                Créer devis
              </Button>
            )}
          </Space>
        )}
      ]}
      dataSource={reports}
      loading={loading}
      rowKey="id"
    />
  );
};
```

---

## 🧪 Tests

### Test 1: Soumission d'un rapport par le technicien

```bash
curl -X POST http://localhost:3000/api/diagnostic-reports \
  -H "Authorization: Bearer <technicien_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "intervention_id": 123,
    "problem_description": "Compresseur défectueux",
    "recommended_solution": "Remplacement compresseur",
    "parts_needed": [{"name": "Compresseur 12000 BTU", "quantity": 1, "unit_price": 50000}],
    "labor_cost": 20000,
    "estimated_total": 70000,
    "urgency_level": "high",
    "estimated_duration": "4 heures"
  }'
```

### Test 2: Création de devis par l'admin

```bash
curl -X POST http://localhost:3000/api/quotes/from-report \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "diagnostic_report_id": 1,
    "line_items": [
      {"description": "Compresseur 12000 BTU", "quantity": 1, "unit_price": 50000, "total": 50000},
      {"description": "Main d'\''œuvre", "quantity": 1, "unit_price": 20000, "total": 20000}
    ],
    "subtotal": 70000,
    "taxAmount": 0,
    "discountAmount": 0,
    "total": 70000,
    "notes": "Intervention urgente",
    "termsAndConditions": "Paiement avant intervention",
    "expiryDays": 7
  }'
```

### Test 3: Acceptation du devis par le client

```bash
curl -X POST http://localhost:3000/api/quotes/45/accept \
  -H "Authorization: Bearer <client_token>"
```

### Test 4: Paiement du devis

```bash
curl -X POST http://localhost:3000/api/payments/cinetpay/initialize-quote \
  -H "Authorization: Bearer <client_token>" \
  -H "Content-Type: application/json" \
  -d '{"quoteId": 45}'
```

---

## 📊 Statistiques et Rapports

### Métriques à suivre

- **Temps moyen** entre soumission du rapport et création du devis
- **Taux d'acceptation** des devis (acceptés / total envoyés)
- **Montant moyen** des devis
- **Taux de conversion** (devis acceptés et payés / devis envoyés)
- **Motifs de refus** les plus fréquents

### Requêtes SQL utiles

```sql
-- Nombre de rapports par statut
SELECT status, COUNT(*) as count 
FROM diagnostic_reports 
GROUP BY status;

-- Taux d'acceptation des devis
SELECT 
  COUNT(CASE WHEN status = 'accepted' THEN 1 END) * 100.0 / COUNT(*) as acceptance_rate
FROM quotes 
WHERE diagnostic_report_id IS NOT NULL;

-- Montant moyen des devis issus de diagnostics
SELECT AVG(total) as average_quote_amount
FROM quotes 
WHERE diagnostic_report_id IS NOT NULL;

-- Devis en attente de paiement
SELECT q.*, i.id as intervention_id, c.first_name, c.last_name
FROM quotes q
JOIN interventions i ON q.intervention_id = i.id
JOIN customer_profiles c ON i.customer_id = c.id
WHERE q.status = 'accepted' AND q.payment_status = 'pending';
```

---

## 🔒 Permissions et Sécurité

### Contrôles d'accès

| Action | Technicien | Client | Admin |
|--------|------------|--------|-------|
| Soumettre rapport | ✅ (si assigné) | ❌ | ✅ |
| Voir rapport | ✅ (si assigné) | ✅ (si son intervention) | ✅ |
| Modifier statut rapport | ❌ | ❌ | ✅ |
| Créer devis | ❌ | ❌ | ✅ |
| Voir devis | ✅ (si assigné) | ✅ (si son devis) | ✅ |
| Accepter/Refuser devis | ❌ | ✅ (si son devis) | ❌ |
| Initier paiement | ❌ | ✅ (si son devis) | ❌ |

### Validations importantes

- ✅ Technicien ne peut soumettre un rapport que pour une intervention qui lui est assignée
- ✅ Client ne peut accepter/refuser que ses propres devis
- ✅ Le devis doit être au statut "sent" pour être accepté/refusé
- ✅ Le devis ne peut être payé que s'il est au statut "accepted"
- ✅ Impossible de modifier un rapport après qu'un devis a été créé
- ✅ Le motif de refus est **obligatoire** lors du rejet d'un devis

---

## 🚀 Déploiement et Configuration

### Variables d'environnement

```bash
# CinetPay (paiements)
CINETPAY_API_KEY=your_api_key
CINETPAY_SITE_ID=your_site_id

# URLs
API_URL=https://api.mct-maintenance.com
FRONTEND_URL=https://app.mct-maintenance.com

# Notifications
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### Migration de la base de données

```bash
# Créer la table diagnostic_reports
cd mct-maintenance-api
sqlite3 database.sqlite < migrations/create_diagnostic_reports.sql

# Ajouter les colonnes à la table quotes
sqlite3 database.sqlite < migrations/extend_quotes_table.sql
```

---

## 📝 Notes de Développement

### Améliorations futures

1. **Photos du rapport**
   - Implémenter l'upload de photos depuis le mobile
   - Stockage sur serveur ou cloud (AWS S3, Firebase Storage)

2. **Signature électronique**
   - Le client signe le devis avant paiement
   - Ajout d'un champ `signed_at` et `signature_url`

3. **Historique des révisions**
   - Tracer toutes les modifications d'un rapport ou devis
   - Table `audit_log` pour la traçabilité

4. **Devis multi-options**
   - Permettre au technicien de proposer plusieurs solutions
   - Le client choisit l'option qui lui convient

5. **Chatbot IA pour l'analyse des rapports**
   - Analyser la description du problème
   - Suggérer automatiquement des solutions et pièces

6. **Intégration avec fournisseurs de pièces**
   - API pour vérifier la disponibilité des pièces en temps réel
   - Prix mis à jour automatiquement

---

## 📞 Support

Pour toute question ou problème:
- 📧 Email: support@mct-maintenance.com
- 📱 Téléphone: +225 XX XX XX XX XX
- 🐛 Issues GitHub: [mct-maintenance/issues](https://github.com/mct-maintenance/issues)

---

**Version:** 1.0.0  
**Dernière mise à jour:** 3 février 2026  
**Auteur:** Équipe MCT Maintenance
