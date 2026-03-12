const { DiagnosticReport, Intervention, User, CustomerProfile, Quote } = require('../models');
const { sequelize } = require('../config/database');
const { Op } = require('sequelize');
const notificationService = require('../services/notificationService');

/**
 * Technicien soumet un rapport de diagnostic
 * POST /api/diagnostic-reports
 */
exports.submitReport = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { 
      intervention_id, 
      problem_description, 
      recommended_solution,
      parts_needed, // Array of {name, quantity, unit_price}
      labor_cost,
      estimated_total,
      urgency_level,
      estimated_duration,
      photos, // Array of URLs
      notes
    } = req.body;
    
    const technician_id = req.user.id;

    // Vérifier que l'intervention existe et est assignée au technicien
    const intervention = await Intervention.findOne({
      where: { id: intervention_id },
      include: [
        { model: CustomerProfile, as: 'customer' },
        { model: User, as: 'technician' }
      ]
    });

    if (!intervention) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Intervention non trouvée' });
    }

    if (intervention.technician_id !== technician_id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'Cette intervention ne vous est pas assignée' });
    }

    // Calculer le total estimé si les pièces ont des prix unitaires
    let calculatedTotal = labor_cost || 0;
    if (Array.isArray(parts_needed)) {
      const partsTotal = parts_needed.reduce((sum, part) => {
        const partTotal = (part.quantity || 0) * (part.unit_price || 0);
        return sum + partTotal;
      }, 0);
      calculatedTotal += partsTotal;
    }
    
    // Utiliser le total calculé si estimated_total n'est pas fourni
    const finalEstimatedTotal = estimated_total || calculatedTotal;

    // Créer le rapport de diagnostic
    const report = await DiagnosticReport.create({
      intervention_id,
      technician_id,
      problem_description,
      recommended_solution,
      parts_needed: JSON.stringify(parts_needed || []),
      labor_cost: labor_cost || 0,
      estimated_total: finalEstimatedTotal,
      urgency_level: urgency_level || 'medium',
      estimated_duration,
      photos: JSON.stringify(photos || []),
      notes,
      status: 'submitted',
      submitted_at: new Date()
    }, { transaction });

    // Mettre à jour le statut de l'intervention
    await intervention.update({ 
      status: 'diagnostic_submitted' 
    }, { transaction });

    await transaction.commit();

    // Notifier les admins et managers qu'un nouveau rapport est disponible (après le commit)
    try {
      const admins = await User.findAll({ where: { role: { [Op.in]: ['admin', 'manager'] }, status: 'active' } });
      for (const admin of admins) {
        await notificationService.create({
          userId: admin.id,
          type: 'diagnostic_report_submitted',
          title: 'Nouveau rapport de diagnostic',
          message: `Un rapport de diagnostic a été soumis pour l'intervention #${intervention_id}`,
          data: { intervention_id, report_id: report.id },
          priority: 'high',
          actionUrl: `/diagnostic-reports`
        });
      }
    } catch (notifError) {
      console.error('Error sending notifications:', notifError);
      // Ne pas bloquer la réponse si les notifications échouent
    }

    res.status(201).json({
      message: 'Rapport de diagnostic soumis avec succès',
      report: {
        ...report.toJSON(),
        intervention,
        technician: await User.findByPk(technician_id, { 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        })
      }
    });

  } catch (error) {
    // Rollback seulement si la transaction n'a pas déjà été commit
    if (!transaction.finished) {
      await transaction.rollback();
    }
    console.error('Error submitting diagnostic report:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la soumission du rapport', 
      error: error.message 
    });
  }
};

/**
 * Obtenir un rapport de diagnostic par ID
 * GET /api/diagnostic-reports/:id
 */
