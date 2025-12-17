-- Migration: Ajouter le support des articles personnalisés dans les commandes
-- Date: 2025-10-31
-- Description: Permet d'avoir des articles personnalisés (sans référence produit) dans les commandes

-- 1. Rendre product_id nullable (supprimer la contrainte NOT NULL)
-- Note: SQLite ne supporte pas ALTER COLUMN directement, il faut recréer la table

-- Sauvegarder les données existantes
CREATE TABLE order_items_backup AS SELECT * FROM order_items;

-- Supprimer l'ancienne table
DROP TABLE order_items;

-- Recréer la table avec product_id nullable
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER,  -- Maintenant nullable
  product_name TEXT,   -- Nouveau: nom du produit (pour articles personnalisés)
  is_custom INTEGER DEFAULT 0,  -- Nouveau: indique si c'est un article personnalisé
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total REAL NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

-- Restaurer les données
INSERT INTO order_items (id, order_id, product_id, product_name, is_custom, quantity, unit_price, total)
SELECT 
  id, 
  order_id, 
  product_id,
  NULL as product_name,  -- Anciennes commandes n'ont pas de product_name
  0 as is_custom,        -- Anciennes commandes sont des produits catalogue
  quantity, 
  unit_price, 
  total
FROM order_items_backup;

-- Supprimer la sauvegarde
DROP TABLE order_items_backup;

-- Créer des index pour optimiser les requêtes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_is_custom ON order_items(is_custom);

-- Note: Les articles personnalisés auront product_id = NULL et product_name rempli
