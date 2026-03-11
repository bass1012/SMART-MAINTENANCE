const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const analyticsController = require('../controllers/admin/analyticsController');

const router = express.Router();
const { Op } = require('sequelize');
const { User, CustomerProfile, TechnicianProfile, Intervention, Order, Subscription, MaintenanceOffer, InstallationService, RepairService, Complaint, SystemConfig, sequelize } = require('../models');

// All admin routes require authentication and admin/manager role
router.use(authenticate);
router.use(authorize('admin', 'manager'));

// Admin dashboard routes
router.get('/dashboard', (req, res) => {
  res.json({
    success: true,
    message: 'Admin dashboard data',
    data: {
      // Dashboard statistics will be implemented later
      totalUsers: 0,
      totalTechnicians: 0,
      totalCustomers: 0,
      totalOrders: 0,
      totalInterventions: 0,
      totalRevenue: 0
    }
  });
});

// ==================== DASHBOARD AMÉLIORÉ ====================

/**
 * GET /api/admin/dashboard/payment-stats
 * Statistiques des paiements (revenus aujourd'hui/semaine/mois, paiements en attente)
 */
router.get('/dashboard/payment-stats', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);
    
    const monthAgo = new Date(today);
    monthAgo.setMonth(monthAgo.getMonth() - 1);

    // Revenus aujourd'hui (commandes payées)
    const revenueToday = await Order.sum('total_amount', {
      where: {
        payment_status: 'paid',
        updated_at: { [Op.gte]: today }
      }
    }) || 0;

    // Revenus cette semaine
    const revenueWeek = await Order.sum('total_amount', {
      where: {
        payment_status: 'paid',
        updated_at: { [Op.gte]: weekAgo }
      }
    }) || 0;

    // Revenus ce mois
    const revenueMonth = await Order.sum('total_amount', {
      where: {
        payment_status: 'paid',
        updated_at: { [Op.gte]: monthAgo }
      }
    }) || 0;

    // Paiements en attente (commandes)
    const pendingOrdersCount = await Order.count({
      where: { payment_status: 'pending' }
    });
    const pendingOrdersAmount = await Order.sum('total_amount', {
      where: { payment_status: 'pending' }
    }) || 0;

    // Diagnostics non payés
    const unpaidDiagnosticsCount = await Intervention.count({
      where: {
        diagnostic_fee: { [Op.gt]: 0 },
        diagnostic_paid: false,
        status: { [Op.notIn]: ['cancelled', 'completed'] }
      }
    });
    const unpaidDiagnosticsAmount = await Intervention.sum('diagnostic_fee', {
      where: {
        diagnostic_fee: { [Op.gt]: 0 },
        diagnostic_paid: false,
        status: { [Op.notIn]: ['cancelled', 'completed'] }
      }
    }) || 0;

    // Abonnements en attente de paiement
    const pendingSubscriptionsCount = await Subscription.count({
      where: { payment_status: 'pending', status: 'active' }
    });
    const pendingSubscriptionsAmount = await Subscription.sum('price', {
      where: { payment_status: 'pending', status: 'active' }
    }) || 0;

    res.json({
      success: true,
      data: {
        revenue: {
          today: revenueToday,
          week: revenueWeek,
          month: revenueMonth
        },
        pending: {
          orders: {
            count: pendingOrdersCount,
            amount: pendingOrdersAmount
          },
          diagnostics: {
            count: unpaidDiagnosticsCount,
            amount: unpaidDiagnosticsAmount
          },
          subscriptions: {
            count: pendingSubscriptionsCount,
            amount: pendingSubscriptionsAmount
          },
          total: {
            count: pendingOrdersCount + unpaidDiagnosticsCount + pendingSubscriptionsCount,
            amount: pendingOrdersAmount + unpaidDiagnosticsAmount + pendingSubscriptionsAmount
          }
        }
      }
    });
  } catch (error) {
    console.error('❌ Erreur récupération stats paiements:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques de paiement',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/dashboard/unpaid-diagnostics
 * Liste des interventions avec diagnostic non payé
 */
router.get('/dashboard/unpaid-diagnostics', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    
    const unpaidDiagnostics = await Intervention.findAll({
      where: {
        diagnostic_fee: { [Op.gt]: 0 },
        diagnostic_paid: false,
        status: { [Op.notIn]: ['cancelled'] }
      },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone']
          }]
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name', 'email']
        }
      ],
      order: [['scheduled_date', 'ASC']],
      limit
    });

    const formattedData = unpaidDiagnostics.map(intervention => ({
      id: intervention.id,
      title: intervention.title,
      type: intervention.type,
      status: intervention.status,
      diagnostic_fee: intervention.diagnostic_fee,
      scheduled_date: intervention.scheduled_date,
      address: intervention.address,
      customer: intervention.customer ? {
        id: intervention.customer.id,
        name: `${intervention.customer.first_name || ''} ${intervention.customer.last_name || ''}`.trim(),
        email: intervention.customer.user?.email,
        phone: intervention.customer.user?.phone
      } : null,
      technician: intervention.technician ? {
        id: intervention.technician.id,
        name: `${intervention.technician.first_name || ''} ${intervention.technician.last_name || ''}`.trim()
      } : null
    }));

    res.json({
      success: true,
      data: formattedData,
      total: unpaidDiagnostics.length
    });
  } catch (error) {
    console.error('❌ Erreur récupération diagnostics non payés:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des diagnostics non payés',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/dashboard/expiring-subscriptions
 * Abonnements qui expirent dans les 7 prochains jours
 */
router.get('/dashboard/expiring-subscriptions', async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 7;
    const limit = parseInt(req.query.limit) || 10;
    
    const today = new Date();
    const futureDate = new Date(today);
    futureDate.setDate(futureDate.getDate() + days);

    const expiringSubscriptions = await Subscription.findAll({
      where: {
        status: 'active',
        end_date: {
          [Op.between]: [today, futureDate]
        }
      },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        },
        {
          model: MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'price']
        },
        {
          model: InstallationService,
          as: 'installationService',
          attributes: ['id', 'title', 'price']
        },
        {
          model: RepairService,
          as: 'repairService',
          attributes: ['id', 'title', 'price']
        }
      ],
      order: [['end_date', 'ASC']],
      limit
    });

    const formattedData = expiringSubscriptions.map(sub => {
      // Déterminer l'offre associée
      let offerName = 'N/A';
      let offerPrice = sub.price;
      
      if (sub.offer) {
        offerName = sub.offer.title;
        offerPrice = sub.offer.price;
      } else if (sub.installationService) {
        offerName = sub.installationService.title;
        offerPrice = sub.installationService.price;
      } else if (sub.repairService) {
        offerName = sub.repairService.title;
        offerPrice = sub.repairService.price;
      }

      // Calculer les jours restants
      const daysRemaining = Math.ceil((new Date(sub.end_date) - today) / (1000 * 60 * 60 * 24));

      return {
        id: sub.id,
        customer: sub.customer ? {
          id: sub.customer.id,
          name: `${sub.customer.first_name || ''} ${sub.customer.last_name || ''}`.trim(),
          email: sub.customer.email,
          phone: sub.customer.phone
        } : null,
        offer_name: offerName,
        price: offerPrice,
        start_date: sub.start_date,
        end_date: sub.end_date,
        days_remaining: daysRemaining,
        payment_status: sub.payment_status
      };
    });

    res.json({
      success: true,
      data: formattedData,
      total: expiringSubscriptions.length
    });
  } catch (error) {
    console.error('❌ Erreur récupération abonnements expirants:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des abonnements expirants',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/dashboard/quick-stats
 * Statistiques rapides pour les widgets du dashboard
 */
router.get('/dashboard/quick-stats', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Interventions du jour
    const interventionsToday = await Intervention.count({
      where: {
        scheduled_date: {
          [Op.gte]: today,
          [Op.lt]: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      }
    });

    // Interventions en attente d'assignation
    const pendingAssignment = await Intervention.count({
      where: {
        status: 'pending',
        technician_id: null
      }
    });

    // Interventions en cours
    const inProgressInterventions = await Intervention.count({
      where: {
        status: { [Op.in]: ['on_the_way', 'arrived', 'in_progress'] }
      }
    });

    // Réclamations ouvertes
    const openComplaints = await Complaint.count({
      where: { status: 'open' }
    });

    // Commandes en attente de traitement
    const pendingOrders = await Order.count({
      where: { status: 'pending' }
    });

    // Nouveaux clients ce mois
    const monthAgo = new Date(today);
    monthAgo.setMonth(monthAgo.getMonth() - 1);
    const newCustomers = await CustomerProfile.count({
      where: {
        created_at: { [Op.gte]: monthAgo }
      }
    });

    res.json({
      success: true,
      data: {
        interventions: {
          today: interventionsToday,
          pendingAssignment: pendingAssignment,
          inProgress: inProgressInterventions
        },
        openComplaints,
        pendingOrders,
        newCustomers
      }
    });
  } catch (error) {
    console.error('❌ Erreur récupération quick stats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques rapides',
      error: error.message
    });
  }
});

