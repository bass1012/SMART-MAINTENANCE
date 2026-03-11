const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const TechnicianProfile = sequelize.define('TechnicianProfile', {
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
  phone: {
    type: DataTypes.STRING(30),
    allowNull: false,
    validate: {
      notEmpty: true,
      is: /^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$/
    }
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  specialization: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  experience_years: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 0,
      max: 50
    }
  },
  certification: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  certification_date: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },
  availability_status: {
    type: DataTypes.ENUM('available', 'busy', 'offline'),
    allowNull: false,
    defaultValue: 'offline'
  },
  current_location_lat: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true,
    validate: {
      min: -90,
      max: 90
    }
  },
  current_location_lng: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true,
    validate: {
      min: -180,
      max: 180
    }
  },
  service_area: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: []
  },
  skills: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: []
  },
  hourly_rate: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    validate: {
      min: 0
    }
  },
  rating: {
    type: DataTypes.DECIMAL(3, 2),
    allowNull: true,
    validate: {
      min: 0,
      max: 5
    },
    defaultValue: 0
  },
  total_reviews: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  total_assignments: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  completed_assignments: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  is_verified: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  verification_documents: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: []
  },
  bio: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  working_hours: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: {
      monday: { start: '08:00', end: '18:00' },
      tuesday: { start: '08:00', end: '18:00' },
      wednesday: { start: '08:00', end: '18:00' },
      thursday: { start: '08:00', end: '18:00' },
      friday: { start: '08:00', end: '18:00' },
      saturday: { start: '08:00', end: '14:00' },
      sunday: { start: null, end: null }
    }
  },
  emergency_contact_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  emergency_contact_phone: {
    type: DataTypes.STRING(30),
    allowNull: true
  },
  emergency_contact_relation: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  bank_account: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: {}
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'technician_profiles',
  indexes: [
    {
      unique: true,
      fields: ['user_id']
    },
    {
      fields: ['availability_status']
    },
    {
      fields: ['specialization']
    },
    {
      fields: ['rating']
    }
  ]
});

// Instance methods
TechnicianProfile.prototype.getFullName = function() {
  return `${this.first_name} ${this.last_name}`.trim();
};

TechnicianProfile.prototype.updateLocation = async function(lat, lng) {
  this.current_location_lat = lat;
  this.current_location_lng = lng;
  await this.save();
};

TechnicianProfile.prototype.isAvailable = function() {
  return this.availability_status === 'available';
};

TechnicianProfile.prototype.calculateCompletionRate = function() {
  if (this.total_assignments === 0) return 0;
  return (this.completed_assignments / this.total_assignments) * 100;
};

// Class methods
TechnicianProfile.findByUserId = async function(userId) {
  return await this.findOne({ where: { user_id: userId } });
};

TechnicianProfile.getAvailableTechnicians = async function() {
  return await this.findAll({ 
    where: { availability_status: 'available' },
    include: ['user']
  });
};

TechnicianProfile.getTechniciansBySpecialization = async function(specialization) {
  return await this.findAll({ 
    where: { specialization: specialization },
    include: ['user']
  });
};

TechnicianProfile.getNearbyTechnicians = async function(lat, lng, radius = 10) {
  // This would typically use a spatial query
  // For now, we'll return all technicians and filter in application
  return await this.findAll({
    where: {
      current_location_lat: { [Op.ne]: null },
      current_location_lng: { [Op.ne]: null }
    },
    include: ['user']
  });
};

TechnicianProfile.getTopRatedTechnicians = async function(limit = 10) {
  return await this.findAll({
    where: {
      rating: { [Op.gte]: 4.0 },
      total_reviews: { [Op.gte]: 5 }
    },
    order: [['rating', 'DESC'], ['total_reviews', 'DESC']],
    limit: limit,
    include: ['user']
  });
};

module.exports = TechnicianProfile;
