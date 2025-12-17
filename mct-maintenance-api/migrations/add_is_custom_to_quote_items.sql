-- Migration: Ajouter le champ isCustom à la table quote_items
-- Date: 2025-10-31
-- Description: Permet de distinguer les articles personnalisés des produits du catalogue

-- Ajouter la colonne isCustom
ALTER TABLE quote_items 
ADD COLUMN isCustom TINYINT(1) DEFAULT 0 COMMENT 'Indique si c''est un article personnalisé (1) ou un produit du catalogue (0)';

-- Créer un index pour optimiser les requêtes de filtrage
CREATE INDEX idx_quote_items_is_custom ON quote_items(isCustom);

-- Mettre à jour les enregistrements existants (tous sont des produits du catalogue)
UPDATE quote_items SET isCustom = 0 WHERE isCustom IS NULL;

-- Note: Les articles personnalisés auront productId = -1 par convention
