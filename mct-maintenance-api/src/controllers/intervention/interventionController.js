const { MaintenanceSchedule, User, Intervention, CustomerProfile, Equipment, InterventionImage, MaintenanceOffer, RepairService, InstallationService, Subscription, DiagnosticReport, Quote } = require('../../models');
const { Op, sequelize } = require('sequelize');
const { sequelize: db } = require('../../config/database');
const { 
  notifyNewIntervention,
  notifyInterventionAssigned,
  notifyTechnicianAssignedToCustomer,
  notifyInterventionCompleted,
  notifyInterventionUpdated,
  notifyInterventionCancelled,
  notifyInterventionInProgress,
  notifyTechnicianOnTheWay,
  notifyTechnicianArrived
} = require('../../services/notificationHelpers');
const notificationService = require('../../services/notificationService');
const { sendEmail } = require('../../services/emailService');
const {
  sendInterventionCreatedEmail,
  sendInterventionAssignedEmail,
  sendInterventionStartedEmail,
  sendInterventionCompletedEmail,
  sendInterventionReportEmail,
  sendInterventionRatingEmail
} = require('../../services/emailHelper');
const upload = require('../../config/multer');
const schedulingService = require('../../services/schedulingService');

// Intervention Controller - Implementation complète
const getAllInterventions = async (req, res) => {
  try {
    const { status, priority, customer_id, technician_id, page = 1, limit = 10 } = req.query;
    
    const where = {};
    if (status) where.status = status;
    if (priority) where.priority = priority;
    
    // Si customer_id est fourni, il peut être un User.id, donc le convertir en CustomerProfile.id
    if (customer_id) {
      const customerProfile = await CustomerProfile.findOne({ 
        where: { user_id: customer_id } 
      });
      
      if (customerProfile) {
        where.customer_id = customerProfile.id;
        console.log(`🔄 Conversion User.id ${customer_id} → CustomerProfile.id ${customerProfile.id} pour filtre`);
      } else {
        // Si pas de profile trouvé, essayer directement avec l'ID fourni (au cas où c'est déjà un CustomerProfile.id)
        where.customer_id = customer_id;
      }
    }
    
    if (technician_id) where.technician_id = technician_id;

    const offset = (page - 1) * limit;

    const result = await Intervention.findAndCountAll({
      where,
      include: [
        {
          model: InterventionImage,
          as: 'images',
          attributes: ['id', 'image_url', 'order', 'image_type'],
          required: false
        },
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
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name', 'email'],
          required: false
        },
        {
          model: MaintenanceOffer,
          as: 'maintenance_offer',
          attributes: ['id', 'title', 'price', 'description', 'duration'],
          required: false
        },
        {
          model: RepairService,
          as: 'repair_service',
          attributes: ['id', 'title', 'model', 'price', 'description'],
          required: false
        },
        {
          model: InstallationService,
          as: 'installation_service',
          attributes: ['id', 'title', 'model', 'price', 'description'],
          required: false
        }
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [
        ['created_at', 'DESC'],
        [{ model: InterventionImage, as: 'images' }, 'order', 'ASC']
      ]
    });

    const interventions = await Promise.all(result.rows.map(async intervention => {
      const plain = intervention.get({ plain: true });
      // Reformater customer pour compatibilité
      let customer = null;
      if (plain.customer) {
        customer = {
          id: plain.customer.user?.id || plain.customer.id,
          email: plain.customer.user?.email || '',
          phone: plain.customer.user?.phone || '',
          first_name: plain.customer.first_name,
          last_name: plain.customer.last_name
        };
      }
      
      // Vérifier si le client a une souscription active pour cette offre
      let has_active_subscription = false;
      if (plain.maintenance_offer_id && customer) {
        const activeSubscription = await Subscription.findOne({
          where: {
            customer_id: customer.id,
            maintenance_offer_id: plain.maintenance_offer_id,
            status: 'active',
            payment_status: 'paid',
            end_date: { [Op.gte]: new Date() }
          }
        });
        has_active_subscription = !!activeSubscription;
      }
      
      return {
        ...plain,
        customer,
        technician: plain.technician || null,
        maintenance_offer: plain.maintenance_offer ? {
          ...plain.maintenance_offer,
          has_active_subscription
        } : null
      };
    }));

    res.status(200).json({
      success: true,
      data: {
        interventions,
        total: result.count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(result.count / limit)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des interventions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des interventions',
      error: error.message
    });
  }
};

const getInterventionById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const intervention = await Intervention.findByPk(id, {
      include: [
        {
          model: InterventionImage,
          as: 'images',
          attributes: ['id', 'image_url', 'order', 'image_type'],
          required: false
        },
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
        { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'], required: false },
        {
          model: MaintenanceOffer,
          as: 'maintenance_offer',
          attributes: ['id', 'title', 'price', 'description', 'duration'],
          required: false
        },
        {
          model: RepairService,
          as: 'repair_service',
          attributes: ['id', 'title', 'model', 'price', 'description'],
          required: false
        },
        {
          model: InstallationService,
          as: 'installation_service',
          attributes: ['id', 'title', 'model', 'price', 'description'],
          required: false
        },
        {
          model: DiagnosticReport,
          as: 'diagnosticReports',
          required: false
        }
      ],
      order: [
        [{ model: InterventionImage, as: 'images' }, 'order', 'ASC']
      ]
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }
    
    // Séparer les images par type
    const allImages = intervention.images || [];
    console.log(`🔍 Debug - Total images: ${allImages.length}`);
    allImages.forEach(img => {
      console.log(`  - Image ${img.id}: type="${img.image_type}" url=${img.image_url}`);
    });
    
    const interventionImages = allImages.filter(img => img.image_type === 'intervention' || !img.image_type);
    const reportImages = allImages.filter(img => img.image_type === 'report');
    
    console.log(`📸 Intervention ${id}: ${interventionImages.length} images client, ${reportImages.length} images rapport`);

    // Préparer la réponse avec images séparées
    const interventionData = intervention.toJSON();
    interventionData.intervention_images = interventionImages;
    interventionData.report_images = reportImages;
    
    res.status(200).json({
      success: true,
      data: interventionData
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'intervention',
      error: error.message
    });
  }
};

// Créer une intervention avec support d'images (multipart/form-data)
const createIntervention = [
  // Middleware multer pour gérer l'upload d'images (max 5)
  upload.array('images', 5),
  
  async (req, res) => {
    const transaction = await Intervention.sequelize.transaction();
    let committed = false;
    
    try {
      console.log('📝 Création d\'une nouvelle intervention...');
      console.log('📋 Données reçues:', req.body);
      
      const interventionData = req.body;
      
      // Validation des données requises
      if (!interventionData.title || !interventionData.description || !interventionData.customer_id || !interventionData.scheduled_date) {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: 'Données manquantes: title, description, customer_id et scheduled_date sont requis'
        });
      }

      // 🔄 IMPORTANT: Convertir User.id en CustomerProfile.id si nécessaire
      // L'app mobile peut envoyer User.id, mais la table interventions attend CustomerProfile.id
      let actualCustomerId = interventionData.customer_id;
      
      // Vérifier si le customer_id fourni est un User.id ou CustomerProfile.id
      const customerProfile = await CustomerProfile.findOne({
        where: { user_id: interventionData.customer_id }
      });
      
      if (customerProfile) {
        // C'était un User.id, on utilise le CustomerProfile.id
        actualCustomerId = customerProfile.id;
        console.log(`🔄 Conversion User.id ${interventionData.customer_id} → CustomerProfile.id ${actualCustomerId}`);
      } else {
        // Vérifier si c'est déjà un CustomerProfile.id valide
        const profileExists = await CustomerProfile.findByPk(interventionData.customer_id);
        if (!profileExists) {
          await transaction.rollback();
          return res.status(400).json({
            success: false,
            message: 'Client non trouvé'
          });
        }
        console.log(`✅ CustomerProfile.id ${actualCustomerId} valide`);
      }
      
      // Mettre à jour avec le bon ID
      interventionData.customer_id = actualCustomerId;

      // 💰 Coût du diagnostic : OBLIGATOIRE pour les diagnostics, réparations et installations
      // Pour l'entretien : gratuit si le client a une souscription active, sinon payant
      const interventionType = interventionData.intervention_type?.toLowerCase() || '';
      const requiresDiagnosticFee = interventionType === 'diagnostic' || 
                                     interventionType === 'repair' || 
                                     interventionType === 'réparation' ||
                                     interventionType === 'reparation' ||
                                     interventionType === 'installation' ||
                                     interventionType === 'dépannage' ||
                                     interventionType === 'depannage';
      
      let diagnosticFee = 0;
      let isFreeDiagnosis = true;
      
      // Vérifier si c'est un entretien sans souscription active
      const isMaintenanceType = interventionType === 'entretien' || interventionType === 'maintenance';
      let hasActiveSubscription = false;
      
      if (isMaintenanceType && interventionData.maintenance_offer_id) {
        // Vérifier si le client a une souscription active pour cette offre
        const activeSubscription = await Subscription.findOne({
          where: {
            customer_id: actualCustomerId,
            maintenance_offer_id: interventionData.maintenance_offer_id,
            status: 'active',
            payment_status: 'paid'
          }
        });
        hasActiveSubscription = !!activeSubscription;
        console.log(`🔍 Souscription active pour offre #${interventionData.maintenance_offer_id}: ${hasActiveSubscription ? 'OUI' : 'NON'}`);
      }
      
      if (requiresDiagnosticFee) {
        // Utiliser le prix du service si disponible, sinon frais par défaut
        if (interventionType === 'repair' && interventionData.repair_service_id) {
          const repairService = await RepairService.findByPk(interventionData.repair_service_id);
          diagnosticFee = repairService ? parseFloat(repairService.price) : 13.00;
        } else if (interventionType === 'installation' && interventionData.installation_service_id) {
          const installationService = await InstallationService.findByPk(interventionData.installation_service_id);
          diagnosticFee = installationService ? parseFloat(installationService.price) : 0;
        } else {
          diagnosticFee = 13.00; // Frais de diagnostic par défaut
        }
        isFreeDiagnosis = false;
        console.log('💵 Frais de service : ' + diagnosticFee + ' (type: ' + interventionType + ')');
      } else if (isMaintenanceType && !hasActiveSubscription && interventionData.maintenance_offer_id) {
        // Entretien sans souscription active : utiliser le prix de l'offre
        const maintenanceOffer = await MaintenanceOffer.findByPk(interventionData.maintenance_offer_id);
        if (maintenanceOffer) {
          diagnosticFee = parseFloat(maintenanceOffer.price);
          isFreeDiagnosis = false;
          console.log('💵 Entretien sans souscription - Prix offre: ' + diagnosticFee + ' FCFA');
        }
      } else {
        console.log('✓ Pas de frais de diagnostic (type: ' + interventionType + ')');
      }

      // Créer l'intervention avec les frais de diagnostic
      // Si un technicien est assigné dès la création, le statut est "assigned"
      const status = interventionData.technician_id ? 'assigned' : 'pending';
      
      const intervention = await Intervention.create({
        ...interventionData,
        status,
        diagnostic_fee: diagnosticFee,
        is_free_diagnosis: isFreeDiagnosis
      }, { transaction });
      console.log(`✅ Intervention créée avec l'ID: ${intervention.id}`);

      // Sauvegarder les images si présentes (images du client)
      if (req.files && req.files.length > 0) {
        console.log(`📸 ${req.files.length} image(s) client uploadée(s)`);
        
        const imagePromises = req.files.map((file, index) => {
          const imageUrl = `/uploads/interventions/${file.filename}`;
          console.log(`   ${index + 1}. ${imageUrl}`);
          
          return InterventionImage.create({
            intervention_id: intervention.id,
            image_url: imageUrl,
            order: index,
            image_type: 'intervention' // Images du client
          }, { transaction });
        });
        
        await Promise.all(imagePromises);
        console.log(`✅ ${req.files.length} image(s) client enregistrée(s) en base`);
      }

      await transaction.commit();
      committed = true;
      console.log('✅ Transaction validée');

      // Récupérer l'intervention créée avec les relations et les images
      const createdIntervention = await Intervention.findByPk(intervention.id, {
        include: [
          {
            model: InterventionImage,
            as: 'images',
            attributes: ['id', 'image_url', 'order', 'image_type']
          },
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
            model: User, 
            as: 'technician', 
            attributes: ['id', 'first_name', 'last_name', 'email'], 
            required: false 
          }
        ],
        order: [
          [{ model: InterventionImage, as: 'images' }, 'order', 'ASC']
        ]
      });

      // 🔔 Envoi des notifications
      try {
        // Enrichir le customer pour la notification
        const customer = {
          id: createdIntervention.customer?.user?.id || createdIntervention.customer_id,
          email: createdIntervention.customer?.user?.email || '',
          phone: createdIntervention.customer?.user?.phone || '',
          first_name: createdIntervention.customer?.first_name || '',
          last_name: createdIntervention.customer?.last_name || ''
        };
        
        // 1. Notifier le client (confirmation de création)
        await notificationService.create({
          userId: customer.id,
          type: 'intervention_request',
          title: 'Intervention créée',
          message: `Votre demande d'intervention "${createdIntervention.title}" a été créée`,
          data: {
            interventionId: createdIntervention.id,
            interventionTitle: createdIntervention.title
          },
          priority: 'high',
          actionUrl: `/interventions`
        });
        console.log('✅ Notification envoyée au client');

        // 📧 Email au client (confirmation de création - template professionnel)
        const emailResult = await sendInterventionCreatedEmail(createdIntervention.get({ plain: true }), customer);
        if (emailResult.success) {
          console.log('📧 Email envoyé au client:', customer.email);
        }

        // 2. Notifier les admins de la nouvelle intervention
        await notificationService.notifyAdmins({
          type: 'intervention_request',
          title: '🔧 Nouvelle demande d\'intervention',
          message: `${customer.first_name || customer.email} a créé une demande: "${createdIntervention.title}"`,
          data: {
            interventionId: createdIntervention.id,
            customerId: customer.id,
            customerName: `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || customer.email,
            interventionTitle: createdIntervention.title,
            scheduledDate: createdIntervention.scheduled_date
          },
          priority: 'high',
          actionUrl: `/interventions`
        });
        console.log('✅ Notification envoyée aux admins');

        // 3. Si un technicien est assigné, le notifier
        if (createdIntervention.technician_id && createdIntervention.technician) {
          await notifyInterventionAssigned(createdIntervention, createdIntervention.technician);
          console.log('✅ Notification envoyée au technicien');
          
          // 4. Notifier aussi le client que le technicien a été assigné
          await notifyTechnicianAssignedToCustomer(createdIntervention, customer, createdIntervention.technician);
          console.log('✅ Notification client - technicien assigné');
        }
      } catch (notifError) {
        console.error('❌ ERREUR NOTIFICATION/EMAIL DÉTAILLÉE:', {
          message: notifError.message,
          stack: notifError.stack,
          customerEmail: customer?.email,
          interventionId: createdIntervention?.id
        });
        // Ne pas bloquer la création si la notification échoue
      }

      res.status(201).json({
        success: true,
        message: 'Intervention créée avec succès',
        data: createdIntervention
      });

    } catch (error) {
      try {
        if (!committed && transaction && transaction.finished !== 'commit' && transaction.finished !== 'rollback') {
          await transaction.rollback();
        }
      } catch (rbErr) {
        console.error('❌ Erreur rollback:', rbErr);
      }
      console.error('❌ Erreur lors de la création:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la création de l\'intervention',
        error: error.message
      });
    }
  }
];

const updateIntervention = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const intervention = await Intervention.findByPk(id);
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    await intervention.update(updateData);

    // Récupérer l'intervention mise à jour avec les relations
    const updatedIntervention = await Intervention.findByPk(id, {
      include: [
        { 
          model: CustomerProfile, 
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'email']
            }
          ]
        },
        { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'], required: false }
      ]
    });

    // 📬 Notifier le client de la modification (SAUF si c'est une assignation de technicien)
    // Si technician_id est modifié, utiliser la route /assign qui gère les notifications spécifiques
    const isTechnicianAssignment = updateData.hasOwnProperty('technician_id');
    
    if (!isTechnicianAssignment) {
      try {
        if (updatedIntervention.customer) {
          // Enrichir le customer pour la notification
          const customer = {
            id: updatedIntervention.customer.user?.id || updatedIntervention.customer.id,
            email: updatedIntervention.customer.user?.email || '',
            first_name: updatedIntervention.customer.first_name || '',
            last_name: updatedIntervention.customer.last_name || ''
          };
          
          console.log('📤 Envoi notification modification intervention au client user_id:', customer.id);
          await notifyInterventionUpdated(updatedIntervention, customer);
          console.log('✅ Notification envoyée au client pour la modification de l\'intervention');
        }
      } catch (notifError) {
        console.error('⚠️  Erreur notification modification intervention:', notifError.message);
      }
    } else {
      console.log('ℹ️  Assignation de technicien détectée - notification gérée par la route /assign');
    }

    res.status(200).json({
      success: true,
      data: updatedIntervention
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de l\'intervention',
      error: error.message
    });
  }
};

const deleteIntervention = async (req, res) => {
  const transaction = await db.transaction();
  
  try {
    const { id } = req.params;

    const intervention = await Intervention.findByPk(id, {
      include: [
        { model: DiagnosticReport, as: 'diagnosticReports' },
        { model: Quote, as: 'quotes' }
      ]
    });
    
    if (!intervention) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Supprimer les rapports de diagnostic associés
    if (intervention.diagnosticReports && intervention.diagnosticReports.length > 0) {
      for (const report of intervention.diagnosticReports) {
        // Supprimer les devis associés au rapport
        await Quote.destroy({ 
          where: { diagnostic_report_id: report.id },
          transaction 
        });
      }
      // Supprimer les rapports
      await DiagnosticReport.destroy({ 
        where: { intervention_id: id },
        transaction 
      });
    }

    // Supprimer les devis directement liés à l'intervention
    await Quote.destroy({ 
      where: { intervention_id: id },
      transaction 
    });

    // Supprimer les images d'intervention
    await InterventionImage.destroy({ 
      where: { intervention_id: id },
      transaction 
    });

    // Maintenant supprimer l'intervention
    await intervention.destroy({ transaction });

    await transaction.commit();

    res.status(200).json({
      success: true,
      message: 'Intervention et toutes ses dépendances supprimées avec succès'
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Erreur lors de la suppression de l\'intervention:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de l\'intervention',
      error: error.message
    });
  }
};

const assignIntervention = async (req, res) => {
  try {
    const { id } = req.params;
    const { technician_id } = req.body;

    if (!technician_id) {
      return res.status(400).json({
        success: false,
        message: 'technician_id est requis'
      });
    }

    // Vérifier que l'intervention existe
    const intervention = await Intervention.findByPk(id);
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    // Vérifier que le technicien existe
    const technician = await User.findByPk(technician_id);
    if (!technician || technician.role !== 'technician') {
      return res.status(404).json({
        success: false,
        message: 'Technicien non trouvé'
      });
    }

    // Vérifier la limite d'interventions par jour
    const MAX_DAILY_INTERVENTIONS = process.env.MAX_DAILY_INTERVENTIONS || 6;
    const interventionDate = intervention.scheduled_date 
      ? new Date(intervention.scheduled_date).toISOString().split('T')[0]
      : new Date().toISOString().split('T')[0];

    const dailyCount = await Intervention.count({
      where: {
        technician_id,
        scheduled_date: {
          [Op.gte]: new Date(interventionDate),
          [Op.lt]: new Date(new Date(interventionDate).getTime() + 24 * 60 * 60 * 1000)
        },
        status: { [Op.notIn]: ['cancelled', 'rejected'] }
      }
    });

    if (dailyCount >= MAX_DAILY_INTERVENTIONS) {
      return res.status(400).json({
        success: false,
        message: `Le technicien a atteint la limite de ${MAX_DAILY_INTERVENTIONS} interventions pour cette journée`,
        data: {
          current_count: dailyCount,
          max_allowed: MAX_DAILY_INTERVENTIONS,
          date: interventionDate
        }
      });
    }

    // Assigner le technicien
    await intervention.update({ 
      technician_id,
      status: 'assigned' // Changer le statut en "assigned"
    });

    // Récupérer l'intervention mise à jour avec les relations
    const updatedIntervention = await Intervention.findByPk(id, {
      include: [
        { 
          model: CustomerProfile, 
          as: 'customer', 
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'email', 'phone']
            }
          ]
        },
        { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    // 🔔 Notifier le technicien de l'assignation
    try {
      console.log(`📤 Envoi notification assignation au technicien user_id: ${technician_id}`);
      await notifyInterventionAssigned(updatedIntervention, technician);
      console.log('✅ Notification envoyée au technicien pour l\'assignation');
    } catch (notifError) {
      console.error('⚠️  Erreur notification assignation technicien:', notifError.message);
      // Ne pas bloquer l'assignation si la notification échoue
    }

    // 🔔 Notifier le client de l'assignation du technicien
    try {
      if (updatedIntervention.customer) {
        // Construire l'objet customer à partir du CustomerProfile
        const customer = {
          id: updatedIntervention.customer.user?.id || updatedIntervention.customer.id,
          email: updatedIntervention.customer.user?.email || '',
          phone: updatedIntervention.customer.user?.phone || '',
          first_name: updatedIntervention.customer.first_name || '',
          last_name: updatedIntervention.customer.last_name || ''
        };
        
        console.log(`📤 Envoi notification assignation au client user_id: ${customer.id}`);
        console.log(`👤 Client: ${customer.first_name} ${customer.last_name}`);
        await notifyTechnicianAssignedToCustomer(updatedIntervention, customer, technician);
        console.log('✅ Notification envoyée au client pour l\'assignation du technicien');
        
        // 📧 Email au client et technicien (assignation)
        await sendInterventionAssignedEmail(
          updatedIntervention.get({ plain: true }),
          technician.get({ plain: true }),
          customer
        );
        console.log('✅ Emails professionnels envoyés (client + technicien)');
      } else {
        console.log('⚠️  Pas de customer trouvé pour cette intervention');
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification assignation client:', notifError.message);
      // Ne pas bloquer l'assignation si la notification échoue
    }

    res.status(200).json({
      success: true,
      message: 'Technicien assigné avec succès',
      data: updatedIntervention
    });
  } catch (error) {
    console.error('Erreur lors de l\'assignation du technicien:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'assignation du technicien',
      error: error.message
    });
  }
};

// Accepter une intervention (technicien)
const acceptIntervention = async (req, res, next) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    console.log(`✅ Technicien ${technicianId} accepte l'intervention ${id}`);
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId }
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée ou non assignée à ce technicien'
      });
    }
    
    if (intervention.status !== 'assigned' && intervention.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Impossible d'accepter une intervention avec le statut: ${intervention.status}`
      });
    }
    
    await intervention.update({
      status: 'accepted',
      accepted_at: new Date()
    });
    
    res.status(200).json({
      success: true,
      message: 'Intervention acceptée avec succès',
      data: intervention
    });
  } catch (error) {
    console.error('❌ Erreur acceptation intervention:', error);
    next(error);
  }
};

