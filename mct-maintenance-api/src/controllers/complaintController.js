const Complaint = require('../models/Complaint');
const { validationResult } = require('express-validator');
const { notifyNewComplaint, notifyComplaintResponse, notifyComplaintStatusChange } = require('../services/notificationHelpers');


// Récupérer toutes les réclamations
async function getComplaints(req, res) {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      priority,
      customerId,
      orderId,
      productId,
      search
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Filtres
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (customerId) where.customerId = customerId;
    if (orderId) where.orderId = orderId;
    if (productId) where.productId = productId;

    // Recherche textuelle
    if (search) {
      const { Op } = require('sequelize');
      where[Op.or] = [
        { reference: { [Op.like]: `%${search}%` } },
        { subject: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } }
      ];
    }


    // Inclure les relations pour affichage frontend
    const { count, rows: complaints } = await Complaint.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']],
      include: [
        {
          model: require('../models/CustomerProfile'),
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: require('../models/User'),
              as: 'user',
              attributes: ['email']
            }
          ]
        },
        {
          model: require('../models/Product'),
          as: 'product',
          attributes: ['id', 'nom', 'reference']
        },
        {
          model: require('../models/Order'),
          as: 'order',
          attributes: ['id', 'reference']
        }
      ]
    });

    // Log pour déboguer les dates
    if (complaints.length > 0) {
      console.log('📋 Exemple de réclamation:', {
        id: complaints[0].id,
        reference: complaints[0].reference,
        created_at: complaints[0].created_at,
        createdAt: complaints[0].createdAt,
        dataValues: complaints[0].dataValues
      });
    }

    res.json({
      success: true,
      data: {
        complaints,
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des réclamations:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des réclamations'
    });
  }
}

// Récupérer une réclamation par ID
async function getComplaintById(req, res) {
  try {
    const { id } = req.params;

    const complaint = await Complaint.findByPk(id, {
      include: [
        {
          model: require('../models/CustomerProfile'),
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: require('../models/User'),
              as: 'user',
              attributes: ['email']
            }
          ]
        },
        {
          model: require('../models/Product'),
          as: 'product',
          attributes: ['id', 'nom', 'reference']
        },
        {
          model: require('../models/Order'),
          as: 'order',
          attributes: ['id', 'reference']
        }
      ]
    });

    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Réclamation non trouvée'
      });
    }

    res.json({
      success: true,
      data: complaint
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de la réclamation:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de la réclamation'
    });
  }
}

// Créer une nouvelle réclamation
async function createComplaint(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Données invalides',
        details: errors.array()
      });
    }

    const {
      customerId,
      orderId,
      productId,
      interventionId,
      subject,
      description,
      priority = 'medium',
      category
    } = req.body;

    // Générer une référence unique
    const currentYear = new Date().getFullYear();
    const count = await Complaint.count() + 1;
    const reference = `REC-${currentYear}-${count.toString().padStart(3, '0')}`;

    const complaint = await Complaint.create({
      reference,
      customerId,
      orderId,
      productId,
      interventionId,
      subject,
      description,
      priority,
      category,
      status: 'open'
    });

    // Récupérer la réclamation avec les relations pour la réponse
    const complaintWithRelations = await Complaint.findByPk(complaint.id, {
      include: [
        {
          model: require('../models/CustomerProfile'),
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: require('../models/User'),
              as: 'user',
              attributes: ['email']
            }
          ]
        },
        {
          model: require('../models/Product'),
          as: 'product',
          attributes: ['id', 'nom', 'reference']
        },
        {
          model: require('../models/Order'),
          as: 'order',
          attributes: ['id', 'reference']
        }
      ]
    });

    // 🔔 Notifier les admins de la nouvelle réclamation
    try {
      const customerUser = complaintWithRelations.customer?.user;
      if (customerUser) {
        const customer = {
          id: customerUser.id,
          first_name: complaintWithRelations.customer.first_name,
          last_name: complaintWithRelations.customer.last_name,
          email: customerUser.email
        };
        await notifyNewComplaint(complaintWithRelations, customer);
        console.log('✅ Notification réclamation envoyée aux admins');
      }
    } catch (notifError) {
      console.error('❌ Erreur notification réclamation:', notifError);
    }

    res.status(201).json({
      success: true,
      data: complaintWithRelations,
      message: 'Réclamation créée avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la création de la réclamation:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création de la réclamation'
    });
  }
}

