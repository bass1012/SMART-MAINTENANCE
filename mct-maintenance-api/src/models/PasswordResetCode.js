const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PasswordResetCode = sequelize.define('PasswordResetCode', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  code: {
    type: DataTypes.STRING(6),
    allowNull: false,
    validate: {
      is: /^\d{6}$/ // 6 chiffres
    }
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false
  },
  used: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  }
}, {
  tableName: 'password_reset_codes',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

// Méthode pour générer un code à 6 chiffres
PasswordResetCode.generateCode = function() {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Méthode pour vérifier si un code est valide
PasswordResetCode.prototype.isValid = function() {
  return !this.used && new Date() < new Date(this.expires_at);
};

module.exports = PasswordResetCode;