// Signaler "En route"
const markOnTheWay = async (req, res, next) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{ model: User, as: 'user' }]
        }
      ]
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }
    
    if (intervention.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: 'Vous devez d\'abord accepter l\'intervention'
      });
    }
    
    await intervention.update({
      status: 'on_the_way',
      departed_at: new Date()
    });

    // 📱 Notification au client
    try {
      if (intervention.customer?.user) {
        const technician = await User.findByPk(technicianId);
        await notifyTechnicianOnTheWay(intervention, intervention.customer.user, technician);
        console.log(`📱 Notification envoyée: technicien en route pour intervention #${id}`);
      }
    } catch (notifError) {
      console.error('⚠️ Erreur notification (non bloquante):', notifError.message);
    }
    
    res.status(200).json({
      success: true,
      message: 'Statut mis à jour: En route',
      data: intervention
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour statut:', error);
    next(error);
  }
};

// Signaler "Arrivé sur les lieux"
const markArrived = async (req, res, next) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{ model: User, as: 'user' }]
        }
      ]
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }
    
    if (intervention.status !== 'on_the_way') {
      return res.status(400).json({
        success: false,
        message: 'Vous devez d\'abord signaler que vous êtes en route'
      });
    }
    
    await intervention.update({
      status: 'arrived',
      arrived_at: new Date()
    });

    // 📱 Notification au client
    try {
      if (intervention.customer?.user) {
        const technician = await User.findByPk(technicianId);
        await notifyTechnicianArrived(intervention, intervention.customer.user, technician);
        console.log(`📱 Notification envoyée: technicien arrivé pour intervention #${id}`);
      }
    } catch (notifError) {
      console.error('⚠️ Erreur notification (non bloquante):', notifError.message);
    }
    
    res.status(200).json({
      success: true,
      message: 'Statut mis à jour: Arrivé sur les lieux',
      data: intervention
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour statut:', error);
    next(error);
  }
};

