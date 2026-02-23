/**
 * Contrôleur pour la gestion des Splits (équipements individuels)
 * 
 * Fonctionnalités:
 * - CRUD des splits
 * - Génération de QR codes
 * - Recherche par code QR
 * - Association avec offres/souscriptions
 */

const { Split, User, Subscription, MaintenanceOffer, Intervention, CustomerProfile } = require('../../models');
const { Op } = require('sequelize');
const QRCode = require('qrcode');
const path = require('path');
const fs = require('fs');

// ========================================
// CRÉER UN SPLIT
// ========================================
const createSplit = async (req, res) => {
  try {
    const {
      customer_id,
      brand,
      model,
      serial_number,
      power,
      power_type,
      location,
      floor,
      installation_date,
      warranty_end_date,
      notes,
      installation_address
    } = req.body;

    // Vérifier que le client existe
    const customer = await User.findByPk(customer_id);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Client non trouvé'
      });
    }

    // Créer le split (le split_code est généré automatiquement via hook)
    const split = await Split.create({
      customer_id,
      brand,
      model,
      serial_number,
      power,
      power_type: power_type || 'BTU',
      location,
      floor,
      installation_date,
      warranty_end_date,
      notes,
      installation_address,
      status: 'active'
    });

    // Générer le QR code
    const qrCodeUrl = await generateQRCode(split.split_code, split.id);
    
    // Mettre à jour avec l'URL du QR code
    await split.update({ qr_code_url: qrCodeUrl });

    console.log(`✅ Split créé: ${split.split_code} pour client ${customer_id}`);

    res.status(201).json({
      success: true,
      message: 'Split créé avec succès',
      data: split
    });

  } catch (error) {
    console.error('❌ Erreur création split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du split',
      error: error.message
    });
  }
};

// ========================================
// GÉNÉRER QR CODE POUR UN SPLIT
// ========================================
const generateQRCode = async (splitCode, splitId) => {
  try {
    // Créer le dossier s'il n'existe pas
    const qrCodeDir = path.join(__dirname, '../../../uploads/qrcodes');
    if (!fs.existsSync(qrCodeDir)) {
      fs.mkdirSync(qrCodeDir, { recursive: true });
    }

    const filename = `split_${splitId}_${splitCode}.png`;
    const filePath = path.join(qrCodeDir, filename);

    // Données à encoder dans le QR code (JSON avec le code split)
    const qrData = JSON.stringify({
      type: 'SPLIT',
      code: splitCode,
      id: splitId
    });

    // Générer le QR code
    await QRCode.toFile(filePath, qrData, {
      errorCorrectionLevel: 'H',
      type: 'png',
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#ffffff'
      }
    });

    // Retourner l'URL relative
    return `/uploads/qrcodes/${filename}`;

  } catch (error) {
    console.error('❌ Erreur génération QR code:', error);
    return null;
  }
};

// ========================================
// RECHERCHER UN SPLIT PAR CODE QR
// ========================================
const findByQRCode = async (req, res) => {
  try {
    const { code } = req.params;

    console.log(`🔍 Recherche split par code: ${code}`);

    const split = await Split.findOne({
      where: { split_code: code },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name', 'email', 'phone']
        },
        {
          model: Subscription,
          as: 'subscriptions',
          where: { status: 'active' },
          required: false,
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer',
              attributes: ['id', 'title', 'description', 'features', 'price']
            }
          ]
        }
      ]
    });

    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé',
        code: code
      });
    }

    // Récupérer l'offre active du split
    const activeSubscription = split.subscriptions && split.subscriptions.length > 0 
      ? split.subscriptions[0] 
      : null;

    // Récupérer les dernières interventions
    const recentInterventions = await Intervention.findAll({
      where: { split_id: split.id },
      order: [['created_at', 'DESC']],
      limit: 5,
      attributes: ['id', 'title', 'status', 'scheduled_date', 'created_at']
    });

    res.json({
      success: true,
      data: {
        split: {
          id: split.id,
          split_code: split.split_code,
          brand: split.brand,
          model: split.model,
          serial_number: split.serial_number,
          power: split.power,
          power_type: split.power_type,
          location: split.location,
          floor: split.floor,
          installation_date: split.installation_date,
          warranty_end_date: split.warranty_end_date,
          last_maintenance_date: split.last_maintenance_date,
          next_maintenance_date: split.next_maintenance_date,
          status: split.status,
          notes: split.notes,
          photo_url: split.photo_url,
          intervention_count: split.intervention_count
        },
        customer: split.customer,
        activeOffer: activeSubscription ? {
          subscription_id: activeSubscription.id,
          offer: activeSubscription.offer,
          start_date: activeSubscription.start_date,
          end_date: activeSubscription.end_date,
          status: activeSubscription.status
        } : null,
        recentInterventions
      }
    });

  } catch (error) {
    console.error('❌ Erreur recherche split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la recherche du split',
      error: error.message
    });
  }
};

