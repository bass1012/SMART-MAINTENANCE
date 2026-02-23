-- Migration: Permettre email NULL dans la table users
-- Date: 2026-01-22
-- Description: Permet l'inscription par téléphone uniquement sans email

-- SQLite ne supporte pas ALTER COLUMN directement
-- Il faut recréer la table avec la nouvelle structure

-- 1. Créer une nouvelle table avec la structure correcte
CREATE TABLE users_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email VARCHAR(255) NULL,  -- Changé de NOT NULL à NULL
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(50) NOT NULL DEFAULT 'customer',
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  last_login DATETIME,
  email_verified BOOLEAN NOT NULL DEFAULT 0,
  email_verification_token VARCHAR(255),
  email_verification_expires DATETIME,
  phone_verified BOOLEAN NOT NULL DEFAULT 0,
  profile_image VARCHAR(255),
  fcm_token VARCHAR(255),
  preferences TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE(email)
);

-- 2. Copier les données de l'ancienne table vers la nouvelle
INSERT INTO users_new 
SELECT * FROM users;

-- 3. Supprimer l'ancienne table
DROP TABLE users;

-- 4. Renommer la nouvelle table
ALTER TABLE users_new RENAME TO users;

-- 5. Recréer les index si nécessaire
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
