const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { Intervention, User, CustomerProfile, DiagnosticReport } = require('../models');
const { Op } = require('sequelize');
const technicianController = require('../controllers/technician/technicianController');

const router = express.Router();

console.log('🔧 TechnicianRoutes chargé - VERSION AVEC LOGS DEBUG');

// All technician routes require authentication
router.use(authenticate);

// Dashboard needs to fetch locations (admin/agent/manager)
router.get('/locations', authorize('admin', 'agent', 'technician', 'superadmin', 'manager'), technicianController.getAllTechnicianLocations);

// Require technician role for the rest
router.use(authorize('technician'));

// Technician profile routes
router.get('/profile', technicianController.getTechnicianProfile);

router.put('/profile', (req, res) => {
  res.json({
    success: true,
    message: 'Technician profile updated successfully'
  });
});

// Technician availability routes
router.put('/availability', technicianController.updateAvailability);
router.patch('/:id/availability', technicianController.updateTechnicianAvailabilityByAdmin);
router.put('/:id/availability', technicianController.updateTechnicianAvailabilityByAdmin);

// Technician location routes
router.put('/location', technicianController.updateLocation);

// Technician assignments routes
router.get('/assignments', (req, res) => {
  res.json({
    success: true,
    message: 'Technician assignments retrieved successfully',
    data: []
  });
});

router.get('/assignments/:id', (req, res) => {
  res.json({
    success: true,
    message: 'Assignment details retrieved successfully',
    data: {}
  });
});

router.put('/assignments/:id/accept', (req, res) => {
  res.json({
    success: true,
    message: 'Assignment accepted successfully'
  });
});

router.put('/assignments/:id/reject', (req, res) => {
  res.json({
    success: true,
    message: 'Assignment rejected successfully'
  });
});

router.put('/assignments/:id/start', (req, res) => {
  res.json({
    success: true,
    message: 'Assignment started successfully'
  });
});

router.put('/assignments/:id/complete', (req, res) => {
  res.json({
    success: true,
    message: 'Assignment completed successfully'
  });
});

// Technician reports routes
router.post('/assignments/:id/reports', (req, res) => {
  res.json({
    success: true,
    message: 'Report submitted successfully'
  });
});

// NOTE: La route /reports complète est définie plus bas (ligne ~457)

router.get('/reports/:id', (req, res) => {
  res.json({
    success: true,
    message: 'Report details retrieved successfully',
    data: {}
  });
});

// Technician schedule routes
router.get('/schedule', (req, res) => {
  res.json({
    success: true,
    message: 'Technician schedule retrieved successfully',
    data: []
  });
});

router.put('/schedule', (req, res) => {
  res.json({
    success: true,
    message: 'Schedule updated successfully'
  });
});

// Technician statistics routes
router.get('/statistics', (req, res) => {
  res.json({
    success: true,
    message: 'Technician statistics retrieved successfully',
    data: {
      totalAssignments: 0,
      completedAssignments: 0,
      pendingAssignments: 0,
      averageRating: 0,
      totalEarnings: 0
    }
  });
});

