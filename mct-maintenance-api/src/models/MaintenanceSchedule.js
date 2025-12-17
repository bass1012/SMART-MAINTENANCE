const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const MaintenanceSchedule = sequelize.define('MaintenanceSchedule', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  equipment_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'equipments',
      key: 'id'
    }
  },
  technician_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  scheduled_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  type: {
    type: DataTypes.ENUM('preventive', 'corrective', 'inspection'),
    allowNull: false
  },
  status: {
    type: DataTypes.ENUM('scheduled', 'in_progress', 'completed', 'cancelled'),
    allowNull: false,
    defaultValue: 'scheduled'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'maintenance_schedules',
  timestamps: true,
  paranoid: false, // Override global paranoid to match existing schema (no deleted_at column)
  underscored: false // Use camelCase timestamps (createdAt/updatedAt) per existing DB
});

module.exports = MaintenanceSchedule;
