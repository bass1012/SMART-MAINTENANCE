const { Sequelize } = require('sequelize');
const path = require('path');
require('dotenv').config();

// Database configuration - SQLite for development
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: process.env.DB_STORAGE || path.join(__dirname, '../../database.sqlite'),
  logging: false, // Désactivé pour éviter la pollution des logs (change en console.log pour déboguer)
  pool: {
    max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true,
      paranoid: true, // Soft deletes
      freezeTableName: false
    }
  }
);

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
  await sequelize.sync({ force: false }); // Sécurisé, ne supprime pas les tables
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