// Mettre à jour une réclamation
async function updateComplaint(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Données invalides',
        details: errors.array()
      });
    }

    const { id } = req.params;
    const updateData = req.body;

    const complaint = await Complaint.findByPk(id);

    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Réclamation non trouvée'
      });
    }

    // Mise à jour de resolved_at si le statut change vers resolved
    if (updateData.status === 'resolved' && complaint.status !== 'resolved') {
      updateData.resolvedAt = new Date();
    }

    // Sauvegarder les valeurs AVANT la mise à jour pour détecter les vrais changements
    const previousValues = {
      status: complaint.status,
      priority: complaint.priority,
      resolution: complaint.resolution,
      description: complaint.description,
      subject: complaint.subject
    };

    await complaint.update(updateData);

    // Vérifier quels champs ont RÉELLEMENT changé
    const statusChanged = complaint.status !== previousValues.status;
    const priorityChanged = complaint.priority !== previousValues.priority;
    const resolutionChanged = complaint.resolution !== previousValues.resolution;
    const descriptionChanged = complaint.description !== previousValues.description;
    const subjectChanged = complaint.subject !== previousValues.subject;
    
    const somethingChanged = statusChanged || priorityChanged || resolutionChanged || descriptionChanged || subjectChanged;
    
    console.log('🔍 Changements détectés:', {
      statusChanged,
      priorityChanged,
      resolutionChanged,
      descriptionChanged,
      subjectChanged,
      somethingChanged
    });

    // Recharger avec les relations pour la notification
    const updatedComplaint = await Complaint.findByPk(id, {
      include: [{
        model: require('../models/CustomerProfile'),
        as: 'customer',
        include: [{
          model: require('../models/User'),
          as: 'user'
        }]
      }]
    });

    // Envoyer une notification au client seulement si un champ a changé
    if (somethingChanged && updatedComplaint.customer && updatedComplaint.customer.user) {
      try {
        if (statusChanged) {
          // Notification de changement de statut (prioritaire)
          await notifyComplaintStatusChange(
            updatedComplaint, 
            updatedComplaint.customer.user, 
            complaint.status
          );
          console.log(`✅ Notification changement statut réclamation ${id} vers "${complaint.status}" envoyée`);
        } else {
          // Notification générale de mise à jour
          await notifyComplaintResponse(
            updatedComplaint, 
            updatedComplaint.customer.user
          );
          console.log(`✅ Notification mise à jour réclamation ${id} envoyée au client`);
        }
      } catch (notifError) {
        console.error('Erreur lors de l\'envoi de la notification:', notifError);
      }
    } else if (!somethingChanged) {
      console.log(`ℹ️  Aucune modification détectée pour la réclamation ${id}`);
    } else {
      console.log(`⚠️  Pas de client trouvé pour la réclamation ${id}`);
    }

    res.json({
      success: true,
      data: updatedComplaint,
      message: 'Réclamation mise à jour avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de la réclamation:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour de la réclamation'
    });
  }
}

// Supprimer une réclamation (soft delete)
async function deleteComplaint(req, res) {
  try {
    const { id } = req.params;

    const complaint = await Complaint.findByPk(id);

    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Réclamation non trouvée'
      });
    }

    await complaint.destroy(); // Soft delete grâce à paranoid: true

    res.json({
      success: true,
      message: 'Réclamation supprimée avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la suppression de la réclamation:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression de la réclamation'
    });
  }
}

// Mettre à jour le statut d'une réclamation
async function updateComplaintStatus(req, res) {
  try {
    const { id } = req.params;
    const { status, resolution } = req.body;

    const complaint = await Complaint.findByPk(id);

    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Réclamation non trouvée'
      });
    }

    const updateData = { status };
    
    // Mise à jour de resolved_at si le statut change vers resolved
    if (status === 'resolved' && complaint.status !== 'resolved') {
      updateData.resolvedAt = new Date();
      if (resolution) {
        updateData.resolution = resolution;
      }
    }

    // Sauvegarder l'ancien statut AVANT la mise à jour
    const oldStatus = complaint.status;

    await complaint.update(updateData);

    // 🔔 Notifier le client pour TOUS les changements de statut
    if (status && status !== oldStatus) {
      try {
        const complaintWithCustomer = await Complaint.findByPk(id, {
          include: [{
            model: require('../models/CustomerProfile'),
            as: 'customer',
            include: [{
              model: require('../models/User'),
              as: 'user'
            }]
          }]
        });

        if (complaintWithCustomer?.customer?.user) {
          await notifyComplaintStatusChange(
            complaintWithCustomer, 
            complaintWithCustomer.customer.user, 
            status
          );
          console.log(`✅ Notification changement statut réclamation ${id} vers "${status}" envoyée`);
        } else {
          console.log(`⚠️  Pas de client trouvé pour la réclamation ${id}`);
        }
      } catch (notifError) {
        console.error('❌ Erreur notification changement de statut:', notifError);
      }
    }

    res.json({
      success: true,
      data: complaint,
      message: 'Statut de la réclamation mis à jour avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour du statut'
    });
  }
}

module.exports = {
  getComplaints,
  getComplaintById,
  createComplaint,
  updateComplaint,
  deleteComplaint,
  updateComplaintStatus
};