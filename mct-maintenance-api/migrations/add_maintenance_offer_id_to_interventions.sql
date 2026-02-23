-- Migration pour ajouter maintenance_offer_id aux interventions
-- Date: 2026-01-21

-- Ajouter la colonne maintenance_offer_id à la table interventions
ALTER TABLE interventions 
ADD COLUMN maintenance_offer_id INTEGER REFERENCES maintenance_offers(id);

-- Index pour améliorer les performances de recherche
CREATE INDEX idx_interventions_maintenance_offer_id ON interventions(maintenance_offer_id);
