const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CustomerProfile = sequelize.define('CustomerProfile', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  first_name: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [2, 100]
    }
  },
  last_name: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [2, 100]
    }
  },
  commune: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  latitude: {
    type: DataTypes.DECIMAL(10, 7),
    allowNull: true
  },
  longitude: {
    type: DataTypes.DECIMAL(10, 7),
    allowNull: true
  },
  country: {
    type: DataTypes.STRING(50),
    allowNull: false,
    defaultValue: 'Côte d\'Ivoire'
  },
  city: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  company_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  company_type: {
    type: DataTypes.ENUM('household', 'healthcare', 'commerce', 'enterprise', 'administration'),
    allowNull: true
  },
  gender: {
    type: DataTypes.ENUM('male', 'female', 'other'),
    allowNull: true
  },
  preferences: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: {
      language: 'fr',
      currency: 'XOF',
      notifications: {
        email: true,
        sms: true,
        push: true
      },
      marketing: {
        email: false,
        sms: false
      }
    }
  }
}, {
  tableName: 'customer_profiles',
  indexes: [
    {
      unique: true,
      fields: ['user_id']
    },
    {
      fields: ['first_name', 'last_name']
    },
    {
      fields: ['company_type']
    }
  ]
});

// Instance methods
CustomerProfile.prototype.getFullName = function() {
  return `${this.first_name} ${this.last_name}`.trim();
};

// Class methods
CustomerProfile.findByUserId = async function(userId) {
  return await this.findOne({ where: { user_id: userId } });
};

CustomerProfile.getCustomersByCompanyType = async function(companyType) {
  return await this.findAll({ 
    where: { company_type: companyType },
    include: ['user']
  });
};

CustomerProfile.searchCustomers = async function(searchTerm) {
  const { Op } = require('sequelize');
  return await this.findAll({
    where: {
      [Op.or]: [
        { first_name: { [Op.iLike]: `%${searchTerm}%` } },
        { last_name: { [Op.iLike]: `%${searchTerm}%` } },
        { company_name: { [Op.iLike]: `%${searchTerm}%` } },
        { email: { [Op.iLike]: `%${searchTerm}%` } }
      ]
    },
    include: ['user']
  });
};

module.exports = CustomerProfile;
