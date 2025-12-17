const { Equipment, User, CustomerProfile } = require('../../models');

// Liste des équipements
const listEquipments = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 50;
    const offset = (page - 1) * limit;
    const { customer_id, status, type } = req.query;

    const where = {};
    if (customer_id) where.customer_id = customer_id;
    if (status) where.status = status;
    if (type) where.type = type;

    const { count, rows } = await Equipment.findAndCountAll({
      where,
      limit,
      offset,
      order: [['createdAt', 'DESC']],
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'phone'],
          include: [{
            model: CustomerProfile,
            as: 'customerProfile',
            attributes: ['first_name', 'last_name']
          }]
        }
      ]
    });

    res.json({
      success: true,
      data: {
        equipments: rows,
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (err) {
    console.error('Error listing equipments:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors du chargement des équipements', 
      error: err.message 
    });
  }
};

// Détail d'un équipement
const getEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findByPk(req.params.id, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'phone'],
          include: [{
            model: CustomerProfile,
            as: 'customerProfile',
            attributes: ['first_name', 'last_name', 'address', 'city']
          }]
        }
      ]
    });

    if (!equipment) {
      return res.status(404).json({ 
        success: false, 
        message: 'Équipement non trouvé' 
      });
    }

    res.json({ success: true, data: equipment });
  } catch (err) {
    console.error('Error getting equipment:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors du chargement de l\'équipement', 
      error: err.message 
    });
  }
};

// Création d'un équipement
const createEquipment = async (req, res) => {
  try {
    const {
      customer_id,
      name,
      type,
      brand,
      model,
      serial_number,
      installation_date,
      purchase_date,
      warranty_expiry,
      location,
      status,
      notes
    } = req.body;

    // Validation
    if (!customer_id || !name || !type) {
      return res.status(400).json({
        success: false,
        message: 'Les champs customer_id, name et type sont requis'
      });
    }

    const equipment = await Equipment.create({
      customer_id,
      name,
      type,
      brand,
      model,
      serial_number,
      installation_date,
      purchase_date,
      warranty_expiry,
      location,
      status: status || 'active',
      notes
    });

    res.status(201).json({ 
      success: true, 
      message: 'Équipement créé avec succès',
      data: equipment 
    });
  } catch (err) {
    console.error('Error creating equipment:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la création de l\'équipement', 
      error: err.message 
    });
  }
};

// Mise à jour d'un équipement
const updateEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findByPk(req.params.id);
    
    if (!equipment) {
      return res.status(404).json({ 
        success: false, 
        message: 'Équipement non trouvé' 
      });
    }

    const {
      customer_id,
      name,
      type,
      brand,
      model,
      serial_number,
      installation_date,
      purchase_date,
      warranty_expiry,
      location,
      status,
      last_maintenance_date,
      next_maintenance_date,
      notes
    } = req.body;

    await equipment.update({
      customer_id,
      name,
      type,
      brand,
      model,
      serial_number,
      installation_date,
      purchase_date,
      warranty_expiry,
      location,
      status,
      last_maintenance_date,
      next_maintenance_date,
      notes
    });

    res.json({ 
      success: true, 
      message: 'Équipement mis à jour avec succès',
      data: equipment 
    });
  } catch (err) {
    console.error('Error updating equipment:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la mise à jour de l\'équipement', 
      error: err.message 
    });
  }
};

// Suppression d'un équipement (soft delete)
const deleteEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findByPk(req.params.id);
    
    if (!equipment) {
      return res.status(404).json({ 
        success: false, 
        message: 'Équipement non trouvé' 
      });
    }

    await equipment.destroy(); // Soft delete grâce à paranoid: true

    res.json({ 
      success: true, 
      message: 'Équipement supprimé avec succès' 
    });
  } catch (err) {
    console.error('Error deleting equipment:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la suppression de l\'équipement', 
      error: err.message 
    });
  }
};

module.exports = {
  listEquipments,
  getEquipment,
  createEquipment,
  updateEquipment,
  deleteEquipment
};
