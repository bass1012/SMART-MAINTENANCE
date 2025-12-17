const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
const { Op } = require('sequelize');
const { User, CustomerProfile, TechnicianProfile, Intervention } = require('../models');

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(authorize('admin'));

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

// System settings routes
router.get('/settings', (req, res) => {
  res.json({
    success: true,
    message: 'System settings',
    data: {}
  });
});

router.put('/settings', (req, res) => {
  res.json({
    success: true,
    message: 'Settings updated successfully'
  });
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

module.exports = router;
