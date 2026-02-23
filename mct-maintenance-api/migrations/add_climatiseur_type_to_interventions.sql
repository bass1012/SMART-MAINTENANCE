-- Migration pour ajouter la colonne climatiseur_type à la table interventions
-- Pour les interventions de type installation seulement

-- Ajouter la colonne climatiseur_type
ALTER TABLE interventions ADD COLUMN climatiseur_type VARCHAR(50) NULL 
COMMENT 'Type de climatiseur pour les installations (Mural, Allège, K7, Gainable, Armoire)';
