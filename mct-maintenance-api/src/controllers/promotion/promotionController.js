const Promotion = require('../../models/Promotion');
const { Op } = require('sequelize');

// Get all promotions with pagination and filters
const getAllPromotions = async (req, res) => {
  try {
    console.log('📋 Récupération des promotions - Query params:', req.query);
    
    const { page = 1, limit = 10, status, type, search } = req.query;
    const offset = (page - 1) * limit;
    
    const where = {};
    if (status === 'active') {
      where.isActive = true;
      where.startDate = { [Op.lte]: new Date() };
      where.endDate = { [Op.gte]: new Date() };
    } else if (status === 'inactive') {
      where.isActive = false;
    }
    
    if (type) where.type = type;
    
    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { code: { [Op.like]: `%${search}%` } }
      ];
    }
    
    console.log('📋 Filtres appliqués:', where);
    
    const { count, rows } = await Promotion.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ ${count} promotions trouvées, ${rows.length} retournées`);
    
    res.status(200).json({
      success: true,
      data: {
        promotions: rows,
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('❌ Error getting promotions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des promotions',
      error: error.message
    });
  }
};

const getPublicPromotions = async (req, res) => {
  try {
    const now = new Date();
    const promotions = await Promotion.findAll({
      where: {
        isActive: true,
        startDate: { [Op.lte]: now },
        endDate: { [Op.gte]: now }
      },
      order: [['created_at', 'DESC']]
    });
    
    res.status(200).json({
      success: true,
      data: promotions
    });
  } catch (error) {
    console.error('Error getting public promotions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des promotions publiques',
      error: error.message
    });
  }
};

const getPromotionById = async (req, res) => {
  try {
    const { id } = req.params;
    const promotion = await Promotion.findByPk(id);
    
    if (!promotion) {
      return res.status(404).json({
        success: false,
        message: 'Promotion non trouvée'
      });
    }
    
    res.status(200).json({
      success: true,
      data: promotion
    });
  } catch (error) {
    console.error('Error getting promotion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la promotion',
      error: error.message
    });
  }
};

const createPromotion = async (req, res) => {
  try {
    const { name, code, type, value, start_date, end_date, usage_limit, target, description } = req.body;
    
    // Vérifier si le code existe déjà
    const existingPromo = await Promotion.findOne({ where: { code } });
    if (existingPromo) {
      return res.status(400).json({
        success: false,
        message: 'Ce code promo existe déjà'
      });
    }
    
    const promotion = await Promotion.create({
      name,
      code,
      type,
      value,
      startDate: start_date,
      endDate: end_date,
      usageLimit: usage_limit,
      target,
      description,
      isActive: true
    });
    
    res.status(201).json({
      success: true,
      message: 'Promotion créée avec succès',
      data: promotion
    });
  } catch (error) {
    console.error('Error creating promotion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la promotion',
      error: error.message
    });
  }
};

const updatePromotion = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, code, type, value, start_date, end_date, usage_limit, target, description, is_active } = req.body;
    
    const promotion = await Promotion.findByPk(id);
    if (!promotion) {
      return res.status(404).json({
        success: false,
        message: 'Promotion non trouvée'
      });
    }
    
    await promotion.update({
      name: name || promotion.name,
      code: code || promotion.code,
      type: type || promotion.type,
      value: value !== undefined ? value : promotion.value,
      startDate: start_date || promotion.startDate,
      endDate: end_date || promotion.endDate,
      usageLimit: usage_limit !== undefined ? usage_limit : promotion.usageLimit,
      target: target || promotion.target,
      description: description !== undefined ? description : promotion.description,
      isActive: is_active !== undefined ? is_active : promotion.isActive
    });
    
    res.status(200).json({
      success: true,
      message: 'Promotion mise à jour avec succès',
      data: promotion
    });
  } catch (error) {
    console.error('Error updating promotion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de la promotion',
      error: error.message
    });
  }
};

const deletePromotion = async (req, res) => {
  try {
    const { id } = req.params;
    const promotion = await Promotion.findByPk(id);
    
    if (!promotion) {
      return res.status(404).json({
        success: false,
        message: 'Promotion non trouvée'
      });
    }
    
    await promotion.destroy();
    
    res.status(200).json({
      success: true,
      message: 'Promotion supprimée avec succès'
    });
  } catch (error) {
    console.error('Error deleting promotion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de la promotion',
      error: error.message
    });
  }
};

const activatePromotion = async (req, res) => {
  try {
    const { id } = req.params;
    const promotion = await Promotion.findByPk(id);
    
    if (!promotion) {
      return res.status(404).json({
        success: false,
        message: 'Promotion non trouvée'
      });
    }
    
    await promotion.update({ isActive: true });
    
    res.status(200).json({
      success: true,
      message: 'Promotion activée avec succès',
      data: promotion
    });
  } catch (error) {
    console.error('Error activating promotion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'activation de la promotion',
      error: error.message
    });
  }
};

const deactivatePromotion = async (req, res) => {
  try {
    const { id } = req.params;
    const promotion = await Promotion.findByPk(id);
    
    if (!promotion) {
      return res.status(404).json({
        success: false,
        message: 'Promotion non trouvée'
      });
    }
    
    await promotion.update({ isActive: false });
    
    res.status(200).json({
      success: true,
      message: 'Promotion désactivée avec succès',
      data: promotion
    });
  } catch (error) {
    console.error('Error deactivating promotion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la désactivation de la promotion',
      error: error.message
    });
  }
};

const validatePromotionCode = async (req, res) => {
  try {
    const { code } = req.body;
    const now = new Date();
    
    const promotion = await Promotion.findOne({ where: { code } });
    
    if (!promotion) {
      return res.status(404).json({
        success: false,
        message: 'Code promo invalide'
      });
    }
    
    // Vérifier si la promotion est active
    if (!promotion.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Cette promotion n\'est plus active'
      });
    }
    
    // Vérifier les dates
    if (new Date(promotion.startDate) > now) {
      return res.status(400).json({
        success: false,
        message: 'Cette promotion n\'a pas encore commencé'
      });
    }
    
    if (new Date(promotion.endDate) < now) {
      return res.status(400).json({
        success: false,
        message: 'Cette promotion a expiré'
      });
    }
    
    // Vérifier la limite d'utilisation
    if (promotion.usageLimit && promotion.usageCount >= promotion.usageLimit) {
      return res.status(400).json({
        success: false,
        message: 'Cette promotion a atteint sa limite d\'utilisation'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Code promo valide',
      data: promotion
    });
  } catch (error) {
    console.error('Error validating promotion code:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la validation du code promo',
      error: error.message
    });
  }
};

module.exports = {
  getAllPromotions,
  getPublicPromotions,
  getPromotionById,
  createPromotion,
  updatePromotion,
  deletePromotion,
  activatePromotion,
  deactivatePromotion,
  validatePromotionCode
};