// Analytics & Reporting routes
router.get('/analytics/stats', analyticsController.getGlobalStats);
router.get('/analytics/technicians', analyticsController.getTechnicianPerformance);
router.get('/analytics/export/excel', analyticsController.exportToExcel);
router.get('/analytics/export/pdf', analyticsController.exportToPDF);
router.get('/analytics/charts/:chartType', analyticsController.getChartData);

// User management routes

// Liste paginée des clients (admin)
router.get('/customers', async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const search = (req.query.search || '').toString().trim();
    const offset = (page - 1) * limit;

    const userWhere = { role: 'customer' };
    if (search) {
      userWhere[Op.or] = [
        { email: { [Op.like]: `%${search}%` } },
        { phone: { [Op.like]: `%${search}%` } },
      ];
    }

    const { rows, count } = await User.findAndCountAll({
      where: userWhere,
      include: [
        {
          model: CustomerProfile,
          as: 'customerProfile',
          required: false,
          attributes: [
            'first_name',
            'last_name',
            'address',
            'city',
            'postal_code',
            'country',
            'company_name'
          ]
        }
      ],
      limit,
      offset,
      order: [['createdAt', 'DESC']],
      attributes: ['id', 'email', 'phone', 'status', 'createdAt', 'updatedAt']
    });

    const customers = rows.map(u => ({
      id: u.id,
      first_name: u.customerProfile?.first_name || '',
      last_name: u.customerProfile?.last_name || '',
      email: u.email,
      phone: u.phone || null,
      company: u.customerProfile?.company_name || null,
      address: u.customerProfile?.address || null,
      city: u.customerProfile?.city || null,
      postal_code: u.customerProfile?.postal_code || null,
      country: u.customerProfile?.country || null,
      created_at: u.createdAt,
      updated_at: u.updatedAt,
    }));

    res.json({
      success: true,
      data: {
        customers,
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des clients:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Technicians management routes
router.get('/technicians', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { first_name: { [Op.iLike]: `%${search}%` } },
        { last_name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } }
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where: {
        role: 'technician',
        ...whereClause
      },
      include: [{
        model: TechnicianProfile,
        as: 'technicianProfile',
        required: false
      }],
      limit,
      offset,
      order: [['createdAt', 'DESC']]
    });

    const technicians = rows.map(u => ({
      id: u.id,
      first_name: u.first_name,
      last_name: u.last_name,
      email: u.email,
      phone: u.phone,
      is_active: u.is_active,
  specialization: u.technicianProfile?.specialization || null,
  experience_years: u.technicianProfile?.experience_years || null,
  certification: u.technicianProfile?.certification || null,
  hourly_rate: u.technicianProfile?.hourly_rate || null,
  availability_status: u.technicianProfile?.availability_status || 'available',
      created_at: u.createdAt,
      updated_at: u.updatedAt,
    }));

    res.json({
      success: true,
      data: {
        technicians,
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des techniciens:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/users', (req, res) => {
  res.json({
    success: true,
    message: 'Users list',
    data: []
  });
});

router.get('/users/:id', (req, res) => {
  res.json({
    success: true,
    message: 'User details',
    data: {}
  });
});

router.put('/users/:id', (req, res) => {
  res.json({
    success: true,
    message: 'User updated successfully'
  });
});

router.delete('/users/:id', (req, res) => {
  res.json({
    success: true,
    message: 'User deleted successfully'
  });
});

// ==================== SYSTEM CONFIGURATION ====================

/**
 * GET /api/admin/settings
 * Récupérer tous les paramètres système
 */
router.get('/settings', async (req, res) => {
  try {
    const { category } = req.query;
    
    let configs;
    if (category) {
      configs = await SystemConfig.findAll({
        where: { category },
        order: [['key', 'ASC']]
      });
    } else {
      configs = await SystemConfig.findAll({
        order: [['category', 'ASC'], ['key', 'ASC']]
      });
    }

    // Transformer en format clé-valeur groupé par catégorie
    const result = {};
    for (const config of configs) {
      if (!result[config.category]) {
        result[config.category] = {};
      }
      
      let value = config.value;
      try {
        if (config.type === 'json' || config.type === 'array') {
          value = JSON.parse(config.value);
        } else if (config.type === 'number') {
          value = parseFloat(config.value);
        } else if (config.type === 'boolean') {
          value = config.value === 'true' || config.value === '1';
        }
      } catch {}
      
      result[config.category][config.key] = {
        value,
        type: config.type,
        description: config.description
      };
    }

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('❌ Erreur récupération paramètres:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des paramètres',
      error: error.message
    });
  }
});

/**
 * PUT /api/admin/settings
 * Mettre à jour plusieurs paramètres
 */
router.put('/settings', async (req, res) => {
  try {
    const { settings } = req.body;
    
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Paramètres invalides'
      });
    }

    const updated = [];
    const errors = [];

    for (const [key, config] of Object.entries(settings)) {
      try {
        const { value, type = 'string', category = 'general', description = null, is_public = false } = config;
        
        await SystemConfig.setValue(key, value, { type, category, description, is_public });
        updated.push(key);
      } catch (err) {
        errors.push({ key, error: err.message });
      }
    }

    res.json({
      success: true,
      message: `${updated.length} paramètre(s) mis à jour`,
      data: { updated, errors }
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour paramètres:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour des paramètres',
      error: error.message
    });
  }
});

