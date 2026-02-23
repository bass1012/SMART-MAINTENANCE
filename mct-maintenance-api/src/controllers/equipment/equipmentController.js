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

    // Utiliser l'ID de l'utilisateur connecté comme customer_id
    const customer_id = req.user.id;

    // Validation
    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Le champ type est requis'
      });
    }

    // Générer automatiquement le nom si non fourni
    const equipmentName = name || `${type}${brand ? ' ' + brand : ''}${model ? ' ' + model : ''}`;

    const equipment = await Equipment.create({
      customer_id,
      name: equipmentName,
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

    // Vérifier que l'équipement appartient à l'utilisateur connecté
    if (equipment.customer_id !== req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non autorisé à modifier cet équipement' 
      });
    }

    const {
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

    // Générer automatiquement le nom si non fourni et que type/brand/model changent
    const updatedName = name || (type || brand || model ? 
      `${type || equipment.type}${brand ? ' ' + brand : (equipment.brand ? ' ' + equipment.brand : '')}${model ? ' ' + model : (equipment.model ? ' ' + equipment.model : '')}` 
      : equipment.name);

    await equipment.update({
      name: updatedName,
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

    // Vérifier que l'équipement appartient à l'utilisateur connecté
    if (equipment.customer_id !== req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non autorisé à supprimer cet équipement' 
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

// Get equipments for current customer
const getMyEquipments = async (req, res) => {
  try {
    const userId = req.user.id;

    const equipments = await Equipment.findAll({
      where: {
        customer_id: userId
      },
      order: [['createdAt', 'DESC']]
    });

    res.json({
      success: true,
      data: equipments
    });
  } catch (err) {
    console.error('Error fetching my equipments:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors du chargement de vos équipements', 
      error: err.message 
    });
  }
};

module.exports = {
  listEquipments,
  getEquipment,
  getMyEquipments,
  createEquipment,
  updateEquipment,
  deleteEquipment
};