// Dashboard stats route
router.get('/dashboard/stats', async (req, res) => {
  try {
    const technicianId = req.user.id;
    
    console.log(`📊 Récupération stats dashboard pour technicien ${technicianId}`);
    
    // Compter les interventions par statut
    const totalInterventions = await Intervention.count({
      where: { technician_id: technicianId }
    });
    
    const pendingInterventions = await Intervention.count({
      where: { technician_id: technicianId, status: 'pending' }
    });
    
    const completedInterventions = await Intervention.count({
      where: { technician_id: technicianId, status: 'completed' }
    });
    
    const inProgressInterventions = await Intervention.count({
      where: { technician_id: technicianId, status: 'in_progress' }
    });
    
    // Rendez-vous à venir (interventions futures)
    const now = new Date();
    const upcomingAppointments = await Intervention.count({
      where: {
        technician_id: technicianId,
        scheduled_date: { [Op.gte]: now },
        status: { [Op.in]: ['pending', 'assigned', 'in_progress'] }
      }
    });
    
    console.log(`✅ Stats: ${totalInterventions} total, ${pendingInterventions} pending, ${completedInterventions} completed`);
    
    // Récupérer toutes les interventions terminées avec évaluation
    const interventions = await Intervention.findAll({
      where: {
        technician_id: technicianId,
        status: 'completed',
        rating: { [Op.not]: null }
      }
    });

    const totalReviews = interventions.length;
    let sumRatings = 0;
    interventions.forEach(intervention => {
      sumRatings += intervention.rating;
    });
    const averageRating = totalReviews > 0 ? (sumRatings / totalReviews) : 0;

    res.json({
      success: true,
      data: {
        total_interventions: totalInterventions,
        pending_interventions: pendingInterventions,
        completed_interventions: completedInterventions,
        in_progress_interventions: inProgressInterventions,
        total_revenue: 0, // TODO: Implémenter calcul des revenus
        monthly_revenue: 0, // TODO: Implémenter calcul mensuel
        average_rating: parseFloat(averageRating.toFixed(2)),
        total_reviews: totalReviews,
        upcoming_appointments: upcomingAppointments
      }
    });
  } catch (error) {
    console.error('❌ Error fetching dashboard stats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
});

// Interventions routes
router.get('/interventions', async (req, res) => {
  try {
    const technicianId = req.user.id;
    const { status } = req.query;
    
    console.log(`📋 Récupération interventions pour technicien ${technicianId}, status: ${status || 'tous'}`);
    
    const where = { technician_id: technicianId };
    if (status) {
      where.status = status;
    }
    
    const interventions = await Intervention.findAll({
      where,
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          required: false,
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone']
          }]
        },
        {
          model: DiagnosticReport,
          as: 'diagnosticReports',
          required: false
        }
      ],
      order: [['scheduled_date', 'DESC']]
    });
    
    console.log(`✅ ${interventions.length} intervention(s) trouvée(s)`);
    
    // Formater les interventions pour l'app mobile
    const formattedInterventions = interventions.map(intervention => {
      const customer = intervention.customer;
      
      // Essayer de récupérer le nom depuis customer (CustomerProfile)
      let customerName = 'Client inconnu';
      let customerPhone = '';
      if (customer) {
        if (customer.first_name && customer.last_name) {
          customerName = `${customer.first_name} ${customer.last_name}`;
        } else if (customer.user) {
          customerName = customer.user.email || 'Client inconnu';
        }
        customerPhone = customer.user?.phone || '';
      }
      
      // Extraire date et heure de scheduled_date
      let dateStr = '';
      let timeStr = '';
      if (intervention.scheduled_date) {
        const scheduledDate = new Date(intervention.scheduled_date);
        dateStr = scheduledDate.toLocaleDateString('fr-FR');
        timeStr = scheduledDate.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
      }
      
      return {
        id: intervention.id,
        title: intervention.title,
        description: intervention.description,
        customer: customerName, // Nom du client pour l'affichage
        customer_name: customerName, // Alias
        address: intervention.address || '',
        date: dateStr, // Format attendu par l'app mobile
        time: timeStr, // Format attendu par l'app mobile
        scheduled_date: intervention.scheduled_date,
        scheduled_time: timeStr,
        status: intervention.status,
        priority: intervention.priority,
        type: intervention.intervention_type || 'repair',
        intervention_type: intervention.intervention_type || 'repair',
        climatiseur_type: intervention.climatiseur_type || null,
        customer_phone: customerPhone,
        report_data: intervention.report_data || null,
        report_submitted_at: intervention.report_submitted_at || null,
        diagnosticReports: intervention.diagnosticReports || []
      };
    });
    
    console.log(`✅ ${formattedInterventions.length} intervention(s) formatée(s) pour technicien ${technicianId}`);
    
    res.json({
      success: true,
      data: formattedInterventions
    });
  } catch (error) {
    console.error('❌ Error fetching interventions:', error);
    console.error('❌ Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des interventions',
      error: error.message
    });
  }
});

router.post('/interventions/:id/accept', async (req, res) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    console.log(`✅ Technicien ${technicianId} accepte intervention ${id}`);
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId }
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée ou non assignée à vous'
      });
    }
    
    await intervention.update({ status: 'in_progress' });
    
    console.log(`✅ Intervention ${id} acceptée, statut changé en 'in_progress'`);
    
    res.json({
      success: true,
      message: 'Intervention acceptée'
    });
  } catch (error) {
    console.error('❌ Error accepting intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'acceptation de l\'intervention'
    });
  }
});

