-- Ajouter toutes les colonnes manquantes à la table interventions

BEGIN TRANSACTION;

-- Colonnes de base
ALTER TABLE interventions ADD COLUMN product_id INTEGER DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN contract_id INTEGER DEFAULT NULL;

-- Timestamps du workflow
ALTER TABLE interventions ADD COLUMN accepted_at DATETIME DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN departed_at DATETIME DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN arrived_at DATETIME DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN started_at DATETIME DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN completed_at DATETIME DEFAULT NULL;

-- Rapport d'intervention
ALTER TABLE interventions ADD COLUMN report_data TEXT DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN report_submitted_at DATETIME DEFAULT NULL;

-- Évaluation client
ALTER TABLE interventions ADD COLUMN rating INTEGER DEFAULT NULL;
ALTER TABLE interventions ADD COLUMN review TEXT DEFAULT NULL;

COMMIT;

-- Vérification
SELECT '=== Colonnes de la table interventions ===' AS info;
PRAGMA table_info(interventions);
