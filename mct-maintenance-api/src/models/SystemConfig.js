const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

/**
 * Modèle SystemConfig
 * Stocke les paramètres de configuration du système
 */
class SystemConfig extends Model {}

SystemConfig.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  key: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
    comment: 'Clé de configuration unique'
  },
  value: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Valeur de configuration (peut être JSON)'
  },
  type: {
    type: DataTypes.ENUM('string', 'number', 'boolean', 'json', 'array'),
    defaultValue: 'string',
    comment: 'Type de la valeur pour validation/parsing'
  },
  category: {
    type: DataTypes.STRING(50),
    allowNull: false,
    defaultValue: 'general',
    comment: 'Catégorie: general, diagnostic, email, location, notification'
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Description de la configuration'
  },
  is_public: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'Si true, accessible sans authentification admin'
  }
}, {
  sequelize,
  modelName: 'SystemConfig',
  tableName: 'system_configs',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

// Méthodes de classe pour accès simplifié
SystemConfig.getValue = async function(key, defaultValue = null) {
  try {
    const config = await this.findOne({ where: { key } });
    if (!config) return defaultValue;
    
    // Parser la valeur selon le type
    switch (config.type) {
      case 'number':
        return parseFloat(config.value) || defaultValue;
      case 'boolean':
        return config.value === 'true' || config.value === '1';
      case 'json':
      case 'array':
        try {
          return JSON.parse(config.value);
        } catch {
          return defaultValue;
        }
      default:
        return config.value || defaultValue;
    }
  } catch (error) {
    console.error(`Erreur récupération config ${key}:`, error);
    return defaultValue;
  }
};

SystemConfig.setValue = async function(key, value, options = {}) {
  try {
    const { type = 'string', category = 'general', description = null, is_public = false } = options;
    
    // Convertir la valeur en string si nécessaire
    let stringValue = value;
    if (type === 'json' || type === 'array' || typeof value === 'object') {
      stringValue = JSON.stringify(value);
    } else if (typeof value !== 'string') {
      stringValue = String(value);
    }
    
    const [config, created] = await this.findOrCreate({
      where: { key },
      defaults: {
        value: stringValue,
        type,
        category,
        description,
        is_public
      }
    });
    
    if (!created) {
      await config.update({ value: stringValue, type, description, is_public });
    }
    
    return config;
  } catch (error) {
    console.error(`Erreur mise à jour config ${key}:`, error);
    throw error;
  }
};

SystemConfig.getByCategory = async function(category) {
  try {
    const configs = await this.findAll({ where: { category } });
    const result = {};
    
    for (const config of configs) {
      switch (config.type) {
        case 'number':
          result[config.key] = parseFloat(config.value) || 0;
          break;
        case 'boolean':
          result[config.key] = config.value === 'true' || config.value === '1';
          break;
        case 'json':
        case 'array':
          try {
            result[config.key] = JSON.parse(config.value);
          } catch {
            result[config.key] = config.value;
          }
          break;
        default:
          result[config.key] = config.value;
      }
    }
    
    return result;
  } catch (error) {
    console.error(`Erreur récupération configs catégorie ${category}:`, error);
    return {};
  }
};

module.exports = SystemConfig;
