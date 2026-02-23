const { Quote, DiagnosticReport, Intervention, User, CustomerProfile } = require('../models');
const { sequelize } = require('../config/database');
const notificationService = require('../services/notificationService');

/**
 * Admin crée un devis à partir d'un rapport de diagnostic
 * POST /api/quotes/from-report
 */
exports.createQuoteFromReport = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { 
      diagnostic_report_id,
      line_items, // Array of {description, quantity, unit_price, total}
      subtotal,
      taxAmount,
      discountAmount,
      total,
      notes,
      termsAndConditions,
      expiryDays = 7 // Validité du devis en jours
    } = req.body;

    // Récupérer le rapport de diagnostic
    const report = await DiagnosticReport.findByPk(diagnostic_report_id, {
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [{ model: CustomerProfile, as: 'customer' }]
        }
      ]
    });

    if (!report) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Rapport de diagnostic non trouvé' });
    }

    const intervention = report.intervention;
    const customer = intervention.customer;

    // Générer une référence unique pour le devis
    const reference = `QTE-${Date.now()}-${report.id}`;
    const issueDate = new Date();
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + expiryDays);

    // Créer le devis
    const quote = await Quote.create({
      reference,
      customerId: customer.id,
      customerName: `${customer.first_name} ${customer.last_name}`,
      issueDate,
      expiryDate,
      status: 'sent',
      subtotal: subtotal || 0,
      taxAmount: taxAmount || 0,
      discountAmount: discountAmount || 0,
      total: total || 0,
      notes,
      termsAndConditions,
      intervention_id: intervention.id,
      diagnostic_report_id: report.id,
      line_items: JSON.stringify(line_items || []),
      sent_at: new Date(),
      payment_status: 'pending'
    }, { transaction });

    // Mettre à jour le statut du rapport ET le estimated_total
    await report.update({ 
      status: 'quote_sent',
      estimated_total: total || 0  // 🆕 Mettre à jour le total estimé avec le montant du devis
    }, { transaction });

    // NE PAS changer le statut de l'intervention de diagnostic - elle reste 'diagnostic_submitted'
    // L'intervention de diagnostic est déjà terminée, le devis est juste une proposition
    // await intervention.update({ status: 'quote_pending' }, { transaction });
    console.log(`ℹ️ Intervention de diagnostic #${intervention.id} reste en statut '${intervention.status}'`);

    await transaction.commit();

    // Notifier le client
    await notificationService.create({
      userId: customer.user_id,
      type: 'quote_received',
      title: 'Nouveau devis disponible',
      message: `Un devis de ${total} FCFA a été créé pour votre intervention #${intervention.id}`,
      data: { 
        quote_id: quote.id, 
        intervention_id: intervention.id,
        total: total 
      },
      priority: 'high',
      actionUrl: `/devis/${quote.id}`
    });

    res.status(201).json({
      message: 'Devis créé et envoyé au client',
      quote: {
        ...quote.toJSON(),
        diagnostic_report: report,
        intervention
      }
    });

  } catch (error) {
    await transaction.rollback();
    console.error('Error creating quote from report:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la création du devis', 
      error: error.message 
    });
  }
};

/**
 * Client accepte un devis
 * POST /api/quotes/:id/accept
 */