// ========================================
// LISTER TOUS LES SPLITS D'UN CLIENT
// ========================================
const getCustomerSplits = async (req, res) => {
  try {
    const { customerId } = req.params;

    const splits = await Split.findAll({
      where: { customer_id: customerId },
      include: [
        {
          model: Subscription,
          as: 'subscriptions',
          where: { status: 'active' },
          required: false,
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer',
              attributes: ['id', 'title', 'description', 'price']
            }
          ]
        }
      ],
      order: [['created_at', 'DESC']]
    });

    // Formater la réponse avec l'offre active de chaque split
    const formattedSplits = splits.map(split => ({
      ...split.toJSON(),
      activeOffer: split.subscriptions && split.subscriptions.length > 0 
        ? split.subscriptions[0].offer 
        : null
    }));

    res.json({
      success: true,
      count: splits.length,
      data: formattedSplits
    });

  } catch (error) {
    console.error('❌ Erreur liste splits client:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des splits',
      error: error.message
    });
  }
};

// ========================================
// LISTER TOUS LES SPLITS (ADMIN)
// ========================================
const getAllSplits = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, status, customerId } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    
    if (search) {
      whereClause[Op.or] = [
        { split_code: { [Op.like]: `%${search}%` } },
        { brand: { [Op.like]: `%${search}%` } },
        { model: { [Op.like]: `%${search}%` } },
        { serial_number: { [Op.like]: `%${search}%` } },
        { location: { [Op.like]: `%${search}%` } }
      ];
    }
    
    if (status) {
      whereClause.status = status;
    }
    
    if (customerId) {
      whereClause.customer_id = customerId;
    }

    const { count, rows: splits } = await Split.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name', 'email', 'phone']
        },
        {
          model: Subscription,
          as: 'subscriptions',
          where: { status: 'active' },
          required: false,
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer',
              attributes: ['id', 'title']
            }
          ]
        }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json({
      success: true,
      data: splits,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit)
      }
    });

  } catch (error) {
    console.error('❌ Erreur liste splits:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des splits',
      error: error.message
    });
  }
};

// ========================================
// RÉCUPÉRER UN SPLIT PAR ID
// ========================================
const getSplitById = async (req, res) => {
  try {
    const { id } = req.params;

    const split = await Split.findByPk(id, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name', 'email', 'phone']
        },
        {
          model: Subscription,
          as: 'subscriptions',
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer'
            }
          ],
          order: [['created_at', 'DESC']]
        },
        {
          model: Intervention,
          as: 'interventions',
          limit: 10,
          order: [['created_at', 'DESC']],
          attributes: ['id', 'title', 'status', 'scheduled_date', 'created_at']
        }
      ]
    });

    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé'
      });
    }

    res.json({
      success: true,
      data: split
    });

  } catch (error) {
    console.error('❌ Erreur récupération split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du split',
      error: error.message
    });
  }
};

// ========================================
// METTRE À JOUR UN SPLIT
// ========================================
const updateSplit = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const split = await Split.findByPk(id);
    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé'
      });
    }

    // Empêcher la modification du split_code
    delete updateData.split_code;
    delete updateData.id;

    await split.update(updateData);

    console.log(`✅ Split mis à jour: ${split.split_code}`);

    res.json({
      success: true,
      message: 'Split mis à jour avec succès',
      data: split
    });

  } catch (error) {
    console.error('❌ Erreur mise à jour split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du split',
      error: error.message
    });
  }
};

// ========================================
// SUPPRIMER UN SPLIT
// ========================================
const deleteSplit = async (req, res) => {
  try {
    const { id } = req.params;

    const split = await Split.findByPk(id);
    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé'
      });
    }

    // Vérifier s'il y a des interventions ou souscriptions liées
    const linkedInterventions = await Intervention.count({ where: { split_id: id } });
    const linkedSubscriptions = await Subscription.count({ where: { split_id: id } });

    if (linkedInterventions > 0 || linkedSubscriptions > 0) {
      // Marquer comme inactif au lieu de supprimer
      await split.update({ status: 'inactive' });
      return res.json({
        success: true,
        message: 'Split marqué comme inactif (historique conservé)',
        data: split
      });
    }

    // Supprimer le QR code si existant
    if (split.qr_code_url) {
      const qrPath = path.join(__dirname, '../../../', split.qr_code_url);
      if (fs.existsSync(qrPath)) {
        fs.unlinkSync(qrPath);
      }
    }

    await split.destroy();

    console.log(`✅ Split supprimé: ${split.split_code}`);

    res.json({
      success: true,
      message: 'Split supprimé avec succès'
    });

  } catch (error) {
    console.error('❌ Erreur suppression split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression du split',
      error: error.message
    });
  }
};