// Démarrer l'intervention
const startIntervention = async (req, res, next) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId }
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }
    
    // Vérifier le statut: 'arrived' pour le workflow normal, 'execution_confirmed' pour l'exécution immédiate
    const validStatuses = ['arrived', 'execution_confirmed'];
    if (!validStatuses.includes(intervention.status)) {
      return res.status(400).json({
        success: false,
        message: 'Vous devez d\'abord signaler votre arrivée'
      });
    }
    
    await intervention.update({
      status: 'in_progress',
      started_at: new Date()
    });
    
    // 📧 Email au client (intervention démarrée)
    try {
      // customer_id est un CustomerProfile.id, pas un User.id
      const customerProfile = await CustomerProfile.findByPk(intervention.customer_id, {
        include: [{ model: User, as: 'user' }]
      });
      
      if (customerProfile && customerProfile.user) {
        const technicianUser = await User.findByPk(technicianId);
        const enrichedCustomer = {
          id: customerProfile.user.id,
          email: customerProfile.user.email,
          first_name: customerProfile.first_name,
          last_name: customerProfile.last_name
        };
        
        await sendInterventionStartedEmail(
          intervention.get({ plain: true }),
          technicianUser.get({ plain: true }),
          enrichedCustomer
        );
        console.log('✅ Email professionnel démarrage envoyé au client');
      }
    } catch (emailError) {
      console.error('⚠️ Erreur envoi email démarrage:', emailError.message);
    }
    
    res.status(200).json({
      success: true,
      message: 'Intervention démarrée',
      data: intervention
    });
  } catch (error) {
    console.error('❌ Erreur démarrage intervention:', error);
    next(error);
  }
};