/**
 * @swagger
 * /api/technician/interventions/{id}/report-unreachable:
 *   post:
 *     summary: Signaler que le client est injoignable ou absent
 *     tags: [Technician]
 */
router.post('/interventions/:id/report-unreachable', async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    const technicianId = req.user.id;

    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId },
      include: [
        { 
          model: CustomerProfile, 
          as: 'customer', 
          attributes: ['id', 'user_id', 'first_name', 'last_name'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'fcm_token']
          }]
        }
      ]
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée ou non autorisée'
      });
    }

    await intervention.update({ 
      status: 'client_unreachable',
      description: intervention.description + (notes ? `\n\n[ABSENCE SIGNALÉE] Notes du technicien : ${notes}` : '')
    });

    // Notifier les admins
    const notificationService = require('../services/notificationService');
    await notificationService.notifyAdmins({
      title: '🚨 Client Injoignable',
      message: `Le technicien a signalé le client ${intervention.customer?.first_name || ''} comme injoignable pour l'intervention #${intervention.id}`,
      type: 'alert',
      related_id: intervention.id
    });

    // Notifier le client
    if (intervention.customer && intervention.customer.user) {
      await notificationService.create({
        userId: intervention.customer.user.id,
        title: 'Technicien sur place',
        message: "Votre technicien MCT est sur place mais n'arrive pas à vous joindre. Sans réponse, l'intervention sera annulée veillez contacter le service client pour la reprogrammer ou aller sur l'application pour la reprogrammer.",
        type: 'alert',
        data: {
          relatedId: intervention.id,
          interventionId: intervention.id
        }
      });
    }

    res.json({
      success: true,
      message: 'Client signalé comme injoignable'
    });
  } catch (error) {
    console.error('❌ Erreur lors du signalement client injoignable:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du signalement'
    });
  }
});

router.post('/interventions/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    console.log(`✅ Technicien ${technicianId} termine intervention ${id}`);
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId }
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée ou non assignée à vous'
      });
    }
    
    await intervention.update({ 
      status: 'completed',
      completed_date: new Date()
    });
    
    console.log(`✅ Intervention ${id} terminée, statut changé en 'completed'`);
    
    res.json({
      success: true,
      message: 'Intervention terminée'
    });
  } catch (error) {
    console.error('❌ Error completing intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la finalisation de l\'intervention'
    });
  }
});

// Reports routes (enriched)
router.post('/reports', async (req, res) => {
  try {
    // TODO: Créer rapport en DB
    res.json({
      success: true,
      message: 'Rapport créé avec succès'
    });
  } catch (error) {
    console.error('Error creating report:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du rapport'
    });
  }
});

router.put('/reports/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Mettre à jour rapport en DB
    res.json({
      success: true,
      message: 'Rapport mis à jour'
    });
  } catch (error) {
    console.error('Error updating report:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du rapport'
    });
  }
});

// Reviews routes - ANCIENNE ROUTE SUPPRIMÉE, voir ligne ~817 pour la vraie implémentation

router.post('/reviews/:id/reply', async (req, res) => {
  try {
    const { id } = req.params;
    const { reply } = req.body;
    
    // TODO: Sauvegarder réponse en DB
    res.json({
      success: true,
      message: 'Réponse envoyée'
    });
  } catch (error) {
    console.error('Error replying to review:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la réponse'
    });
  }
});