// ========================================
// ASSOCIER UNE OFFRE À UN SPLIT
// ========================================
const assignOfferToSplit = async (req, res) => {
  try {
    const { splitId } = req.params;
    const { maintenance_offer_id, start_date, end_date, price } = req.body;

    const split = await Split.findByPk(splitId);
    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé'
      });
    }

    const offer = await MaintenanceOffer.findByPk(maintenance_offer_id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offre non trouvée'
      });
    }

    // Désactiver les anciennes souscriptions actives de ce split
    await Subscription.update(
      { status: 'expired' },
      { 
        where: { 
          split_id: splitId, 
          status: 'active' 
        } 
      }
    );

    // Créer la nouvelle souscription
    const subscription = await Subscription.create({
      customer_id: split.customer_id,
      split_id: splitId,
      maintenance_offer_id,
      status: 'active',
      start_date: start_date || new Date(),
      end_date: end_date || new Date(Date.now() + offer.duration * 30 * 24 * 60 * 60 * 1000),
      price: price || offer.price,
      payment_status: 'pending'
    });

    console.log(`✅ Offre "${offer.title}" associée au split ${split.split_code}`);

    res.status(201).json({
      success: true,
      message: `Offre "${offer.title}" associée au split avec succès`,
      data: {
        subscription,
        split,
        offer
      }
    });

  } catch (error) {
    console.error('❌ Erreur association offre-split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'association de l\'offre',
      error: error.message
    });
  }
};

// ========================================
// RÉGÉNÉRER LE QR CODE D'UN SPLIT
// ========================================
const regenerateQRCode = async (req, res) => {
  try {
    const { id } = req.params;

    const split = await Split.findByPk(id);
    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé'
      });
    }

    // Supprimer l'ancien QR code si existant
    if (split.qr_code_url) {
      const oldPath = path.join(__dirname, '../../../', split.qr_code_url);
      if (fs.existsSync(oldPath)) {
        fs.unlinkSync(oldPath);
      }
    }

    // Générer le nouveau QR code
    const qrCodeUrl = await generateQRCode(split.split_code, split.id);
    await split.update({ qr_code_url: qrCodeUrl });

    console.log(`✅ QR code régénéré pour split ${split.split_code}`);

    res.json({
      success: true,
      message: 'QR code régénéré avec succès',
      data: {
        split_code: split.split_code,
        qr_code_url: qrCodeUrl
      }
    });

  } catch (error) {
    console.error('❌ Erreur régénération QR code:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la régénération du QR code',
      error: error.message
    });
  }
};

// ========================================
// SCANNER UN SPLIT POUR UNE INTERVENTION
// ========================================
const scanSplitForIntervention = async (req, res) => {
  try {
    const { interventionId } = req.params;
    const { split_code, scan_method, exception_reason } = req.body;
    const technicianId = req.user.id;

    console.log(`🔍 Scan split pour intervention ${interventionId}`);
    console.log(`   Code: ${split_code}, Méthode: ${scan_method}`);

    // Trouver l'intervention
    const intervention = await Intervention.findByPk(interventionId);
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Vérifier que le technicien est bien assigné à cette intervention
    if (intervention.technician_id !== technicianId) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas assigné à cette intervention'
      });
    }

    // Trouver le split
    const split = await Split.findOne({
      where: { split_code },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name']
        },
        {
          model: Subscription,
          as: 'subscriptions',
          where: { status: 'active' },
          required: false,
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer'
            }
          ]
        }
      ]
    });

    if (!split) {
      return res.status(404).json({
        success: false,
        message: 'Split non trouvé avec ce code',
        code: split_code
      });
    }

    // Vérifier que le split appartient au bon client (si l'intervention a un customer_id)
    if (intervention.customer_id) {
      // Récupérer le CustomerProfile pour avoir le user_id
      const customerProfile = await CustomerProfile.findByPk(intervention.customer_id);
      if (customerProfile && customerProfile.user_id !== split.customer_id) {
        return res.status(400).json({
          success: false,
          message: 'Ce split n\'appartient pas au client de cette intervention',
          warning: 'SPLIT_CUSTOMER_MISMATCH',
          split_customer: split.customer,
          intervention_customer_id: intervention.customer_id
        });
      }
    }

    // Mettre à jour l'intervention avec le split scanné
    await intervention.update({
      split_id: split.id,
      split_scan_method: scan_method || 'qr_scan',
      split_scan_exception_reason: exception_reason || null,
      split_scanned_at: new Date()
    });

    // Mettre à jour la date du dernier entretien si l'intervention est de type maintenance
    // (à faire quand l'intervention est terminée)

    const activeOffer = split.subscriptions && split.subscriptions.length > 0 
      ? split.subscriptions[0] 
      : null;

    console.log(`✅ Split ${split_code} associé à intervention ${interventionId}`);
    if (activeOffer) {
      console.log(`   📋 Offre active: ${activeOffer.offer.title}`);
    } else {
      console.log(`   ⚠️ Aucune offre active sur ce split`);
    }

    res.json({
      success: true,
      message: 'Split scanné et associé à l\'intervention',
      data: {
        split: {
          id: split.id,
          split_code: split.split_code,
          brand: split.brand,
          model: split.model,
          power: split.power,
          location: split.location,
          last_maintenance_date: split.last_maintenance_date,
          status: split.status
        },
        activeOffer: activeOffer ? {
          id: activeOffer.id,
          offer_title: activeOffer.offer.title,
          offer_description: activeOffer.offer.description,
          features: activeOffer.offer.features,
          end_date: activeOffer.end_date
        } : null,
        hasActiveOffer: !!activeOffer
      }
    });

  } catch (error) {
    console.error('❌ Erreur scan split:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du scan du split',
      error: error.message
    });
  }
};

