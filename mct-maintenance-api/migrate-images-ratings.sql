-- Migration: Stockage images en DB + support rating technicien
-- Date: 2026-04-27
-- À exécuter UNE SEULE FOIS sur le VPS

-- 1. Agrandir la colonne profile_image pour stocker les data URL base64
ALTER TABLE users ALTER COLUMN profile_image TYPE TEXT;

-- 2. Ajouter la colonne imageUrl à la table equipments (si elle n'existe pas)
ALTER TABLE equipments ADD COLUMN IF NOT EXISTS "imageUrl" TEXT;

-- Vérification
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name IN ('users', 'equipments')
  AND column_name IN ('profile_image', 'imageUrl');