// Calendar route
router.get('/calendar', async (req, res) => {
  try {
    const technicianId = req.user.id;
    const { start_date, end_date } = req.query;
    
    console.log(`📅 Récupération calendrier pour technicien ${technicianId}`);
    console.log(`📆 Période: ${start_date} → ${end_date}`);
    
    // Construire le filtre de dates
    const where = { technician_id: technicianId };
    
    if (start_date || end_date) {
      where.scheduled_date = {};
      if (start_date) {
        where.scheduled_date[Op.gte] = new Date(start_date);
      }
      if (end_date) {
        // Inclure toute la journée de fin
        const endDate = new Date(end_date);
        endDate.setHours(23, 59, 59, 999);
        where.scheduled_date[Op.lte] = endDate;
      }
    }
    
    const interventions = await Intervention.findAll({
      where,
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['phone', 'email']
            }
          ],
          required: false
        }
      ],
      order: [['scheduled_date', 'ASC']]
    });
    
    console.log(`✅ ${interventions.length} événement(s) trouvé(s) dans le calendrier`);
    
    // Formater pour le calendrier mobile
    const events = interventions.map(intervention => {
      const customer = intervention.customer;
      
      let customerName = 'Client inconnu';
      let customerPhone = null;
      if (customer) {
        customerName = `${customer.first_name} ${customer.last_name}`;
        customerPhone = customer.user?.phone || null;
      }
      
      return {
        id: intervention.id,
        title: intervention.title,
        description: intervention.description,
        customer_name: customerName,
        address: intervention.address || '',
        scheduled_date: intervention.scheduled_date,
        scheduled_time: intervention.scheduled_date ? 
          new Date(intervention.scheduled_date).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) : '',
        status: intervention.status,
        priority: intervention.priority,
        type: intervention.intervention_type || 'repair',
        date: intervention.scheduled_date, // Alias pour compatibilité
        time: intervention.scheduled_date ? 
          new Date(intervention.scheduled_date).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) : ''
      };
    });
    
    res.json({
      success: true,
      data: events
    });
  } catch (error) {
    console.error('❌ Error fetching calendar:', error);
    console.error('❌ Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du calendrier',
      error: error.message
    });
  }
});