/**
 * PUT /api/admin/settings/diagnostic
 * Mettre à jour la configuration des frais de diagnostic
 */
router.put('/settings/diagnostic', async (req, res) => {
  try {
    const { default_fee, fees_by_location } = req.body;

    if (typeof default_fee !== 'undefined') {
      await SystemConfig.setValue('diagnostic_default_fee', default_fee, {
        type: 'number',
        category: 'diagnostic',
        description: 'Frais de diagnostic par défaut (FCFA)'
      });
    }

    if (fees_by_location) {
      await SystemConfig.setValue('diagnostic_fees_by_location', fees_by_location, {
        type: 'json',
        category: 'diagnostic',
        description: 'Frais de diagnostic par ville/zone'
      });
    }

    res.json({
      success: true,
      message: 'Configuration des frais de diagnostic mise à jour'
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour config diagnostic:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/settings/diagnostic
 * Récupérer la configuration des frais de diagnostic
 */
router.get('/settings/diagnostic', async (req, res) => {
  try {
    const defaultFee = await SystemConfig.getValue('diagnostic_default_fee', 4000);
    const feesByLocation = await SystemConfig.getValue('diagnostic_fees_by_location', {});

    res.json({
      success: true,
      data: {
        default_fee: defaultFee,
        fees_by_location: feesByLocation
      }
    });
  } catch (error) {
    console.error('❌ Erreur récupération config diagnostic:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération',
      error: error.message
    });
  }
});

/**
 * PUT /api/admin/settings/email-templates
 * Mettre à jour les templates d'email
 */
router.put('/settings/email-templates', async (req, res) => {
  try {
    const { templates } = req.body;

    if (!templates || typeof templates !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Templates invalides'
      });
    }

    for (const [templateName, templateContent] of Object.entries(templates)) {
      await SystemConfig.setValue(`email_template_${templateName}`, templateContent, {
        type: 'json',
        category: 'email',
        description: `Template email: ${templateName}`
      });
    }

    res.json({
      success: true,
      message: 'Templates email mis à jour'
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour templates email:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/settings/email-templates
 * Récupérer les templates d'email
 */
router.get('/settings/email-templates', async (req, res) => {
  try {
    const configs = await SystemConfig.findAll({
      where: {
        category: 'email',
        key: { [Op.like]: 'email_template_%' }
      }
    });

    const templates = {};
    for (const config of configs) {
      const templateName = config.key.replace('email_template_', '');
      try {
        templates[templateName] = JSON.parse(config.value);
      } catch {
        templates[templateName] = config.value;
      }
    }

    // Templates par défaut si vides
    const defaultTemplates = {
      intervention_created: {
        subject: 'Nouvelle demande d\'intervention - MCT Maintenance',
        body: 'Bonjour {{customer_name}},\n\nVotre demande d\'intervention a été enregistrée.\n\nDétails:\n- Titre: {{intervention_title}}\n- Date prévue: {{scheduled_date}}\n\nCordialement,\nL\'équipe MCT Maintenance'
      },
      intervention_assigned: {
        subject: 'Technicien assigné à votre intervention - MCT Maintenance',
        body: 'Bonjour {{customer_name}},\n\nUn technicien a été assigné à votre intervention.\n\nTechnicien: {{technician_name}}\nDate: {{scheduled_date}}\n\nCordialement,\nL\'équipe MCT Maintenance'
      },
      payment_received: {
        subject: 'Confirmation de paiement - MCT Maintenance',
        body: 'Bonjour {{customer_name}},\n\nNous avons bien reçu votre paiement de {{amount}} FCFA.\n\nMerci de votre confiance.\n\nCordialement,\nL\'équipe MCT Maintenance'
      },
      subscription_expiring: {
        subject: 'Votre abonnement expire bientôt - MCT Maintenance',
        body: 'Bonjour {{customer_name}},\n\nVotre abonnement {{offer_name}} expire dans {{days_remaining}} jour(s).\n\nRenouvelez-le dès maintenant pour continuer à bénéficier de nos services.\n\nCordialement,\nL\'équipe MCT Maintenance'
      }
    };

    res.json({
      success: true,
      data: { ...defaultTemplates, ...templates }
    });
  } catch (error) {
    console.error('❌ Erreur récupération templates email:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération',
      error: error.message
    });
  }
});

/**
 * PUT /api/admin/settings/locations
 * Gérer les zones/villes de service
 */
router.put('/settings/locations', async (req, res) => {
  try {
    const { locations } = req.body;

    if (!Array.isArray(locations)) {
      return res.status(400).json({
        success: false,
        message: 'Liste de locations invalide'
      });
    }

    await SystemConfig.setValue('service_locations', locations, {
      type: 'array',
      category: 'location',
      description: 'Zones de service disponibles'
    });

    res.json({
      success: true,
      message: 'Zones de service mises à jour'
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour locations:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/settings/locations
 * Récupérer les zones/villes de service
 */
router.get('/settings/locations', async (req, res) => {
  try {
    const locations = await SystemConfig.getValue('service_locations', [
      { name: 'Dakar', code: 'DKR', active: true },
      { name: 'Thiès', code: 'THS', active: true },
      { name: 'Saint-Louis', code: 'SLO', active: true },
      { name: 'Mbour', code: 'MBR', active: true },
      { name: 'Ziguinchor', code: 'ZIG', active: true }
    ]);

    res.json({
      success: true,
      data: locations
    });
  } catch (error) {
    console.error('❌ Erreur récupération locations:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération',
      error: error.message
    });
  }
});

/**
 * GET /api/admin/settings/:category
 * Récupérer les paramètres d'une catégorie spécifique
 * NOTE: This route MUST be after all specific /settings/* routes
 */
router.get('/settings/:category', async (req, res) => {
  try {
    const { category } = req.params;
    
    const configs = await SystemConfig.findAll({
      where: { category },
      order: [['key', 'ASC']]
    });

    const result = {};
    for (const config of configs) {
      let value = config.value;
      try {
        if (config.type === 'json' || config.type === 'array') {
          value = JSON.parse(config.value);
        } else if (config.type === 'number') {
          value = parseFloat(config.value);
        } else if (config.type === 'boolean') {
          value = config.value === 'true' || config.value === '1';
        }
      } catch {}
      
      result[config.key] = value;
    }

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('❌ Erreur récupération paramètres catégorie:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des paramètres',
      error: error.message
    });
  }
});

// Audit logs routes
router.get('/audit-logs', (req, res) => {
  res.json({
    success: true,
    message: 'Audit logs',
    data: []
  });
});

// Get all intervention reports (admin)
router.get('/reports', async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status; // 'all', 'submitted', 'approved', etc.
    const offset = (page - 1) * limit;

    console.log(`📋 Admin: Récupération des rapports (page ${page}, limit ${limit})`);

    // Construire le where
    const where = {
      report_submitted_at: { [Op.not]: null } // Seulement les interventions avec rapport
    };

    if (status && status !== 'all') {
      where.status = status;
    }

    // Récupérer les interventions avec rapport
    const { rows: interventions, count } = await Intervention.findAndCountAll({
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
              attributes: ['id', 'email', 'phone'],
            }
          ]
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
        },
      ],
      order: [['report_submitted_at', 'DESC']], // Plus récents en premier
      limit,
      offset,
    });

    // Formater les données
    const reports = interventions.map(intervention => {
      const reportData = intervention.report_data ? 
        (typeof intervention.report_data === 'string' ? 
          JSON.parse(intervention.report_data) : intervention.report_data) 
        : {};

      return {
        id: intervention.id,
        intervention_title: intervention.title,
        intervention_description: intervention.description,
        intervention_address: intervention.address,
        intervention_status: intervention.status,
        scheduled_date: intervention.scheduled_date,
        completed_date: intervention.completed_date,
        customer: intervention.customer ? {
          id: intervention.customer.id,
          name: `${intervention.customer.first_name} ${intervention.customer.last_name}`,
          email: intervention.customer.user?.email || '',
          phone: intervention.customer.user?.phone || '',
        } : null,
        technician: intervention.technician ? {
          id: intervention.technician.id,
          name: `${intervention.technician.first_name} ${intervention.technician.last_name}`,
          email: intervention.technician.email,
          phone: intervention.technician.phone,
        } : null,
        report: {
          work_description: reportData.work_description || '',
          duration: reportData.duration || 0,
          materials_used: reportData.materials_used || [],
          observations: reportData.observations || '',
          photos_count: reportData.photos_count || 0,
          status: reportData.status || 'submitted',
          submitted_at: intervention.report_submitted_at,
          // Mesures techniques
          pression: reportData.pression || '',
          puissance: reportData.puissance || reportData.temperature || '',
          intensite: reportData.intensite || '',
          tension: reportData.tension || '',
          // Section Équipements (nouveau format - tableau)
          equipments: reportData.equipments || [],
          // Section Équipement (format legacy)
          equipment_state: reportData.equipment_state || '',
          equipment_type: reportData.equipment_type || '',
          equipment_brand: reportData.equipment_brand || '',
          // Section Détail Intervention
          technician_name: reportData.technician_name || '',
          intervention_date: reportData.intervention_date || '',
          start_time: reportData.start_time || '',
          end_time: reportData.end_time || '',
          intervention_nature: reportData.intervention_nature || '',
          // Pièces de rechange
          spare_parts: reportData.spare_parts || [],
        },
      };
    });

    console.log(`✅ ${reports.length} rapport(s) trouvé(s) sur ${count} total`);

    res.json({
      success: true,
      data: reports,
      pagination: {
        page,
        limit,
        total: count,
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('❌ Erreur récupération rapports admin:', error);
    next(error);
  }
});

// Get a single report details (admin)
router.get('/reports/:interventionId', async (req, res, next) => {
  try {
    const { interventionId } = req.params;

    const intervention = await Intervention.findByPk(interventionId, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone'],
        },
      ],
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée',
      });
    }

    if (!intervention.report_submitted_at) {
      return res.status(404).json({
        success: false,
        message: 'Aucun rapport soumis pour cette intervention',
      });
    }

    const reportData = intervention.report_data ? 
      (typeof intervention.report_data === 'string' ? 
        JSON.parse(intervention.report_data) : intervention.report_data) 
      : {};

    const report = {
      id: intervention.id,
      intervention_title: intervention.title,
      intervention_description: intervention.description,
      intervention_address: intervention.address,
      intervention_status: intervention.status,
      scheduled_date: intervention.scheduled_date,
      completed_date: intervention.completed_date,
      customer: intervention.customer ? {
        id: intervention.customer.id,
        name: `${intervention.customer.first_name} ${intervention.customer.last_name}`,
        email: intervention.customer.email,
        phone: intervention.customer.phone,
      } : null,
      technician: intervention.technician ? {
        id: intervention.technician.id,
        name: `${intervention.technician.first_name} ${intervention.technician.last_name}`,
        email: intervention.technician.email,
        phone: intervention.technician.phone,
      } : null,
      report: {
        work_description: reportData.work_description || '',
        duration: reportData.duration || 0,
        materials_used: reportData.materials_used || [],
        observations: reportData.observations || '',
        photos_count: reportData.photos_count || 0,
        status: reportData.status || 'submitted',
        submitted_at: intervention.report_submitted_at,
        // Mesures techniques
        pression: reportData.pression || '',
        puissance: reportData.puissance || reportData.temperature || '',
        intensite: reportData.intensite || '',
        tension: reportData.tension || '',
        // Section Équipements (nouveau format - tableau)
        equipments: reportData.equipments || [],
        // Section Équipement (format legacy)
        equipment_state: reportData.equipment_state || '',
        equipment_type: reportData.equipment_type || '',
        equipment_brand: reportData.equipment_brand || '',
        // Section Détail Intervention
        technician_name: reportData.technician_name || '',
        intervention_date: reportData.intervention_date || '',
        start_time: reportData.start_time || '',
        end_time: reportData.end_time || '',
        intervention_nature: reportData.intervention_nature || '',
        // Pièces de rechange
        spare_parts: reportData.spare_parts || [],
      },
    };

    res.json({
      success: true,
      data: report,
    });
  } catch (error) {
    console.error('❌ Erreur récupération détail rapport:', error);
    next(error);
  }
});

// ==================== SOUSCRIPTIONS ====================

// GET /api/admin/subscriptions - Récupérer toutes les souscriptions (Admin)
router.get('/subscriptions', async (req, res) => {
  try {
    const { Subscription, MaintenanceOffer, InstallationService, RepairService, User } = require('../models');
    
    console.log('🔍 GET /api/admin/subscriptions');
    
    const subscriptions = await Subscription.findAll({
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        },
        {
          model: MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'description', 'price', 'duration', 'features']
        },
        {
          model: InstallationService,
          as: 'installationService',
          attributes: ['id', 'title', 'model', 'price', 'description', 'duration', 'isActive']
        },
        {
          model: RepairService,
          as: 'repairService',
          attributes: ['id', 'title', 'model', 'price', 'description', 'duration', 'isActive']
        }
      ],
      order: [['created_at', 'DESC']]
    });
    
    console.log(`✅ Found ${subscriptions.length} subscriptions`);
    
    res.json({
      success: true,
      data: subscriptions,
      message: 'Souscriptions récupérées avec succès'
    });
  } catch (error) {
    console.error('❌ Error getting admin subscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des souscriptions',
      error: error.message
    });
  }
});

// PATCH /api/admin/subscriptions/:id/cancel - Annuler une souscription (Admin)
router.patch('/subscriptions/:id/cancel', async (req, res) => {
  try {
    const { Subscription, User } = require('../models');
    const { id } = req.params;
    
    console.log(`📝 PATCH /api/admin/subscriptions/${id}/cancel`);
    
    const subscription = await Subscription.findByPk(id, {
      include: [{
        model: User,
        as: 'customer',
        attributes: ['id', 'email', 'first_name', 'last_name']
      }]
    });
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    if (subscription.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Cette souscription est déjà annulée'
      });
    }
    
    await subscription.update({
      status: 'cancelled',
      cancelled_at: new Date()
    });
    
    console.log(`✅ Souscription #${id} annulée avec succès`);
    
    res.json({
      success: true,
      data: subscription,
      message: 'Souscription annulée avec succès'
    });
  } catch (error) {
    console.error('❌ Error cancelling subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'annulation de la souscription',
      error: error.message
    });
  }
});

module.exports = router;
