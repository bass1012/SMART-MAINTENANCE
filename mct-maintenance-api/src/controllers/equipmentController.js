const Equipment = require('../models/equipment.model');
const User = require('../models/user.model');

// Get all equipments for the current customer
const getMyEquipments = async (req, res) => {
  try {
    const userId = req.user.id;

    const equipments = await Equipment.findAll({
      where: {
        customer_id: userId,
        deleted_at: null
      },
      order: [['created_at', 'DESC']]
    });

    res.json({
      success: true,
      data: equipments
    });
  } catch (error) {
    console.error('Error fetching equipments:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des équipements'
    });
  }
};

// Get a single equipment
const getEquipment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const equipment = await Equipment.findOne({
      where: {
        id,
        customer_id: userId,
        deleted_at: null
      }
    });

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé'
      });
    }

    res.json({
      success: true,
      data: equipment
    });
  } catch (error) {
    console.error('Error fetching equipment:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'équipement'
    });
  }
};

// Create new equipment
const createEquipment = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      type,
      brand,
      model,
      serial_number,
      location,
      installation_date,
      purchase_date,
      warranty_end_date,
      notes,
      status
    } = req.body;

    // Validation
    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Le type d\'équipement est requis'
      });
    }

    // Check if serial number already exists
    if (serial_number) {
      const existingEquipment = await Equipment.findOne({
        where: { serial_number, deleted_at: null }
      });

      if (existingEquipment) {
        return res.status(409).json({
          success: false,
          message: 'Un équipement avec ce numéro de série existe déjà'
        });
      }
    }

    const equipment = await Equipment.create({
      customer_id: userId,
      type,
      brand,
      model,
      serial_number,
      location,
      installation_date,
      purchase_date,
      warranty_end_date,
      notes,
      status: status || 'active'
    });

    res.status(201).json({
      success: true,
      message: 'Équipement créé avec succès',
      data: equipment
    });
  } catch (error) {
    console.error('Error creating equipment:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de l\'équipement'
    });
  }
};

// Update equipment
const updateEquipment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const {
      type,
      brand,
      model,
      serial_number,
      location,
      installation_date,
      purchase_date,
      warranty_end_date,
      notes,
      status
    } = req.body;

    const equipment = await Equipment.findOne({
      where: {
        id,
        customer_id: userId,
        deleted_at: null
      }
    });

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé'
      });
    }

    // Check if serial number already exists (for other equipment)
    if (serial_number && serial_number !== equipment.serial_number) {
      const existingEquipment = await Equipment.findOne({
        where: {
          serial_number,
          id: { [require('sequelize').Op.ne]: id },
          deleted_at: null
        }
      });

      if (existingEquipment) {
        return res.status(409).json({
          success: false,
          message: 'Un équipement avec ce numéro de série existe déjà'
        });
      }
    }

    await equipment.update({
      type: type || equipment.type,
      brand,
      model,
      serial_number,
      location,
      installation_date,
      purchase_date,
      warranty_end_date,
      notes,
      status: status || equipment.status
    });

    res.json({
      success: true,
      message: 'Équipement mis à jour avec succès',
      data: equipment
    });
  } catch (error) {
    console.error('Error updating equipment:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de l\'équipement'
    });
  }
};

// Delete equipment (soft delete)
const deleteEquipment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const equipment = await Equipment.findOne({
      where: {
        id,
        customer_id: userId,
        deleted_at: null
      }
    });

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé'
      });
    }

    await equipment.update({
      deleted_at: new Date()
    });

    res.json({
      success: true,
      message: 'Équipement supprimé avec succès'
    });
  } catch (error) {
    console.error('Error deleting equipment:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de l\'équipement'
    });
  }
};

module.exports = {
  getMyEquipments,
  getEquipment,
  createEquipment,
  updateEquipment,
  deleteEquipment
};
