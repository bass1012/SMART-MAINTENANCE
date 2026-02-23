const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  email: {
    type: DataTypes.STRING(255),
    allowNull: true, // Permettre NULL si inscription par téléphone uniquement
    unique: true,
    validate: {
      // Custom validation to allow both regular emails and soft-deleted format (deleted_timestamp_email@domain)
      isValidEmail(value) {
        // Permettre NULL (inscription par téléphone uniquement)
        if (!value || value === null || value === 'null') return;
        
        // Allow soft-deleted format: deleted_timestamp_email@domain
        if (value.startsWith('deleted_')) {
          const emailPart = value.replace(/^deleted_\d+_/, '');
          // Si la partie email est vide ou "null", c'est OK (user sans email)
          if (!emailPart || emailPart === 'null' || emailPart === '') return;
          if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(emailPart)) {
            throw new Error('Invalid email format');
          }
        } else {
          // Validate normal email format
          if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(value)) {
            throw new Error('Invalid email format');
          }
        }
      }
    }
  },
  first_name: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  last_name: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  password_hash: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      notEmpty: true
    }
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: true,
    validate: {
      // Allow both regular phone numbers and soft-deleted format (deleted_timestamp_+number)
      is: /^(deleted_\d+_)?[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$/
    }
  },
  role: {
    type: DataTypes.ENUM('admin', 'customer', 'technician', 'depannage', 'manager'),
    allowNull: false,
    defaultValue: 'customer'
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'pending'),
    allowNull: false,
    defaultValue: 'pending'
  },
  last_login: {
    type: DataTypes.DATE,
    allowNull: true
  },
  email_verified: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  email_verification_token: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'Token de vérification email'
  },
  email_verification_expires: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'Date d\'expiration du token de vérification'
  },
  phone_verified: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  profile_image: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  fcm_token: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'Token FCM pour les notifications push mobiles'
  },
  created_by: {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: 'ID de l\'admin qui a créé cet utilisateur (pour admin/manager uniquement)'
  },
  preferences: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: {}
  }
}, {
  tableName: 'users',
  validate: {
    // Au moins email OU phone doit être fourni
    emailOrPhone() {
      if (!this.email && !this.phone) {
        throw new Error('Either email or phone number must be provided');
      }
    }
  },
  hooks: {
    beforeCreate: async (user) => {
      if (user.password_hash) {
        user.password_hash = await bcrypt.hash(user.password_hash, 12);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password_hash')) {
        user.password_hash = await bcrypt.hash(user.password_hash, 12);
      }
    }
  }
});

// Instance methods
User.prototype.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password_hash);
};

User.prototype.toJSON = function() {
  const values = Object.assign({}, this.get());
  delete values.password_hash;
  return values;
};

// Class methods
User.findByEmail = async function(email) {
  return await this.findOne({ where: { email } });
};

User.findByPhone = async function(phone) {
  return await this.findOne({ where: { phone } });
};

User.getActiveUsers = async function() {
  return await this.findAll({ where: { status: 'active' } });
};

User.getUsersByRole = async function(role) {
  return await this.findAll({ where: { role } });
};

module.exports = User;
