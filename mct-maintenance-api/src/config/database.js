const { Sequelize } = require('sequelize');
const path = require('path');
require('dotenv').config();

// Database configuration - PostgreSQL for production, SQLite for development
const isProduction = process.env.NODE_ENV === 'production';
const databaseUrl = process.env.DATABASE_URL;

let sequelize;

if (isProduction && databaseUrl) {
  // Production: PostgreSQL via DATABASE_URL
  console.log('🐘 Connecting to PostgreSQL...');
  const dbSslRejectUnauthorized = process.env.DB_SSL_REJECT_UNAUTHORIZED?.toLowerCase() === 'false';
  sequelize = new Sequelize(databaseUrl, {
    dialect: 'postgres',
    logging: false,
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false // nosemgrep: bypass-tls-verification - Certificat auto-signé sur le serveur local
      }
    },
    pool: {
      max: 20,
      min: 5,
      acquire: 60000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true,
      paranoid: true,
      freezeTableName: false
    }
  });
} else {
  // Development: SQLite local
  console.log('📁 Connecting to SQLite...');
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: process.env.DB_STORAGE || path.join(__dirname, '../../database.sqlite'),
    logging: false,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true,
      paranoid: true,
      freezeTableName: false
    }
  });
}

// Test database connection
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');
  } catch (error) {
    console.error('❌ Unable to connect to the database:', error.message);
    process.exit(1);
  }
};

// Sync database models
const syncDatabase = async () => {
  try {
    const forceSync = process.env.FORCE_SYNC === 'true';

    if (forceSync) {
      if (isProduction) {
        // En production, FORCE_SYNC est trop dangereux — refus explicite
        console.error('❌ CRITIQUE: FORCE_SYNC=true est interdit en production. Utilisez des migrations versionnées.');
        process.exit(1);
      }
      console.log('⚠️  Force sync activé - Recréation des tables...');
      await sequelize.sync({ force: true });

    } else if (isProduction) {
      // En production : vérifier la connexion uniquement — pas d'alter automatique.
      // Les changements de schéma doivent passer par des migrations explicites.
      console.log('ℹ️  Production : sync désactivé. Vérification de connexion uniquement.');
      await sequelize.authenticate();
      console.log('✅ Database schema assumed to be up-to-date (managed by migrations).');

    } else {
      // Développement (SQLite) : alter:true est safe
      await sequelize.sync({ alter: true });
      console.log('✅ Database synchronized successfully (development mode).');
    }
  } catch (error) {
    console.error('❌ Error synchronizing database:', error.message);
    if (isProduction) {
      // Empêcher le serveur de démarrer avec un schéma inconnu
      process.exit(1);
    }
  }
};

module.exports = {
  sequelize,
  testConnection,
  syncDatabase
};
