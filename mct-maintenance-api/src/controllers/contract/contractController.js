const { Contract, User, Subscription, Intervention } = require('../../models');
const { Op } = require('sequelize');
const { notifyNewContract } = require('../../services/notificationHelpers');
const { sendEmail } = require('../../services/emailService');
const {
  sendContractSubscribedEmail,
  sendContractExpiringEmail
} = require('../../services/emailHelper');
const contractSchedulingService = require('../../services/contractSchedulingService');

// Contract Controller - Implementation complète
const getAllContracts = async (req, res) => {
  try {
    const { status, type, customer_id, page = 1, limit = 10 } = req.query;
    
    const where = {};
    if (status) where.status = status;
    if (type) where.type = type;
    if (customer_id) where.customer_id = customer_id;

    const offset = (page - 1) * limit;

    const result = await Contract.findAndCountAll({
      where,
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']]
    });

    res.status(200).json({
      success: true,
      data: {
        contracts: result.rows,
        total: result.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(result.count / limit)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des contrats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

const getContractById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const contract = await Contract.findByPk(id, {
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    res.status(200).json({
      success: true,
      data: contract
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
};

const createContract = async (req, res) => {
  try {
    const contractData = req.body;
    
    // Validation des champs requis (référence et titre seront générés automatiquement)
    if (!contractData.customer_id || !contractData.start_date || !contractData.end_date) {
      return res.status(400).json({
        success: false,
        message: 'Données manquantes: customer_id, start_date et end_date sont requis'
      });
    }

    // Générer automatiquement la référence au format CONT-YYYY-XXXXX
    const year = new Date().getFullYear();
    
    // Compter les contrats de l'année en cours
    const { Op } = require('sequelize');
    const startOfYear = new Date(year, 0, 1);
    const endOfYear = new Date(year, 11, 31, 23, 59, 59);
    
    const countThisYear = await Contract.count({
      where: {
        created_at: {
          [Op.between]: [startOfYear, endOfYear]
        }
      }
    });
    
    // Générer le numéro séquentiel (5 chiffres)
    const sequenceNumber = (countThisYear + 1).toString().padStart(5, '0');
    const reference = `CONT-${year}-${sequenceNumber}`;
    
    console.log(`📝 Génération référence contrat: ${reference}`);
    
    // Créer le contrat avec la référence générée (retirer title du contractData)
    const { title, ...dataWithoutTitle } = contractData;
    const contract = await Contract.create({
      ...dataWithoutTitle,
      reference,
      title: null // Mettre le titre à null
    });

    const createdContract = await Contract.findByPk(contract.id, {
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    // Envoyer une notification au client
    try {
      if (createdContract.customer) {
        await notifyNewContract(createdContract, createdContract.customer);
        console.log(`📧 Notification envoyée au client ${createdContract.customer.id} pour le contrat ${reference}`);
        
        // 📧 Email au client (souscription contrat - template professionnel)
        await sendContractSubscribedEmail(
          createdContract.get({ plain: true }),
          createdContract.customer.get({ plain: true })
        );
        console.log('✅ Email professionnel souscription contrat envoyé au client');
      }
    } catch (notifError) {
      console.error('Erreur lors de l\'envoi de la notification:', notifError);
      // Ne pas bloquer la création du contrat si la notification échoue
    }

    res.status(201).json({
      success: true,
      data: createdContract,
      message: `Contrat créé avec succès - Référence: ${reference}`
    });
  } catch (error) {
    console.error('Erreur lors de la création du contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du contrat',
      error: error.message
    });
  }
};

const updateContract = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const contract = await Contract.findByPk(id);
    
    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    await contract.update(updateData);

    const updatedContract = await Contract.findByPk(id, {
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    res.status(200).json({
      success: true,
      data: updatedContract
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du contrat',
      error: error.message
    });
  }
};

const deleteContract = async (req, res) => {
  try {
    const { id } = req.params;

    const contract = await Contract.findByPk(id);
    
    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    await contract.destroy();

    res.status(200).json({
      success: true,
      message: 'Contrat supprimé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la suppression du contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression du contrat',
      error: error.message
    });
  }
};

const renewContract = async (req, res) => {
  try {
    const { id } = req.params;
    const { end_date } = req.body;

    const contract = await Contract.findByPk(id);
    
    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    await contract.update({ 
      end_date: end_date,
      status: 'active'
    });

    const renewedContract = await Contract.findByPk(id, {
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    res.status(200).json({
      success: true,
      data: renewedContract,
      message: 'Contrat renouvelé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors du renouvellement du contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du renouvellement du contrat',
      error: error.message
    });
  }
};

const cancelContract = async (req, res) => {
  try {
    const { id } = req.params;

    const contract = await Contract.findByPk(id);
    
    if (!contract) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    await contract.update({ status: 'terminated' });

    const cancelledContract = await Contract.findByPk(id, {
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    res.status(200).json({
      success: true,
      data: cancelledContract,
      message: 'Contrat annulé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de l\'annulation du contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'annulation du contrat',
      error: error.message
    });
  }
};

// ============================================
// CONTRATS PROGRAMMÉS (Maintenance planifiée)
// ============================================

/**
 * Récupérer tous les contrats programmés
 */
const getScheduledContracts = async (req, res) => {
  try {
    const { customerId, status } = req.query;
    
    const where = { contract_type: 'scheduled' };
    
    if (customerId) {
      where.customer_id = customerId;
    }
    
    if (status) {
      where.status = status;
    }
    
    const contracts = await Subscription.findAll({
      where,
      order: [['created_at', 'DESC']]
    });
    
    res.status(200).json({
      success: true,
      data: contracts,
      message: 'Contrats programmés récupérés avec succès'
    });
  } catch (error) {
    console.error('Erreur récupération contrats programmés:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats programmés',
      error: error.message
    });
  }
};

/**
 * Créer un contrat programmé avec visites automatiques
 */
const createScheduledContract = async (req, res) => {
  try {
    const {
      customerId,
      equipment,
      model,
      firstInterventionDate,
      visitsTotal = 4,
      visitIntervalMonths = 3,
      durationMonths = 12,
      price = 0
    } = req.body;
    
    const result = await contractSchedulingService.createScheduledContract({
      customer_id: customerId,
      equipment_description: equipment,
      equipment_model: model,
      first_intervention_date: new Date(firstInterventionDate),
      visits_total: visitsTotal,
      visit_interval_months: visitIntervalMonths,
      duration_months: durationMonths,
      price
    });
    
    res.status(201).json({
      success: true,
      data: result,
      message: `Contrat programmé créé avec ${visitsTotal} visites planifiées`
    });
  } catch (error) {
    console.error('Erreur création contrat programmé:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du contrat programmé',
      error: error.message
    });
  }
};

/**
 * Récupérer les visites d'un contrat programmé
 */
const getScheduledVisits = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Récupérer le contrat
    const subscription = await Subscription.findByPk(id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }
    
    if (subscription.contract_type !== 'scheduled') {
      return res.status(400).json({
        success: false,
        message: 'Ce contrat n\'est pas un contrat programmé'
      });
    }
    
    // Récupérer toutes les interventions liées à ce contrat
    const interventions = await Intervention.findAll({
      where: { subscription_id: id },
      order: [['scheduled_date', 'ASC']]
    });
    
    res.status(200).json({
      success: true,
      data: {
        contract: subscription,
        visits: interventions,
        progress: {
          completed: subscription.visits_completed,
          total: subscription.visits_total,
          remaining: subscription.visits_total - subscription.visits_completed
        }
      },
      message: 'Visites récupérées avec succès'
    });
  } catch (error) {
    console.error('Erreur récupération visites:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des visites',
      error: error.message
    });
  }
};

/**
 * Récupérer toutes les visites à venir
 */
const getUpcomingVisits = async (req, res) => {
  try {
    const { days = 30 } = req.query;
    
    const visits = await contractSchedulingService.getUpcomingVisits(parseInt(days));
    
    res.status(200).json({
      success: true,
      data: visits,
      message: `${visits.length} visite(s) à venir dans les ${days} prochains jours`
    });
  } catch (error) {
    console.error('Erreur récupération visites à venir:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des visites à venir',
      error: error.message
    });
  }
};

module.exports = {
  getAllContracts,
  getContractById,
  createContract,
  updateContract,
  deleteContract,
  renewContract,
  cancelContract,
  // Contrats programmés
  getScheduledContracts,
  createScheduledContract,
  getScheduledVisits,
  getUpcomingVisits
};

