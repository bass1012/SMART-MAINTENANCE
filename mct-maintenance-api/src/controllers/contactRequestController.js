const { ContactRequest, CustomerProfile, User } = require('../models');
const { validationResult } = require('express-validator');
const notificationService = require('../services/notificationService');

// Créer une nouvelle demande de rappel
async function createContactRequest(req, res) {
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
      name,
      email,
      phone,
      motive,
      message,
      preferredChannel,
      preferredTime,
      customerId
    } = req.body;

    // Si l'utilisateur est authentifié, on essaie d'associer son customerId
    let finalCustomerId = customerId;
    if (req.user && req.user.role === 'customer') {
      // Récupérer le profil client
      const customer = await CustomerProfile.findOne({ where: { user_id: req.user.id } });
      if (customer) {
        finalCustomerId = customer.id;
      }
    }

    const contactRequest = await ContactRequest.create({
      customerId: finalCustomerId || null,
      name,
      email: email || null,
      phone,
      motive,
      message,
      preferredChannel,
      preferredTime,
      urgencyLevel: 'low',
      status: 'pending'
    });

    // Notifier immédiatement tous les admins et managers (DB + Socket.IO + Push FCM)
    try {
      await notificationService.notifyAdmins({
        type: 'new_contact_request',
        title: '📞 Demande de rappel reçue',
        message: `${name} (${phone}) souhaite être rappelé (${motive || 'entretien'}).`,
        data: {
          contactRequestId: contactRequest.id,
          name,
          phone,
          motive,
          preferredChannel,
          preferredTime
        },
        priority: 'high',
        actionUrl: `/contact-requests?id=${contactRequest.id}`
      });

      // Émettre l'événement direct sur la socket des clients du dashboard
      const io = req.app.get('io') || notificationService.io;
      if (io) {
        io.emit('contact_request_created', contactRequest);
        io.emit('new_contact_request', contactRequest);
      }
    } catch (notifError) {
      console.error('⚠️ Erreur envoi notification rappel aux admins:', notifError);
    }

    res.status(201).json({
      success: true,
      message: 'Votre demande a été envoyée avec succès',
      data: contactRequest
    });
  } catch (error) {
    console.error('Erreur création demande contact:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création de la demande de contact'
    });
  }
}

// Récupérer toutes les demandes de contact (Admin/Tech)
async function getContactRequests(req, res) {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      motive,
      urgencyLevel
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    if (status) where.status = status;
    if (motive) where.motive = motive;
    if (urgencyLevel) where.urgencyLevel = urgencyLevel;

    const { count, rows } = await ContactRequest.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']],
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['email']
            }
          ]
        }
      ]
    });

    res.json({
      success: true,
      data: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Erreur récupération demandes contact:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des demandes de contact'
    });
  }
}

// Mettre à jour une demande de contact (Admin/Tech/TL)
async function updateContactRequest(req, res) {
  try {
    const { id } = req.params;
    const { urgencyLevel, status, notes, resolutionNotes } = req.body;

    const contactRequest = await ContactRequest.findByPk(id);
    if (!contactRequest) {
      return res.status(404).json({
        success: false,
        error: 'Demande de contact non trouvée'
      });
    }

    const targetNotes = (notes || resolutionNotes || '').trim();

    if (status === 'resolved' && !targetNotes) {
      return res.status(400).json({
        success: false,
        error: 'Un commentaire de résolution expliquant l’action réalisée est obligatoire pour clore la demande.'
      });
    }

    if (urgencyLevel !== undefined) {
      contactRequest.urgencyLevel = urgencyLevel;
    }

    if (status !== undefined) {
      contactRequest.status = status;
    }

    if (targetNotes) {
      contactRequest.resolutionNotes = targetNotes;
      contactRequest.message = contactRequest.message
        ? `${contactRequest.message}\n\n[Action/Résolution]: ${targetNotes}`
        : `[Action/Résolution]: ${targetNotes}`;
    }

    await contactRequest.save();

    res.json({
      success: true,
      message: 'Demande de contact mise à jour avec succès',
      data: contactRequest
    });
  } catch (error) {
    console.error('Erreur mise à jour demande contact:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour de la demande de contact'
    });
  }
}

module.exports = {
  createContactRequest,
  getContactRequests,
  updateContactRequest
};