// Terminer l'intervention
const completeIntervention = async (req, res, next) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId }
    });
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }
    
    if (intervention.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        message: 'L\'intervention doit être en cours pour être terminée'
      });
    }
    
    await intervention.update({
      status: 'completed',
      completed_at: new Date()
    });
    
    // 📧 Email au client (intervention terminée)
    try {
      // customer_id est un CustomerProfile.id, pas un User.id
      const customerProfile = await CustomerProfile.findByPk(intervention.customer_id, {
        include: [{ model: User, as: 'user' }]
      });
      
      if (customerProfile && customerProfile.user) {
        const enrichedCustomer = {
          id: customerProfile.user.id,
          email: customerProfile.user.email,
          first_name: customerProfile.first_name,
          last_name: customerProfile.last_name
        };
        
        await sendInterventionCompletedEmail(
          intervention.get({ plain: true }),
          enrichedCustomer
        );
        console.log('✅ Email professionnel terminaison envoyé au client');
      }
    } catch (emailError) {
      console.error('⚠️ Erreur envoi email terminaison:', emailError.message);
    }
    
    res.status(200).json({
      success: true,
      message: 'Intervention terminée avec succès',
      data: intervention
    });
  } catch (error) {
    console.error('❌ Erreur fin intervention:', error);
    next(error);
  }
};