// Get technician's submitted reports (Maintenance & Diagnostic)
router.get('/reports', async (req, res, next) => {
  try {
    const technicianId = req.user.id;
    const status = req.query.status; // draft, submitted, approved
    
    console.log(`📋 Technicien ${technicianId}: Récupération des rapports (Maintenance + Diagnostic)`);

    // 1. Récupérer les interventions assignées au technicien
    const techInterventions = await Intervention.findAll({
      where: { technician_id: technicianId },
      order: [['id', 'DESC']],
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          targetKey: 'user_id',
          attributes: ['id', 'user_id', 'first_name', 'last_name', 'company_name'],
          required: false
        }
      ]
    });

    const techInterventionIds = techInterventions.map(i => i.id);

    // Interventions avec rapport de maintenance
    const maintenanceInterventions = techInterventions.filter(
      i => i.report_submitted_at != null || i.report_data != null
    );

    // 2. Récupérer les rapports de diagnostic soumis par le technicien ou associés à ses interventions
    const diagWhere = techInterventionIds.length > 0
      ? {
          [Op.or]: [
            { technician_id: technicianId },
            { intervention_id: { [Op.in]: techInterventionIds } }
          ]
        }
      : { technician_id: technicianId };

    const diagnosticReports = await DiagnosticReport.findAll({
      where: diagWhere,
      order: [['id', 'DESC']],
      include: [
        {
          model: Intervention,
          as: 'intervention',
          required: false,
          include: [
            {
              model: CustomerProfile,
              as: 'customer',
              targetKey: 'user_id',
              attributes: ['id', 'user_id', 'first_name', 'last_name', 'company_name'],
              required: false
            }
          ]
        }
      ]
    });

    // Formater les rapports de maintenance
    const formattedMaintenanceReports = maintenanceInterventions.map(intervention => {
      const reportData = intervention.report_data ? 
        (typeof intervention.report_data === 'string' ? 
          JSON.parse(intervention.report_data) : intervention.report_data) 
        : {};

      const customerProfile = intervention.customer;
      const customerName = customerProfile ? 
        `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim() :
        'Client non renseigné';
      const customerCompany = customerProfile?.company_name || '';
      const reportDate = intervention.report_submitted_at || intervention.updatedAt || intervention.createdAt;

      return {
        id: intervention.id,
        report_type: 'maintenance',
        intervention_title: intervention.title || 'Intervention de Maintenance',
        title: intervention.title ? `Maintenance - ${intervention.title}` : 'Rapport de Maintenance',
        address: intervention.address || 'Non spécifiée',
        customer_name: customerName || 'Client non renseigné',
        customer_phone: '',
        customer_email: '',
        customer_company: customerCompany,
        created_at: reportDate,
        date: reportDate,
        status: reportData.status || intervention.status || 'submitted',
        work_description: reportData.work_description || intervention.description || '',
        duration: reportData.duration || 0,
        materials_used: reportData.materials_used || [],
        observations: reportData.observations || '',
        photos_count: reportData.photos_count || (Array.isArray(reportData.photos) ? reportData.photos.length : 0),
        total_cost: 0,
        pression: reportData.pression || '',
        freon: reportData.freon || '',
        puissance: reportData.puissance || reportData.temperature || '',
        intensite: reportData.intensite || '',
        tension: reportData.tension || '',
        equipments: reportData.equipments || [],
        equipment_state: reportData.equipment_state || '',
        equipment_type: reportData.equipment_type || '',
        equipment_brand: reportData.equipment_brand || '',
        technician_name: reportData.technician_name || '',
        intervention_date: reportData.intervention_date || '',
        start_time: reportData.start_time || '',
        end_time: reportData.end_time || '',
        intervention_nature: reportData.intervention_nature || '',
        spare_parts: reportData.spare_parts || [],
      };
    });

    // Formater les rapports de diagnostic
    const formattedDiagnosticReports = diagnosticReports.map(diag => {
      const intervention = diag.intervention || {};
      const customerProfile = intervention.customer;
      const customerName = customerProfile ? 
        `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim() :
        'Client non renseigné';
      const customerCompany = customerProfile?.company_name || '';

      let partsNeeded = [];
      if (diag.parts_needed) {
        try {
          partsNeeded = typeof diag.parts_needed === 'string' ? JSON.parse(diag.parts_needed) : diag.parts_needed;
        } catch (e) {
          partsNeeded = [];
        }
      }

      let photosList = [];
      if (diag.photos) {
        try {
          photosList = typeof diag.photos === 'string' ? JSON.parse(diag.photos) : diag.photos;
        } catch (e) {
          photosList = [];
        }
      }

      let equipmentsList = [];
      if (diag.equipments) {
        try {
          equipmentsList = typeof diag.equipments === 'string' ? JSON.parse(diag.equipments) : diag.equipments;
        } catch (e) {
          equipmentsList = [];
        }
      }

      const reportDate = diag.createdAt || diag.submitted_at || new Date();

      return {
        id: intervention.id || diag.intervention_id || diag.id,
        diagnostic_report_id: diag.id,
        report_type: 'diagnostic',
        intervention_title: intervention.title || 'Diagnostic Technique',
        title: intervention.title ? `Diagnostic - ${intervention.title}` : `Rapport Diagnostic #${diag.id}`,
        address: intervention.address || 'Non spécifiée',
        customer_name: customerName || 'Client non renseigné',
        customer_phone: '',
        customer_email: '',
        customer_company: customerCompany,
        created_at: reportDate,
        date: reportDate,
        status: diag.status || 'submitted',
        work_description: diag.problem_description || '',
        observations: diag.recommended_solution || diag.notes || '',
        duration: diag.estimated_duration || '1h',
        materials_used: partsNeeded,
        photos_count: Array.isArray(photosList) ? photosList.length : 0,
        total_cost: diag.estimated_total || 0,
        pression: diag.pression || '',
        freon: diag.freon || '',
        puissance: diag.puissance || '',
        intensite: diag.intensite || '',
        tension: diag.tension || '',
        equipments: Array.isArray(equipmentsList) ? equipmentsList : [],
        spare_parts: partsNeeded,
      };
    });

    // Combiner et trier par date décroissante
    let allReports = [...formattedMaintenanceReports, ...formattedDiagnosticReports];
    allReports.sort((a, b) => new Date(b.date) - new Date(a.date));

    // Filtrer par statut si spécifié
    if (status && status !== 'all') {
      allReports = allReports.filter(r => r.status === status);
    }

    console.log(`✅ ${allReports.length} rapport(s) trouvé(s) (${formattedMaintenanceReports.length} maintenance, ${formattedDiagnosticReports.length} diagnostic)`);

    res.json({
      success: true,
      data: allReports,
    });
  } catch (error) {
    console.error('❌ Erreur récupération rapports technicien:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des rapports',
      error: error.message,
      detail: error.original ? error.original.message : null
    });
  }
});

