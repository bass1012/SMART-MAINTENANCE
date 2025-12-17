-- Migration: Ajouter les champs pour le rapport d'intervention
-- Date: 2025-10-28
-- Description: Ajoute les colonnes pour stocker les données du rapport

USE mct_maintenance;

-- Ajouter les colonnes de rapport
ALTER TABLE interventions 
ADD COLUMN report_data JSON NULL COMMENT 'Données du rapport (JSON)' AFTER completed_at,
ADD COLUMN report_submitted_at DATETIME NULL COMMENT 'Date de soumission du rapport' AFTER report_data;

-- Créer un index pour optimiser les recherches de rapports
CREATE INDEX idx_interventions_report_submitted ON interventions(report_submitted_at);

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
  AND COLUMN_NAME IN ('report_data', 'report_submitted_at')
ORDER BY ORDINAL_POSITION;