// Soumettre un rapport d'intervention
const submitReport = async (req, res, next) => {
  try {
    const { id } = req.params;
    const technicianId = req.user.id;
    let {
      work_description,
      materials_used,
      duration,
      observations,
      photos,
      // Mesures techniques
      pression,
      temperature,
      intensite,
      tension,
    } = req.body;

    console.log(`📝 Soumission rapport pour intervention ${id}`);
    
    // Parser materials_used si c'est un string JSON
    if (typeof materials_used === 'string') {
      try {
        materials_used = JSON.parse(materials_used);
      } catch (e) {
        console.warn('⚠️ Erreur parsing materials_used, utilisation valeur par défaut');
        materials_used = [];
      }
    }

    // Vérifier que l'intervention existe et appartient au technicien
    const intervention = await Intervention.findOne({
      where: { id, technician_id: technicianId }
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée ou non assignée à ce technicien'
      });
    }

    if (intervention.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'L\'intervention doit être terminée pour soumettre un rapport'
      });
    }

    // Validation des données
    if (!work_description || work_description.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'La description du travail effectué est obligatoire'
      });
    }

    // 📸 Sauvegarder les images uploadées par le technicien
    const uploadedFiles = req.files || [];
    console.log(`📸 ${uploadedFiles.length} image(s) reçue(s) du technicien`);
    
    if (uploadedFiles.length > 0) {
      for (let i = 0; i < uploadedFiles.length; i++) {
        const file = uploadedFiles[i];
        const imagePath = `/uploads/interventions/${file.filename}`;
        
        await InterventionImage.create({
          intervention_id: id,
          image_url: imagePath,
          order: i,
          image_type: 'report' // Images du rapport technicien
        });
        
        console.log(`✅ Image rapport sauvegardée: ${imagePath}`);
      }
    }

    // Préparer les données du rapport
    const reportData = {
      intervention_id: id,
      technician_id: technicianId,
      work_description: work_description.trim(),
      materials_used: Array.isArray(materials_used) ? materials_used : [],
      duration: duration || 0,
      observations: observations ? observations.trim() : null,
      photos_count: uploadedFiles.length,
      status: 'submitted',
      submitted_at: new Date(),
      // Mesures techniques
      pression: pression || '',
      temperature: temperature || '',
      intensite: intensite || '',
      tension: tension || '',
    };

    // TODO: Sauvegarder le rapport dans une table dédiée
    // Pour l'instant, on met à jour l'intervention avec les infos du rapport
    await intervention.update({
      report_data: JSON.stringify(reportData),
      report_submitted_at: new Date(),
    });

    console.log(`✅ Rapport soumis avec succès (${uploadedFiles.length} image(s))`);

    // 🔔 Notifier le client et les admins
    try {
      // Récupérer l'intervention avec toutes les relations pour les notifications
      const interventionWithRelations = await Intervention.findByPk(id, {
        include: [
          { 
            model: CustomerProfile, 
            as: 'customer', 
            attributes: ['id', 'first_name', 'last_name'],
            include: [{
              model: User,
              as: 'user',
              attributes: ['id', 'email']
            }]
          },
          { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'] }
        ]
      });

      const technicianName = interventionWithRelations.technician 
        ? `${interventionWithRelations.technician.first_name} ${interventionWithRelations.technician.last_name}`
        : 'Technicien';

      // 1. Notifier le client
      if (interventionWithRelations.customer_id) {
        console.log(`📧 Notification client ${interventionWithRelations.customer_id} pour rapport intervention ${id}`);
        await notificationService.create({
          userId: interventionWithRelations.customer_id,
          type: 'report_submitted',
          title: 'Rapport d\'intervention disponible',
          message: `Le rapport de votre intervention "${interventionWithRelations.title}" a été soumis par ${technicianName}`,
          data: {
            interventionId: id,
            interventionTitle: interventionWithRelations.title,
            technicianName: technicianName
          },
          priority: 'high',
          actionUrl: `/rapports-interventions`
        });
        console.log('✅ Client notifié');
      }

      // 2. Notifier tous les admins
      console.log('👥 Recherche des admins pour notification rapport...');
      const admins = await User.findAll({
        where: { 
          role: 'admin',
          status: 'active'
        },
        attributes: ['id', 'email']
      });

      console.log(`👥 ${admins.length} admin(s) trouvé(s)`);
      
      for (const admin of admins) {
        await notificationService.create({
          userId: admin.id,
          type: 'report_submitted',
          title: 'Nouveau rapport d\'intervention',
          message: `${technicianName} a soumis le rapport pour l'intervention "${interventionWithRelations.title}"`,
          data: {
            interventionId: id,
            interventionTitle: interventionWithRelations.title,
            technicianId: technicianId,
            technicianName: technicianName,
            customerId: interventionWithRelations.customer_id
          },
          priority: 'medium',
          actionUrl: `/rapports-interventions`
        });
      }
      console.log('✅ Admins notifiés');
      
      // 📧 Email au client (rapport disponible)
      if (interventionWithRelations.customer) {
        const enrichedCustomer = {
          id: interventionWithRelations.customer.id,
          email: interventionWithRelations.customer.email,
          first_name: interventionWithRelations.customer.first_name || '',
          last_name: interventionWithRelations.customer.last_name || ''
        };
        
        await sendInterventionReportEmail(
          interventionWithRelations.get({ plain: true }),
          reportData,
          enrichedCustomer
        );
        console.log('✅ Email professionnel rapport envoyé au client');
      }

    } catch (notifError) {
      console.error('⚠️  Erreur notifications rapport:', notifError.message);
      // Ne pas bloquer la soumission du rapport si les notifications échouent
    }

    res.status(200).json({
      success: true,
      message: 'Rapport soumis avec succès',
      data: {
        intervention_id: id,
        report: reportData,
      }
    });
  } catch (error) {
    console.error('❌ Erreur soumission rapport:', error);
    next(error);
  }
};

