const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class ComplaintNote extends Model {}

ComplaintNote.init({
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  complaintId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'complaint_id',
    references: {
      model: 'complaints',
      key: 'id'
    }
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'user_id',
    references: {
      model: 'users',
      key: 'id'
    }
  },
  note: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  isInternal: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
    field: 'is_internal',
    comment: 'Si true, la note est visible uniquement par le staff'
  }
}, {
  sequelize,
  modelName: 'ComplaintNote',
  tableName: 'complaint_notes',
  timestamps: true,
  paranoid: true,
  underscored: true
});

module.exports = ComplaintNote;