// ========================================
// MES SPLITS (POUR UN CLIENT CONNECTÉ)
// ========================================
const getMySplits = async (req, res) => {
  try {
    const customerId = req.user.id;

    const splits = await Split.findAll({
      where: { 
        customer_id: customerId,
        status: { [Op.ne]: 'out_of_service' }
      },
      include: [
        {
          model: Subscription,
          as: 'subscriptions',
          where: { status: 'active' },
          required: false,
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer',
              attributes: ['id', 'title', 'description', 'features', 'price']
            }
          ]
        }
      ],
      order: [['location', 'ASC'], ['created_at', 'DESC']]
    });

    const formattedSplits = splits.map(split => ({
      id: split.id,
      split_code: split.split_code,
      brand: split.brand,
      model: split.model,
      power: `${split.power} ${split.power_type}`,
      location: split.location,
      floor: split.floor,
      installation_date: split.installation_date,
      last_maintenance_date: split.last_maintenance_date,
      next_maintenance_date: split.next_maintenance_date,
      status: split.status,
      photo_url: split.photo_url,
      activeOffer: split.subscriptions && split.subscriptions.length > 0 
        ? split.subscriptions[0].offer 
        : null
    }));

    res.json({
      success: true,
      count: splits.length,
      data: formattedSplits
    });

  } catch (error) {
    console.error('❌ Erreur mes splits:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de vos splits',
      error: error.message
    });
  }
};

// ========================================
// LISTER LES SPLITS POUR UNE INTERVENTION
// ========================================
const getSplitsForIntervention = async (req, res) => {
  try {
    const { interventionId } = req.params;

    console.log(`🔍 Recherche splits pour intervention: ${interventionId}`);

    // Récupérer l'intervention pour obtenir le customer_id
    const Intervention = require('../../models').Intervention;
    const intervention = await Intervention.findByPk(interventionId);

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Récupérer les splits du client de cette intervention
    const splits = await Split.findAll({
      where: { customer_id: intervention.customer_id },
      include: [
        {
          model: Subscription,
          as: 'subscriptions',
          where: { status: 'active' },
          required: false,
          include: [
            {
              model: MaintenanceOffer,
              as: 'offer',
              attributes: ['id', 'title', 'description', 'price']
            }
          ]
        }
      ],
      order: [['created_at', 'DESC']]
    });

    // Formater la réponse avec l'offre active de chaque split
    const formattedSplits = splits.map(split => ({
      ...split.toJSON(),
      activeOffer: split.subscriptions && split.subscriptions.length > 0 
        ? split.subscriptions[0].offer 
        : null
    }));

    console.log(`✅ ${splits.length} splits trouvés pour le client ${intervention.customer_id}`);

    res.json({
      success: true,
      count: splits.length,
      data: formattedSplits
    });

  } catch (error) {
    console.error('❌ Erreur splits pour intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des splits',
      error: error.message
    });
  }
};

module.exports = {
  createSplit,
  findByQRCode,
  getCustomerSplits,
  getSplitsForIntervention,
  getAllSplits,
  getSplitById,
  updateSplit,
  deleteSplit,
  assignOfferToSplit,
  regenerateQRCode,
  scanSplitForIntervention,
  getMySplits,
  generateQRCode
};
