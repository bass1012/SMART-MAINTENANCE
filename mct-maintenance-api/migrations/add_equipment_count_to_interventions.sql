-- Migration: Ajouter la colonne equipment_count à la table interventions
-- Date: 2025-10-30
-- Description: Ajout du nombre d'équipements pour chaque intervention

-- Ajouter la colonne equipment_count
ALTER TABLE interventions ADD COLUMN equipment_count INTEGER DEFAULT 1;

-- Mettre à jour les interventions existantes avec la valeur par défaut
UPDATE interventions SET equipment_count = 1 WHERE equipment_count IS NULL;