// GET /api/interventions/reports - Liste agrégée de rapports d'intervention
const listReports = async (req, res) => {
  try {
    const { status, type, start_date, end_date, technicianId, page = 1, limit = 20, q } = req.query;

    const where = {};
    if (status) where.status = status; // scheduled | in_progress | completed | cancelled
    if (type) where.type = type; // preventive | corrective | inspection
    if (technicianId) where.technician_id = technicianId;
    if (start_date || end_date) {
      where.scheduled_date = {};
      if (start_date) where.scheduled_date[Op.gte] = new Date(start_date);
      if (end_date) where.scheduled_date[Op.lte] = new Date(end_date);
    }

    const offset = (Number(page) - 1) * Number(limit);

    const { rows, count } = await MaintenanceSchedule.findAndCountAll({
      where,
      include: [
        { 
          model: User, 
          as: 'technician', 
          attributes: ['id', 'first_name', 'last_name', 'email'] 
        },
        {
          model: Equipment,
          as: 'equipment',
          attributes: ['id', 'name', 'type', 'customer_id'],
          include: [
            {
              model: User,
              as: 'customer',
              attributes: ['id', 'first_name', 'last_name', 'email']
            }
          ]
        }
      ],
      order: [['scheduled_date', 'DESC']],
      offset,
      limit: Number(limit)
    });

    // Mapping vers un format de "rapport"
    const reports = rows.map(ms => {
      const tech = ms.technician;
      const techName = tech
        ? ([tech.first_name, tech.last_name].filter(Boolean).join(' ').trim() || tech.email)
        : null;
      
      const equip = ms.equipment;
      const equipName = equip ? `${equip.name} (${equip.type})` : null;
      
      const customer = equip?.customer;
      const customerName = customer
        ? ([customer.first_name, customer.last_name].filter(Boolean).join(' ').trim() || customer.email)
        : null;
      
      // Calculer ou estimer la durée
      let duration = null;
      
      if (ms.status === 'completed') {
        // Pour les interventions terminées, calculer la durée réelle
        if (ms.updatedAt && ms.scheduled_date) {
          const start = new Date(ms.scheduled_date);
          const end = new Date(ms.updatedAt);
          const diffMs = end - start;
          
          // Vérifier que la différence est positive et raisonnable (moins de 24h)
          if (diffMs > 0 && diffMs < 86400000) { // 24h en ms
            const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
            const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
            duration = `${diffHours}h ${diffMinutes}m`;
          }
        }
      }
      
      // Si pas de durée calculée, utiliser une durée estimée selon le type
      if (!duration) {
        const estimatedDurations = {
          preventive: '2h 00m',
          corrective: '3h 00m',
          inspection: '1h 30m'
        };
        duration = estimatedDurations[ms.type] || '2h 00m';
      }
      
      return {
        id: ms.id,
        title: `${ms.type === 'preventive' ? 'Maintenance' : ms.type === 'corrective' ? 'Dépannage' : 'Inspection'} #${ms.id}`,
        technician: techName,
        technician_id: ms.technician_id,
        client: customerName,
        date: ms.scheduled_date,
        status: ms.status, // scheduled | in_progress | completed | cancelled
        type: ms.type, // preventive | corrective | inspection
        duration: duration,
        equipment: equipName
      };
    });

    res.status(200).json({
      success: true,
      data: {
        reports,
        total: count,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(count / Number(limit))
      }
    });
  } catch (error) {
    console.error('Error listing intervention reports:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du chargement des rapports', error: error.message });
  }
};

// Mettre à jour uniquement le statut d'une intervention
const updateInterventionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const previousStatus = req.body.previousStatus; // optionnel

    // Charger l'intervention avec les relations
    const intervention = await Intervention.findByPk(id, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'first_name', 'last_name']
          }]
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }
      ]
    });

    if (!intervention) {
      return res.status(404).json({ success: false, message: 'Intervention non trouvée' });
    }

    const oldStatus = intervention.status;
    await intervention.update({ status });

    // Envoyer les notifications selon le nouveau statut
    try {
      const customer = intervention.customer;
      const technician = intervention.technician;
      const customerUser = customer?.user;

      switch (status) {
        case 'in_progress':
          // Notifier le client que l'intervention démarre
          if (customerUser) {
            await notifyInterventionInProgress(intervention, customerUser, technician);
            console.log(`📱 Notification envoyée au client: intervention #${id} en cours`);
          }
          break;

        case 'completed':
          // Notifier le client que l'intervention est terminée
          if (customerUser) {
            await notifyInterventionCompleted(intervention, customerUser);
            console.log(`📱 Notification envoyée au client: intervention #${id} terminée`);
          }
          // Notifier les admins
          await notificationService.notifyAdmins({
            type: 'intervention_completed',
            title: 'Intervention terminée',
            message: `L'intervention #${id} a été terminée par ${technician?.first_name || 'le technicien'}`,
            data: { interventionId: intervention.id },
            priority: 'medium',
            actionUrl: `/interventions`
          });
          break;

        case 'cancelled':
          // Notifier client, technicien et admins
          await notifyInterventionCancelled(intervention, customerUser, technician, 'admin');
          console.log(`📱 Notifications envoyées: intervention #${id} annulée`);
          break;

        case 'assigned':
          // Notifier le client
          if (customerUser) {
            await notifyInterventionUpdated(intervention, customerUser);
            console.log(`📱 Notification envoyée au client: intervention #${id} assignée`);
          }
          break;

        default:
          // Pour les autres statuts, notifier le client
          if (customerUser) {
            await notifyInterventionUpdated(intervention, customerUser);
          }
      }
    } catch (notifError) {
      console.error('⚠️ Erreur notification (non bloquante):', notifError.message);
    }

    res.status(200).json({ 
      success: true, 
      message: 'Statut mis à jour avec succès',
      data: intervention 
    });
  } catch (error) {
    console.error('❌ Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la mise à jour du statut', 
      error: error.message 
    });
  }
};

