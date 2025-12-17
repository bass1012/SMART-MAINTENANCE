-- =====================================================
-- Migration: Créer table intervention_images
-- Date: 2025-10-30
-- Description: Table pour stocker les images associées aux interventions
-- =====================================================

-- Créer la table intervention_images
CREATE TABLE IF NOT EXISTS intervention_images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  intervention_id INTEGER NOT NULL,
  image_url VARCHAR(255) NOT NULL,
  `order` INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON DELETE CASCADE
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_intervention_images_intervention_id 
ON intervention_images(intervention_id);

-- Commentaires sur les colonnes
-- intervention_id: ID de l'intervention (clé étrangère)
-- image_url: Chemin relatif vers l'image (/uploads/interventions/xxx.jpg)
-- order: Ordre d'affichage (0 à 4 pour max 5 images)
-- created_at: Date de création de l'entrée
-- updated_at: Date de dernière modification

-- Exemples de données pour tests (optionnel)
-- INSERT INTO intervention_images (intervention_id, image_url, `order`) VALUES
--   (1, '/uploads/interventions/intervention-1730281234567-123456789.jpg', 0),
--   (1, '/uploads/interventions/intervention-1730281345678-987654321.jpg', 1);

-- Vérifier la création
SELECT 'Table intervention_images créée avec succès !' as message;
