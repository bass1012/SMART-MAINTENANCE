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
  const enableSsl = process.env.DB_SSL !== 'false';
  const dbSslRejectUnauthorized = process.env.DB_SSL_REJECT_UNAUTHORIZED?.toLowerCase() === 'true';

  sequelize = new Sequelize(databaseUrl, {
    dialect: 'postgres',
    logging: false,
    dialectOptions: enableSsl ? {
      ssl: {
        require: true,
        rejectUnauthorized: dbSslRejectUnauthorized
      }
    } : {},
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

// Le démarrage de l'API ne doit jamais modifier le schéma. Les migrations
// versionnées sont exécutées séparément (`npm run migrate`) avant le déploiement.
const syncDatabase = async () => {
  try {
    if (process.env.FORCE_SYNC === 'true') {
      throw new Error('FORCE_SYNC est interdit : utilisez des migrations versionnées.');
    }
    await sequelize.authenticate();
    console.log('✅ Base accessible ; schéma géré exclusivement par migrations.');
  } catch (error) {
    console.error('❌ Error synchronizing database:', error.message);
    throw error;
  }
};

module.exports = {
  sequelize,
  testConnection,
  syncDatabase
};