// Noter une intervention (customer uniquement)
const rateIntervention = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, review } = req.body;
    const userId = req.user.id;

    console.log('⭐ Évaluation intervention:', { id, userId, rating, review });

    // Récupérer le CustomerProfile pour obtenir le customer_id
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }

    const customerId = customerProfile.id;
    console.log(`🔄 Conversion User.id ${userId} → CustomerProfile.id ${customerId} pour évaluation`);

    // Vérifier que l'intervention existe
    const intervention = await Intervention.findByPk(id);
    if (!intervention) {
      return res.status(404).json({ 
        success: false, 
        message: 'Intervention non trouvée' 
      });
    }

    // Vérifier que l'intervention est terminée
    if (intervention.status !== 'completed') {
      return res.status(400).json({ 
        success: false, 
        message: 'L\'intervention doit être terminée pour être évaluée' 
      });
    }

    // Vérifier que c'est bien le client de cette intervention
    console.log('🔍 Vérification propriétaire:', { 
      interventionCustomerId: intervention.customer_id, 
      customerId: customerId 
    });
    
    if (intervention.customer_id !== customerId) {
      return res.status(403).json({ 
        success: false, 
        message: 'Vous ne pouvez évaluer que vos propres interventions' 
      });
    }

    // Vérifier si une évaluation existe déjà
    if (intervention.rating !== null) {
      return res.status(400).json({ 
        success: false, 
        message: 'Cette intervention a déjà été évaluée' 
      });
    }

    // Enregistrer l'évaluation
    await intervention.update({ 
      rating: parseInt(rating), 
      review: review || null 
    });

    console.log('✅ Évaluation enregistrée avec succès');

    // Envoyer les notifications (ne pas faire échouer la requête si ça échoue)
    try {
      // Récupérer les informations complètes
      const fullIntervention = await Intervention.findByPk(id, {
        include: [
          {
            model: User,
            as: 'customer',
            attributes: ['id', 'email', 'first_name', 'last_name'],
            include: [
              {
                model: CustomerProfile,
                as: 'customerProfile',
                attributes: ['first_name', 'last_name']
              }
            ]
          },
          {
            model: User,
            as: 'technician',
            attributes: ['id', 'first_name', 'last_name', 'email']
          }
        ]
      });

      // Préparer les informations du client
      const customerName = fullIntervention.customer.customerProfile 
        ? `${fullIntervention.customer.customerProfile.first_name} ${fullIntervention.customer.customerProfile.last_name}`
        : fullIntervention.customer.email;

      // 1. Notifier le technicien
      if (fullIntervention.technician_id) {
        const stars = '⭐'.repeat(rating);
        await notificationService.create({
          userId: fullIntervention.technician_id,
          type: 'intervention_rated',
          title: `Nouvelle évaluation ${stars}`,
          message: `${customerName} a évalué votre intervention "${fullIntervention.title}" avec ${rating}/5 étoiles${review ? ': "' + review + '"' : ''}`,
          data: {
            interventionId: fullIntervention.id,
            rating: rating,
            review: review,
            customerName: customerName
          },
          priority: 'medium',
          actionUrl: `/rapports-interventions`
        });
        console.log('📧 Notification envoyée au technicien');
      }

      // 2. Notifier tous les admins
      const admins = await User.findAll({
        where: { 
          role: 'admin',
          status: 'active'
        }
      });

      for (const admin of admins) {
        const stars = '⭐'.repeat(rating);
        await notificationService.create({
          userId: admin.id,
          type: 'intervention_rated',
          title: `Évaluation reçue ${stars}`,
          message: `${customerName} a évalué l'intervention "${fullIntervention.title}" (Technicien: ${fullIntervention.technician.first_name} ${fullIntervention.technician.last_name}) - ${rating}/5 étoiles${review ? ': "' + review + '"' : ''}`,
          data: {
            interventionId: fullIntervention.id,
            rating: rating,
            review: review,
            customerName: customerName,
            technicianName: `${fullIntervention.technician.first_name} ${fullIntervention.technician.last_name}`
          },
          priority: 'medium',
          actionUrl: `/interventions`
        });
      }
      console.log(`📧 Notifications envoyées à ${admins.length} admin(s)`);
      
      // 📧 Email au technicien (nouvelle évaluation)
      if (fullIntervention.technician) {
        await sendInterventionRatingEmail(
          fullIntervention.get({ plain: true }),
          { rating, review },
          fullIntervention.technician.get({ plain: true })
        );
        console.log('✅ Email professionnel évaluation envoyé au technicien');
      }
    } catch (notificationError) {
      // Les notifications ont échoué mais l'évaluation est enregistrée
      console.error('⚠️ Erreur lors de l\'envoi des notifications:', notificationError.message);
    }

    res.status(200).json({ 
      success: true, 
      message: 'Évaluation enregistrée avec succès',
      data: {
        id: intervention.id,
        rating: intervention.rating,
        review: intervention.review
      }
    });
  } catch (error) {
    console.error('❌ Erreur lors de l\'enregistrement de l\'évaluation:', error);
    console.error('❌ Détails erreur:', {
      name: error.name,
      message: error.message,
      errors: error.errors?.map(e => ({
        field: e.path,
        message: e.message,
        type: e.type,
        value: e.value
      }))
    });
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de l\'enregistrement de l\'évaluation', 
      error: error.message,
      details: error.errors?.map(e => e.message)
    });
  }
};

// Récupérer les interventions terminées non notées (customer uniquement)
const getUnratedInterventions = async (req, res) => {
  try {
    const userId = req.user.id;

    console.log('📋 Récupération interventions non notées pour userId:', userId);

    // Récupérer le CustomerProfile pour obtenir le customer_id
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }

    const customerId = customerProfile.id;
    console.log(`🔄 Conversion User.id ${userId} → CustomerProfile.id ${customerId}`);

    // Récupérer les interventions terminées non notées
    const unratedInterventions = await Intervention.findAll({
      where: {
        customer_id: customerId,
        status: 'completed',
        rating: null
      },
      include: [
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name']
        }
      ],
      order: [['completed_at', 'DESC']],
      limit: 10 // Limiter à 10 pour éviter surcharge
    });

    console.log(`✅ ${unratedInterventions.length} intervention(s) non notée(s) trouvée(s)`);

    res.status(200).json({
      success: true,
      data: unratedInterventions
    });
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des interventions non notées:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des interventions non notées',
      error: error.message
    });
  }
};

/**
 * Récupérer les interventions avec diagnostic non payé
 * @route GET /api/interventions/pending-diagnostic-payment
 */
const getPendingDiagnosticPayments = async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`🔍 Recherche interventions avec diagnostic non payé pour user #${userId}`);

    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }

    const customerId = customerProfile.id;

    // Récupérer les interventions avec diagnostic non payé
    // (type diagnostic ou repair ET is_free_diagnosis = false ET diagnostic_paid = false)
    const pendingPayments = await Intervention.findAll({
      where: {
        customer_id: customerId,
        is_free_diagnosis: false,
        diagnostic_paid: false,
        status: { [Op.notIn]: ['cancelled', 'completed'] }
      },
      include: [
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name', 'phone']
        }
      ],
      order: [['created_at', 'DESC']],
      attributes: [
        'id', 'title', 'description', 'intervention_type', 'status', 
        'diagnostic_fee', 'diagnostic_paid', 'is_free_diagnosis',
        'created_at', 'equipment_count', 'address'
      ]
    });

    console.log(`✅ ${pendingPayments.length} intervention(s) avec diagnostic non payé`);

    res.status(200).json({
      success: true,
      data: pendingPayments,
      count: pendingPayments.length
    });
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des paiements en attente:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des paiements en attente',
      error: error.message
    });
  }
};

module.exports = {
  getAllInterventions,
  getInterventionById,
  createIntervention,
  updateIntervention,
  deleteIntervention,
  assignIntervention,
  acceptIntervention,
  markOnTheWay,
  markArrived,
  startIntervention,
  completeIntervention,
  submitReport,
  listReports,
  updateInterventionStatus,
  rateIntervention,
  getUnratedInterventions,
  getPendingDiagnosticPayments,
  suggestTechnicians,
  autoAssignIntervention,
  sendPaymentLink
};