exports.acceptQuote = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { execute_now, scheduled_date, second_contact } = req.body;
    const customer_user_id = req.user.id;

    const quote = await Quote.findByPk(id, {
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [
            { model: CustomerProfile, as: 'customer' },
            { model: User, as: 'assignedTo' }
          ]
        },
        { 
          model: DiagnosticReport, 
          as: 'diagnosticReport',
          include: [{ model: User, as: 'technician' }]
        }
      ]
    });

    if (!quote) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Devis non trouvé' });
    }

    // Vérifier que c'est bien le client qui accepte
    if (quote.intervention.customer.user_id !== customer_user_id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'Vous n\'êtes pas autorisé à accepter ce devis' });
    }

    // Vérifier que le devis n'est pas expiré
    const now = new Date();
    const expiryDate = new Date(quote.expiryDate);
    if (now > expiryDate) {
      await transaction.rollback();
      return res.status(400).json({ message: 'Ce devis a expiré' });
    }

    // Déterminer la date d'exécution
    let executionDate;
    if (execute_now === true) {
      executionDate = new Date();
      console.log('⚡ Exécution immédiate demandée pour le devis', id);
    } else if (scheduled_date) {
      executionDate = new Date(scheduled_date);
      if (executionDate <= new Date()) {
        await transaction.rollback();
        return res.status(400).json({ message: 'La date de l\'intervention doit être dans le futur' });
      }
    }

    // Mettre à jour le devis
    await quote.update({
      status: 'accepted',
      responded_at: new Date(),
      scheduled_date: executionDate || null,
      execute_now: execute_now || false,
      second_contact: second_contact || null
    }, { transaction });

    // Mettre à jour l'intervention
    const interventionStatus = execute_now ? 'in_progress' : 'quote_accepted';
    await quote.intervention.update({
      status: interventionStatus,
      scheduled_date: executionDate || null
    }, { transaction });

    // Mettre à jour le rapport
    if (quote.diagnosticReport) {
      await quote.diagnosticReport.update({
        status: 'approved'
      }, { transaction });
    }

    await transaction.commit();

    // Notifier les admins
    const admins = await User.findAll({ where: { role: 'admin' } });
    for (const admin of admins) {
      await notificationService.create({
        userId: admin.id,
        type: 'quote_accepted',
        title: 'Devis accepté',
        message: `Le devis ${quote.reference} a été accepté par le client`,
        data: { quote_id: quote.id, intervention_id: quote.intervention_id },
        priority: 'high',
        actionUrl: `/devis/${quote.id}`
      });
    }

    // Notifier le technicien
    if (quote.intervention.assigned_to) {
      const techMessage = execute_now 
        ? `Le client a accepté le devis pour l'intervention #${quote.intervention_id}. En attente du paiement.`
        : `Le client a accepté le devis pour l'intervention #${quote.intervention_id}. Intervention planifiée, paiement différé.`;
      
      await notificationService.create({
        userId: quote.intervention.assigned_to,
        type: 'quote_accepted',
        title: 'Devis accepté',
        message: techMessage,
        data: { quote_id: quote.id, intervention_id: quote.intervention_id },
        priority: 'high',
        actionUrl: `/interventions`
      });
    }

    // Retourner les infos différentes selon le mode d'exécution
    const responseMessage = execute_now 
      ? 'Devis accepté. Veuillez procéder au paiement.'
      : 'Devis accepté. L\'intervention est planifiée. Le paiement sera effectué le jour de l\'intervention.';

    res.json({
      message: responseMessage,
      quote: await Quote.findByPk(id, {
        include: [
          { model: Intervention, as: 'intervention' },
          { model: DiagnosticReport, as: 'diagnosticReport' }
        ]
      }),
      // Paiement immédiat seulement pour exécution immédiate
      payment_required: execute_now === true,
      payment_deferred: execute_now !== true,
      scheduled_date: executionDate,
      amount: quote.total
    });

  } catch (error) {
    await transaction.rollback();
    console.error('Error accepting quote:', error);
    res.status(500).json({ 
      message: 'Erreur lors de l\'acceptation du devis', 
      error: error.message 
    });
  }
};

/**
 * Client rejette un devis
 * POST /api/quotes/:id/reject
 */
