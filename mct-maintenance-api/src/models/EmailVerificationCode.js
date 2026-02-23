const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const EmailVerificationCode = sequelize.define('EmailVerificationCode', {
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
    allowNull: false
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false
  },
  used: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  }
}, {
  tableName: 'email_verification_codes',
  timestamps: true,
  underscored: true,
  paranoid: false
});

// Générer un code à 6 chiffres
EmailVerificationCode.generateCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

module.exports = EmailVerificationCode;