// ==================== PLANIFICATION AUTOMATIQUE ====================

/**
 * @swagger
 * /api/interventions/{id}/suggest-technicians:
 *   post:
 *     summary: Suggérer les meilleurs techniciens pour une intervention
 *     tags: [Interventions]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               max_results:
 *                 type: integer
 *                 default: 5
 *               weights:
 *                 type: object
 *     responses:
 *       200:
 *         description: Suggestions générées avec succès
 */
async function suggestTechnicians(req, res) {
  try {
    const interventionId = parseInt(req.params.id);
    const { max_results, weights } = req.body;

    console.log(`🤖 Génération suggestions pour intervention ${interventionId}`);

    const result = await schedulingService.suggestTechnicians(interventionId, {
      max_results,
      weights
    });

    res.status(200).json({
      success: true,
      data: result,
      message: `${result.suggestions.length} technicien(s) suggéré(s)`
    });

  } catch (error) {
    console.error('❌ Erreur suggestTechnicians:', error);
    
    if (error.message === 'Intervention non trouvée') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    
    if (error.message === 'Intervention déjà assignée') {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération des suggestions'
    });
  }
}

/**
 * @swagger
 * /api/interventions/{id}/auto-assign:
 *   post:
 *     summary: Assigner automatiquement le meilleur technicien
 *     tags: [Interventions]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Assignation automatique réussie
 */
async function autoAssignIntervention(req, res) {
  try {
    const interventionId = parseInt(req.params.id);

    console.log(`🤖 Auto-assignation intervention ${interventionId}`);

    const result = await schedulingService.autoAssignIntervention(interventionId);

    // Récupérer l'intervention et le technicien complets pour notifications
    const intervention = await Intervention.findByPk(interventionId, {
      include: [
        { 
          model: CustomerProfile, 
          as: 'customer',
          include: [{
            model: User,
            as: 'user'
          }]
        },
        { model: User, as: 'technician' }
      ]
    });

    // Envoyer notifications
    await notifyInterventionAssigned(intervention, intervention.technician);

    res.status(200).json({
      success: true,
      data: result,
      message: `Intervention assignée automatiquement à ${result.assigned_technician.name}`
    });

  } catch (error) {
    console.error('❌ Erreur autoAssignIntervention:', error);
    
    if (error.message === 'Intervention non trouvée' || error.message === 'Aucun technicien disponible trouvé') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    
    if (error.message === 'Intervention déjà assignée') {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'assignation automatique'
    });
  }
}

// Envoyer un lien de paiement pour l'offre d'entretien
async function sendPaymentLink(req, res) {
  try {
    const interventionId = parseInt(req.params.id);

    console.log(`💳 Envoi du lien de paiement pour intervention ${interventionId}`);

    const intervention = await Intervention.findByPk(interventionId, {
      include: [
        { 
          model: CustomerProfile, 
          as: 'customer',
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone', 'first_name', 'last_name']
          }]
        },
        {
          model: MaintenanceOffer,
          as: 'maintenance_offer'
        },
        {
          model: RepairService,
          as: 'repair_service'
        },
        {
          model: InstallationService,
          as: 'installation_service'
        }
      ]
    });

    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    if (!intervention.maintenance_offer_id || !intervention.maintenance_offer) {
      return res.status(400).json({
        success: false,
        message: 'Cette intervention n\'a pas d\'offre d\'entretien associée'
      });
    }

    const customerId = intervention.customer?.user?.id || intervention.customer_id;
    
    // Vérifier si une souscription active existe déjà
    const existingSubscription = await Subscription.findOne({
      where: {
        customer_id: customerId,
        maintenance_offer_id: intervention.maintenance_offer_id,
        status: 'active',
        payment_status: 'paid',
        end_date: { [Op.gte]: new Date() }
      }
    });

    if (existingSubscription) {
      return res.status(400).json({
        success: false,
        message: 'Le client a déjà une souscription active pour cette offre'
      });
    }

    // Créer ou récupérer une souscription en attente
    let subscription = await Subscription.findOne({
      where: {
        customer_id: customerId,
        maintenance_offer_id: intervention.maintenance_offer_id,
        payment_status: 'pending'
      }
    });

    if (!subscription) {
      // Créer une nouvelle souscription en attente
      const startDate = new Date();
      const endDate = new Date();
      endDate.setMonth(endDate.getMonth() + (intervention.maintenance_offer.duration || 12));

      subscription = await Subscription.create({
        customer_id: customerId,
        maintenance_offer_id: intervention.maintenance_offer_id,
        status: 'active',
        start_date: startDate,
        end_date: endDate,
        price: intervention.maintenance_offer.price,
        payment_status: 'pending'
      });
    }

    // Générer le lien de paiement (conservé pour référence)
    const paymentLink = `${process.env.FRONTEND_URL || 'http://localhost:3001'}/payment/subscription/${subscription.id}`;

    // Envoyer une notification au client (sans le lien, le client paiera depuis l'app)
    const notificationMessage = `Votre offre d'entretien "${intervention.maintenance_offer.title}" est prête ! Montant: ${intervention.maintenance_offer.price} F CFA. Rendez-vous dans "Mes Interventions" pour procéder au paiement.`;
    
    await notificationService.create({
      userId: customerId,
      type: 'maintenance_offer_payment',
      title: 'Paiement en attente - Offre d\'entretien',
      message: notificationMessage,
      data: {
        subscription_id: subscription.id,
        offer_id: intervention.maintenance_offer_id,
        intervention_id: interventionId
      },
      priority: 'high'
    });

    // Envoyer par email si disponible
    if (intervention.customer?.user?.email) {
      try {
        await sendEmail({
          to: intervention.customer.user.email,
          subject: `Lien de paiement - ${intervention.maintenance_offer.title}`,
          html: `
            <h2>Bonjour ${intervention.customer.user.first_name},</h2>
            <p>Votre offre d'entretien <strong>${intervention.maintenance_offer.title}</strong> est prête !</p>
            <p>Montant: <strong>${intervention.maintenance_offer.price} F CFA</strong></p>
            <p>Cliquez sur le lien ci-dessous pour procéder au paiement:</p>
            <p><a href="${paymentLink}" style="background-color: #52c41a; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Payer maintenant</a></p>
            <p>Cordialement,<br>L'équipe MCT Maintenance</p>
          `
        });
      } catch (emailError) {
        console.error('❌ Erreur envoi email:', emailError);
      }
    }

    res.status(200).json({
      success: true,
      message: 'Lien de paiement envoyé au client',
      data: {
        subscription_id: subscription.id,
        payment_link: paymentLink
      }
    });

  } catch (error) {
    console.error('❌ Erreur sendPaymentLink:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi du lien de paiement',
      error: error.message
    });
  }
}