exports.rejectQuote = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { rejection_reason } = req.body;
    const customer_user_id = req.user.id;

    if (!rejection_reason || rejection_reason.trim().length === 0) {
      return res.status(400).json({ message: 'Le motif du refus est obligatoire' });
    }

    const quote = await Quote.findByPk(id, {
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [
            { model: CustomerProfile, as: 'customer' },
            { model: User, as: 'assignedTo' }
          ]
        },
        { 
          model: DiagnosticReport, 
          as: 'diagnosticReport',
          include: [{ model: User, as: 'technician' }]
        }
      ]
    });

    if (!quote) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Devis non trouvé' });
    }

    // Vérifier que c'est bien le client qui rejette
    if (quote.intervention.customer.user_id !== customer_user_id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'Vous n\'êtes pas autorisé à rejeter ce devis' });
    }

    // Mettre à jour le devis
    await quote.update({
      status: 'rejected',
      rejection_reason,
      responded_at: new Date()
    }, { transaction });

    // Mettre à jour l'intervention
    await quote.intervention.update({
      status: 'quote_rejected'
    }, { transaction });

    // Mettre à jour le rapport
    if (quote.diagnosticReport) {
      await quote.diagnosticReport.update({
        status: 'rejected'
      }, { transaction });
    }

    await transaction.commit();

    // Notifier les admins
    const admins = await User.findAll({ where: { role: 'admin' } });
    for (const admin of admins) {
      await notificationService.create({
        userId: admin.id,
        type: 'quote_rejected',
        title: 'Devis rejeté',
        message: `Le devis ${quote.reference} a été rejeté: ${rejection_reason}`,
        data: { 
          quote_id: quote.id, 
          intervention_id: quote.intervention_id,
          rejection_reason 
        },
        priority: 'medium',
        actionUrl: `/devis/${quote.id}`
      });
    }

    // Notifier le technicien
    if (quote.intervention.assigned_to) {
      await notificationService.create({
        userId: quote.intervention.assigned_to,
        type: 'quote_rejected',
        title: 'Devis rejeté',
        message: `Le client a rejeté le devis pour l'intervention #${quote.intervention_id}`,
        data: { 
          quote_id: quote.id, 
          intervention_id: quote.intervention_id,
          rejection_reason 
        },
        priority: 'medium',
        actionUrl: `/interventions`
      });
    }

    res.json({
      message: 'Devis rejeté',
      quote: await Quote.findByPk(id, {
        include: [
          { model: Intervention, as: 'intervention' },
          { model: DiagnosticReport, as: 'diagnosticReport' }
        ]
      })
    });

  } catch (error) {
    await transaction.rollback();
    console.error('Error rejecting quote:', error);
    res.status(500).json({ 
      message: 'Erreur lors du rejet du devis', 
      error: error.message 
    });
  }
};

/**
 * Obtenir les détails d'un devis
 * GET /api/quotes/:id/details
 */
exports.getQuoteDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const quote = await Quote.findByPk(id, {
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [
            { model: CustomerProfile, as: 'customer' },
            { model: User, as: 'assignedTo', attributes: ['id', 'firstName', 'lastName', 'email', 'phoneNumber'] }
          ]
        },
        { 
          model: DiagnosticReport, 
          as: 'diagnosticReport',
          include: [{ model: User, as: 'technician', attributes: ['id', 'firstName', 'lastName', 'email'] }]
        }
      ]
    });

    if (!quote) {
      return res.status(404).json({ message: 'Devis non trouvé' });
    }

    // Vérifier les permissions
    const user = req.user;
    const isAdmin = user.role === 'admin';
    const isCustomer = quote.intervention?.customer?.user_id === user.id;
    const isTechnician = quote.intervention?.assigned_to === user.id;

    if (!isAdmin && !isCustomer && !isTechnician) {
      return res.status(403).json({ message: 'Accès non autorisé' });
    }

    // Enregistrer la consultation si c'est le client
    if (isCustomer && !quote.viewed_at) {
      await quote.update({ viewed_at: new Date() });
    }

    res.json(quote);

  } catch (error) {
    console.error('Error fetching quote details:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la récupération du devis', 
      error: error.message 
    });
  }
};

module.exports = exports;
