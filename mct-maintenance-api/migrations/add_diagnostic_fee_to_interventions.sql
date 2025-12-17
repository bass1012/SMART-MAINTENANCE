-- Migration: Ajout des champs de diagnostic aux interventions
-- Date: 2025-10-31

-- Ajouter le champ pour le coût du diagnostic
ALTER TABLE interventions ADD COLUMN diagnostic_fee DECIMAL(10, 2) DEFAULT 0.00;

-- Ajouter le champ pour indiquer si le diagnostic est gratuit
ALTER TABLE interventions ADD COLUMN is_free_diagnosis BOOLEAN DEFAULT 0;

-- Ajouter un commentaire pour expliquer la logique
-- Si le client a un contract_id, le diagnostic est gratuit (is_free_diagnosis = 1, diagnostic_fee = 0)
-- Sinon, le diagnostic coûte 4000 FCFA (is_free_diagnosis = 0, diagnostic_fee = 4000)