exports.getReportById = async (req, res) => {
  try {
    const { id } = req.params;

    const report = await DiagnosticReport.findByPk(id, {
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [
            { model: CustomerProfile, as: 'customer' },
            { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'] }
          ]
        },
        { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'] },
        { model: User, as: 'reviewer', attributes: ['id', 'first_name', 'last_name', 'email'] },
        { model: Quote, as: 'quotes' }
      ]
    });

    if (!report) {
      return res.status(404).json({ message: 'Rapport non trouvé' });
    }

    // Vérifier les permissions
    const user = req.user;
    const isAdmin = user.role === 'admin';
    const isTechnician = report.technician_id === user.id;
    const isCustomer = report.intervention?.customer?.user_id === user.id;

    if (!isAdmin && !isTechnician && !isCustomer) {
      return res.status(403).json({ message: 'Accès non autorisé' });
    }

    // Parser parts_needed si c'est un string JSON
    const reportData = report.toJSON();
    if (typeof reportData.parts_needed === 'string') {
      try {
        reportData.parts_needed = JSON.parse(reportData.parts_needed);
      } catch (e) {
        reportData.parts_needed = [];
      }
    }

    res.json(reportData);

  } catch (error) {
    console.error('Error fetching diagnostic report:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la récupération du rapport', 
      error: error.message 
    });
  }
};

/**
 * Lister les rapports de diagnostic (avec filtres)
 * GET /api/diagnostic-reports
 */
exports.listReports = async (req, res) => {
  try {
    const { status, technician_id, intervention_id, page = 1, limit = 20 } = req.query;
    const user = req.user;

    const where = {};
    
    // Filtres
    if (status) where.status = status;
    if (technician_id) where.technician_id = technician_id;
    if (intervention_id) where.intervention_id = intervention_id;

    // Si technicien, ne voir que ses rapports
    if (user.role === 'technician') {
      where.technician_id = user.id;
    }

    const offset = (page - 1) * limit;

    const { count, rows } = await DiagnosticReport.findAndCountAll({
      where,
      include: [
        { 
          model: Intervention, 
          as: 'intervention',
          include: [{ model: CustomerProfile, as: 'customer' }]
        },
        { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'] },
        { model: User, as: 'reviewer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ],
      order: [['submitted_at', 'DESC']],
      limit: parseInt(limit),
      offset
    });

    // Parser parts_needed pour chaque rapport si c'est un string JSON
    const reportsData = rows.map(report => {
      const reportJson = report.toJSON();
      if (typeof reportJson.parts_needed === 'string') {
        try {
          reportJson.parts_needed = JSON.parse(reportJson.parts_needed);
        } catch (e) {
          reportJson.parts_needed = [];
        }
      }
      return reportJson;
    });

    res.json({
      reports: reportsData,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit)
      }
    });

  } catch (error) {
    console.error('Error listing diagnostic reports:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la récupération des rapports', 
      error: error.message 
    });
  }
};

/**
 * Admin met à jour le statut d'un rapport
 * PATCH /api/diagnostic-reports/:id/status
 */
exports.updateReportStatus = async (req, res) => {
  const transaction = await sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const reviewer_id = req.user.id;

    const report = await DiagnosticReport.findByPk(id, {
      include: [
        { model: Intervention, as: 'intervention' },
        { model: User, as: 'technician' }
      ]
    });

    if (!report) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Rapport non trouvé' });
    }

    // Mettre à jour le rapport
    await report.update({
      status,
      reviewed_by: reviewer_id,
      reviewed_at: new Date(),
      notes: notes || report.notes
    }, { transaction });

    await transaction.commit();

    // Notifier le technicien
    await notificationService.create({
      userId: report.technician_id,
      type: 'diagnostic_report_reviewed',
      title: 'Rapport de diagnostic examiné',
      message: `Votre rapport pour l'intervention #${report.intervention_id} a été ${status === 'approved' ? 'approuvé' : 'examiné'}`,
      data: { report_id: report.id, status, role: 'technician' },
      priority: 'medium',
      actionUrl: `/diagnostic-reports`
    });

    res.json({
      message: 'Statut du rapport mis à jour',
      report: await DiagnosticReport.findByPk(id, {
        include: [
          { model: Intervention, as: 'intervention' },
          { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name'] },
          { model: User, as: 'reviewer', attributes: ['id', 'first_name', 'last_name'] }
        ]
      })
    });

  } catch (error) {
    await transaction.rollback();
    console.error('Error updating report status:', error);
    res.status(500).json({ 
      message: 'Erreur lors de la mise à jour du statut', 
      error: error.message 
    });
  }
};

module.exports = exports;