// Download report PDF
router.get('/reports/:interventionId/download', async (req, res, next) => {
  try {
    const technicianId = req.user.id;
    const interventionId = req.params.interventionId;

    console.log(`📥 Téléchargement PDF rapport intervention ${interventionId} par technicien ${technicianId}`);

    // Récupérer l'intervention
    const intervention = await Intervention.findOne({
      where: {
        id: interventionId,
        technician_id: technicianId
      },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone', 'first_name', 'last_name']
          }]
        }
      ]
    });

    let diagReport = null;
    if (intervention) {
      diagReport = await DiagnosticReport.findOne({
        where: { intervention_id: intervention.id, technician_id: technicianId }
      });
    }

    if (!intervention || (!intervention.report_submitted_at && !diagReport)) {
      return res.status(404).json({
        success: false,
        message: 'Rapport non trouvé'
      });
    }

    let reportData = {};
    if (diagReport) {
      let partsNeeded = [];
      try { partsNeeded = typeof diagReport.parts_needed === 'string' ? JSON.parse(diagReport.parts_needed) : diagReport.parts_needed || []; } catch(e) {}
      reportData = {
        work_description: diagReport.problem_description,
        observations: diagReport.recommended_solution,
        pression: diagReport.pression,
        freon: diagReport.freon,
        puissance: diagReport.puissance,
        intensite: diagReport.intensite,
        tension: diagReport.tension,
        spare_parts: partsNeeded,
        duration: diagReport.estimated_duration || '1h'
      };
    } else {
      reportData = intervention.report_data ? 
        (typeof intervention.report_data === 'string' ? 
          JSON.parse(intervention.report_data) : intervention.report_data) 
        : {};
    }

    // Fonction pour échapper le HTML
    const escapeHtml = (text) => {
      if (!text) return '';
      return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    };

    // Enrichir customer
    const customerProfile = intervention.customer;
    const customerUser = customerProfile?.user;
    const customerName = customerProfile ? 
      (customerProfile.first_name && customerProfile.last_name ? 
        `${customerProfile.first_name} ${customerProfile.last_name}` :
        (customerUser ? `${customerUser.first_name || ''} ${customerUser.last_name || ''}`.trim() || customerUser.email : 'Client')
      ) : 'Client inconnu';
    const customerPhone = customerUser?.phone || 'Non renseigné';

    // Générer HTML du rapport
    const html = ` // nosemgrep: raw-html-format
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 40px;
      color: #333;
    }
    .header {
      text-align: center;
      border-bottom: 3px solid #0a543d;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    h1 { color: #0a543d; margin-bottom: 10px; }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 30px;
    }
    .info-section {
      background: #f5f5f5;
      padding: 15px;
      border-radius: 8px;
    }
    .info-section h3 {
      color: #0a543d;
      margin-top: 0;
      margin-bottom: 10px;
      font-size: 16px;
    }
    .info-row {
      margin-bottom: 8px;
    }
    .label {
      font-weight: bold;
      color: #555;
    }
    .section {
      margin-bottom: 25px;
    }
    .section h2 {
      color: #0a543d;
      border-bottom: 2px solid #0a543d;
      padding-bottom: 8px;
      margin-bottom: 15px;
    }
    .description-box {
      background: #f9f9f9;
      padding: 15px;
      border-left: 4px solid #0a543d;
      border-radius: 4px;
      margin-bottom: 15px;
    }
    .footer {
      text-align: center;
      margin-top: 50px;
      padding-top: 20px;
      border-top: 1px solid #ddd;
      color: #888;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>RAPPORT D'INTERVENTION</h1>
    <p style="font-size: 18px; color: #666;">MCT Maintenance</p>
  </div>

  <div class="info-grid">
    <div class="info-section">
      <h3>📋 Informations Intervention</h3>
      <div class="info-row"><span class="label">Référence:</span> #${Number(intervention.id) /* nosemgrep: raw-html-format */}</div>
      <div class="info-row"><span class="label">Titre:</span> ${escapeHtml(intervention.title) /* nosemgrep: raw-html-format */}</div>
      <div class="info-row"><span class="label">Adresse:</span> ${(escapeHtml(intervention.address) || 'Non spécifiée') /* nosemgrep: raw-html-format */}</div>
      <div class="info-row"><span class="label">Date:</span> ${new Date(intervention.report_submitted_at).toLocaleDateString('fr-FR') /* nosemgrep: raw-html-format */}</div>
      <div class="info-row"><span class="label">Durée:</span> ${(Number(reportData.duration) || 0) /* nosemgrep: raw-html-format */} minutes</div>
    </div>

    <div class="info-section">
      <h3>👤 Informations Client</h3>
      <div class="info-row"><span class="label">Nom:</span> ${escapeHtml(customerName) /* nosemgrep: raw-html-format */}</div>
      <div class="info-row"><span class="label">Email:</span> ${(escapeHtml(customer?.email) || 'Non renseigné') /* nosemgrep: raw-html-format */}</div>
      <div class="info-row"><span class="label">Téléphone:</span> ${escapeHtml(customerPhone) /* nosemgrep: raw-html-format */}</div>
    </div>
  </div>

  <div class="section">
    <h2>🔧 Travail Effectué</h2>
    <div class="description-box">
      ${escapeHtml(reportData.work_description) || 'Aucune description'}
    </div>
  </div>

  ${reportData.observations ? `
  <div class="section">
    <h2>📝 Observations</h2>
    <div class="description-box">
      ${escapeHtml(reportData.observations)}
    </div>
  </div>
  ` : ''}

  ${reportData.materials_used && Array.isArray(reportData.materials_used) && reportData.materials_used.length > 0 ? `
  <div class="section">
    <h2>🛠️ Matériel Utilisé</h2>
    <ul>
      ${reportData.materials_used.map(m => `<li>${(escapeHtml(m) || 'Item') /* nosemgrep: raw-html-format */}</li>`).join('')}
    </ul>
  </div>
  ` : ''}

  ${reportData.photos_count > 0 ? `
  <div class="section">
    <h2>📸 Photos Jointes</h2>
    <p>${Number(reportData.photos_count) /* nosemgrep: raw-html-format */} photo(s) disponible(s)</p>
  </div>
  ` : ''}

  <div class="footer">
    <p>MCT Maintenance - Service de maintenance professionnel</p>
    <p>Rapport généré le ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR')}</p>
  </div>
</body>
</html>
    `;

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="rapport-${intervention.id}.html"`);
    res.send(html);

    console.log(`✅ PDF rapport ${interventionId} téléchargé`);
  } catch (error) {
    console.error('❌ Erreur téléchargement PDF:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération du rapport',
      error: error.message
    });
  }
});

// Route pour récupérer les évaluations du technicien
router.get('/reviews', async (req, res) => {
  try {
    const technicianId = req.user.id;
    
    console.log('📊 Récupération des évaluations pour le technicien:', technicianId);
    console.log('📊 User complet:', JSON.stringify(req.user));

    // Récupérer toutes les interventions terminées avec évaluation
    const interventions = await Intervention.findAll({
      where: {
        technician_id: technicianId,
        status: 'completed',
        rating: { [Op.not]: null }
      },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['first_name', 'last_name']
        }
      ],
      order: [['completed_at', 'DESC']]
    });

    // Calculer les statistiques
    const totalReviews = interventions.length;
    let sumRatings = 0;
    const ratingsBreakdown = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };

    const reviews = interventions.map(intervention => {
      const rating = intervention.rating;
      sumRatings += rating;
      ratingsBreakdown[rating]++;

      const customerName = intervention.customer
        ? `${intervention.customer.first_name || ''} ${intervention.customer.last_name || ''}`.trim()
        : 'Client';

      return {
        id: intervention.id,
        rating: rating,
        review: intervention.review || '',
        comment: intervention.review || '',
        customer_name: customerName || 'Client',
        intervention_title: intervention.title,
        date: intervention.completed_at ? intervention.completed_at.toISOString().split('T')[0] : (intervention.updated_at ? intervention.updated_at.toISOString().split('T')[0] : ''),
        created_at: intervention.updated_at
      };
    });

    const averageRating = totalReviews > 0 ? (sumRatings / totalReviews) : 0;

    console.log('✅ Statistiques:', {
      total: totalReviews,
      average: averageRating.toFixed(2),
      breakdown: ratingsBreakdown
    });
    
    console.log('📊 Nombre d\'interventions trouvées:', interventions.length);

    res.json({
      success: true,
      message: 'Évaluations récupérées avec succès',
      data: {
        total_reviews: totalReviews,
        average_rating: parseFloat(averageRating.toFixed(2)),
        ratings_breakdown: ratingsBreakdown,
        reviews: reviews
      }
    });
  } catch (error) {
    console.error('❌ Erreur récupération évaluations:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des évaluations',
      error: error.message
    });
  }
});

module.exports = router;
