-- Migration: Ajouter les timestamps pour le workflow d'intervention
-- Date: 2025-10-28
-- Description: Ajoute les champs de timestamp pour tracker chaque étape du workflow technicien

USE mct_maintenance;

-- Ajouter les colonnes de timestamp
ALTER TABLE interventions 
ADD COLUMN accepted_at DATETIME NULL COMMENT 'Date/heure d\'acceptation par le technicien' AFTER status,
ADD COLUMN departed_at DATETIME NULL COMMENT 'Date/heure de départ (en route)' AFTER accepted_at,
ADD COLUMN arrived_at DATETIME NULL COMMENT 'Date/heure d\'arrivée sur les lieux' AFTER departed_at,
ADD COLUMN started_at DATETIME NULL COMMENT 'Date/heure de début de l\'intervention' AFTER arrived_at,
ADD COLUMN completed_at DATETIME NULL COMMENT 'Date/heure de fin de l\'intervention' AFTER started_at;

-- Créer des index pour optimiser les requêtes
CREATE INDEX idx_interventions_accepted_at ON interventions(accepted_at);
CREATE INDEX idx_interventions_completed_at ON interventions(completed_at);
CREATE INDEX idx_interventions_status_technician ON interventions(status, technician_id);

-- Afficher la structure mise à jour
DESCRIBE interventions;

-- Vérification
SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    IS_NULLABLE, 
    COLUMN_COMMENT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'mct_maintenance' 
  AND TABLE_NAME = 'interventions'
  AND COLUMN_NAME IN ('accepted_at', 'departed_at', 'arrived_at', 'started_at', 'completed_at')
ORDER BY ORDINAL_POSITION;
