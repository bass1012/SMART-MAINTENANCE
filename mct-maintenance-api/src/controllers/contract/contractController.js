const { Contract, User } = require('../../models');
const { Op } = require('sequelize');
const { notifyNewContract } = require('../../services/notificationHelpers');

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

module.exports = {
  getAllContracts,
  getContractById,
  createContract,
  updateContract,
  deleteContract,
  renewContract,
  cancelContract
};

