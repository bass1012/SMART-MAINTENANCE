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
  sequelize = new Sequelize(databaseUrl, {
    dialect: 'postgres',
    logging: false,
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
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
    // Vérifier si les tables existent déjà
    const forceSync = process.env.FORCE_SYNC === 'true';
    
    if (forceSync) {
      console.log('⚠️  Force sync activé - Recréation des tables...');
      await sequelize.sync({ force: true });
    } else {
      // Utiliser alter pour ajouter les colonnes/tables manquantes sans supprimer les données
      await sequelize.sync({ alter: true });
    }
    console.log('✅ Database synchronized successfully.');
  } catch (error) {
    console.error('❌ Error synchronizing database:', error.message);
  }
};

module.exports = {
  sequelize,
  testConnection,
  syncDatabase
};
