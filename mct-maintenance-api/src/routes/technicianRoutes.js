const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { Intervention, User, CustomerProfile } = require('../models');
const { Op } = require('sequelize');
const technicianController = require('../controllers/technician/technicianController');

const router = express.Router();

console.log('🔧 TechnicianRoutes chargé - VERSION AVEC LOGS DEBUG');

// All technician routes require authentication and technician role
router.use(authenticate);
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

// Technician location routes
router.put('/location', (req, res) => {
  res.json({
    success: true,
    message: 'Location updated successfully'
  });
});

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
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
          required: false
        }
      ],
      order: [['scheduled_date', 'DESC']]
    });
    
    console.log(`✅ ${interventions.length} intervention(s) trouvée(s)`);
    
    // Formater les interventions pour l'app mobile
    const formattedInterventions = interventions.map(intervention => {
      const customer = intervention.customer;
      
      // Essayer de récupérer le nom depuis customer ou construire depuis email
      let customerName = 'Client inconnu';
      if (customer) {
        if (customer.first_name && customer.last_name) {
          customerName = `${customer.first_name} ${customer.last_name}`;
        } else {
          customerName = customer.email || 'Client inconnu';
        }
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
        customer_phone: customer?.phone || '',
        report_data: intervention.report_data || null,
        report_submitted_at: intervention.report_submitted_at || null
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
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
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
      if (customer) {
        if (customer.first_name && customer.last_name) {
          customerName = `${customer.first_name} ${customer.last_name}`;
        } else {
          customerName = customer.email || 'Client inconnu';
        }
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

// Get technician's submitted reports
router.get('/reports', async (req, res, next) => {
  try {
    const technicianId = req.user.id;
    const status = req.query.status; // draft, submitted, approved
    
    console.log(`📋 Technicien ${technicianId}: Récupération des rapports`);

    // Construire le where
    const where = {
      technician_id: technicianId,
      report_submitted_at: { [Op.not]: null } // Seulement avec rapport
    };

    // Filtre par statut si spécifié
    if (status && status !== 'all') {
      // Le statut est dans report_data JSON, on devra filtrer après
    }

    // Récupérer les interventions avec rapport
    const interventions = await Intervention.findAll({
      where,
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name'],
          include: [{
            model: CustomerProfile,
            as: 'customerProfile',
            attributes: ['first_name', 'last_name']
          }]
        }
      ],
      order: [['report_submitted_at', 'DESC']],
    });

    // Formater les données pour le mobile
    const reports = interventions.map(intervention => {
      const reportData = intervention.report_data ? 
        (typeof intervention.report_data === 'string' ? 
          JSON.parse(intervention.report_data) : intervention.report_data) 
        : {};

      // Enrichir le customer
      const customer = intervention.customer;
      const customerName = customer ? 
        (customer.customerProfile ? 
          `${customer.customerProfile.first_name} ${customer.customerProfile.last_name}` :
          `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || customer.email
        ) : 'Client inconnu';

      return {
        id: intervention.id,
        intervention_title: intervention.title,
        customer_name: customerName,
        address: intervention.address || 'Non spécifiée',
        created_at: intervention.report_submitted_at,
        date: intervention.report_submitted_at,
        status: reportData.status || 'submitted',
        work_description: reportData.work_description || '',
        duration: reportData.duration || 0,
        materials_used: reportData.materials_used || [],
        observations: reportData.observations || '',
        photos_count: reportData.photos_count || 0,
        total_cost: 0, // À calculer si besoin
      };
    });

    // Filtrer par statut si spécifié
    let filteredReports = reports;
    if (status && status !== 'all') {
      filteredReports = reports.filter(r => r.status === status);
    }

    console.log(`✅ ${filteredReports.length} rapport(s) trouvé(s)`);

    res.json({
      success: true,
      data: filteredReports,
    });
  } catch (error) {
    console.error('❌ Erreur récupération rapports technicien:', error);
    next(error);
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
        technician_id: technicianId,
        report_submitted_at: { [Op.not]: null }
      },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
          include: [{
            model: CustomerProfile,
            as: 'customerProfile',
            attributes: ['first_name', 'last_name']
          }]
        }
      ]
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Rapport non trouvé'
      });
    }

    const reportData = intervention.report_data ? 
      (typeof intervention.report_data === 'string' ? 
        JSON.parse(intervention.report_data) : intervention.report_data) 
      : {};

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
    const customer = intervention.customer;
    const customerName = customer ? 
      (customer.customerProfile ? 
        `${customer.customerProfile.first_name} ${customer.customerProfile.last_name}` :
        `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || customer.email
      ) : 'Client inconnu';
    const customerPhone = customer?.phone || 'Non renseigné';

    // Générer HTML du rapport
    const html = `
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
      <div class="info-row"><span class="label">Référence:</span> #${intervention.id}</div>
      <div class="info-row"><span class="label">Titre:</span> ${escapeHtml(intervention.title)}</div>
      <div class="info-row"><span class="label">Adresse:</span> ${escapeHtml(intervention.address) || 'Non spécifiée'}</div>
      <div class="info-row"><span class="label">Date:</span> ${new Date(intervention.report_submitted_at).toLocaleDateString('fr-FR')}</div>
      <div class="info-row"><span class="label">Durée:</span> ${reportData.duration || 0} minutes</div>
    </div>

    <div class="info-section">
      <h3>👤 Informations Client</h3>
      <div class="info-row"><span class="label">Nom:</span> ${escapeHtml(customerName)}</div>
      <div class="info-row"><span class="label">Email:</span> ${escapeHtml(customer?.email) || 'Non renseigné'}</div>
      <div class="info-row"><span class="label">Téléphone:</span> ${escapeHtml(customerPhone)}</div>
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
      ${reportData.materials_used.map(m => `<li>${escapeHtml(m) || 'Item'}</li>`).join('')}
    </ul>
  </div>
  ` : ''}

  ${reportData.photos_count > 0 ? `
  <div class="section">
    <h2>📸 Photos Jointes</h2>
    <p>${reportData.photos_count} photo(s) disponible(s)</p>
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
          model: User,
          as: 'customer',
          attributes: ['id', 'email'],
          include: [
            {
              model: CustomerProfile,
              as: 'customerProfile',
              attributes: ['first_name', 'last_name']
            }
          ]
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

      const customerName = intervention.customer?.customerProfile
        ? `${intervention.customer.customerProfile.first_name} ${intervention.customer.customerProfile.last_name}`
        : intervention.customer?.email || 'Client';

      return {
        id: intervention.id,
        customer_name: customerName,
        rating: rating,
        review: intervention.review,
        intervention_title: intervention.title,
        date: intervention.completed_at,
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
