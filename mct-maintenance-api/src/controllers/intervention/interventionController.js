const { MaintenanceSchedule, User, Intervention, CustomerProfile, Equipment, InterventionImage } = require('../../models');
const { Op } = require('sequelize');
const { 
  notifyNewIntervention,
  notifyInterventionAssigned,
  notifyTechnicianAssignedToCustomer,
  notifyInterventionCompleted,
  notifyInterventionUpdated
} = require('../../services/notificationHelpers');
const notificationService = require('../../services/notificationService');
const upload = require('../../config/multer');

// Intervention Controller - Implementation complète
const getAllInterventions = async (req, res) => {
  try {
    const { status, priority, customer_id, technician_id, page = 1, limit = 10 } = req.query;
    
    const where = {};
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (customer_id) where.customer_id = customer_id;
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
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name', 'email'],
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

    const interventions = result.rows.map(intervention => {
      const plain = intervention.get({ plain: true });
      console.log('🔍 Intervention brute:', JSON.stringify(plain, null, 2));
      // On enrichit le customer avec les infos du profil
      let customer = null;
      if (plain.customer) {
        customer = {
          id: plain.customer.id,
          email: plain.customer.email,
          first_name: plain.customer.customerProfile ? plain.customer.customerProfile.first_name : null,
          last_name: plain.customer.customerProfile ? plain.customer.customerProfile.last_name : null
        };
        console.log('✅ Customer enrichi:', customer);
      } else {
        console.log('❌ Pas de customer trouvé pour intervention ID:', plain.id);
      }
      return {
        ...plain,
        customer,
        technician: plain.technician || null
      };
    });

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
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] },
        { model: User, as: 'technician', attributes: ['id', 'first_name', 'last_name', 'email'], required: false }
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

      // 💰 Calcul du coût du diagnostic
      // Si le client a un contrat d'entretien actif, le diagnostic est gratuit
      // Sinon, le diagnostic coûte 4000 FCFA
      let diagnosticFee = 4000.00;
      let isFreeDiagnosis = false;

      if (interventionData.contract_id) {
        // Client avec contrat d'entretien = diagnostic gratuit
        diagnosticFee = 0.00;
        isFreeDiagnosis = true;
        console.log('✅ Client avec contrat d\'entretien → Diagnostic GRATUIT');
      } else {
        // Client sans contrat = diagnostic payant
        console.log('💵 Client sans contrat → Diagnostic payant: 4000 FCFA');
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
          id: createdIntervention.customer.id,
          email: createdIntervention.customer.email,
          first_name: createdIntervention.customer.customerProfile?.first_name || '',
          last_name: createdIntervention.customer.customerProfile?.last_name || ''
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
        console.error('❌ Erreur notification:', notifError);
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
            id: updatedIntervention.customer.id,
            email: updatedIntervention.customer.email,
            first_name: updatedIntervention.customer.customerProfile?.first_name || '',
            last_name: updatedIntervention.customer.customerProfile?.last_name || ''
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
  try {
    const { id } = req.params;

    const intervention = await Intervention.findByPk(id);
    
    if (!intervention) {
      return res.status(404).json({
        success: false,
        message: 'Intervention non trouvée'
      });
    }

    await intervention.destroy();

    res.status(200).json({
      success: true,
      message: 'Intervention supprimée avec succès'
    });
  } catch (error) {
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

    // Assigner le technicien
    await intervention.update({ 
      technician_id,
      status: 'assigned' // Changer le statut en "assigned"
    });

    // Récupérer l'intervention mise à jour avec les relations
    const updatedIntervention = await Intervention.findByPk(id, {
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
        // Enrichir le customer avec les données du profil
        const customer = {
          id: updatedIntervention.customer.id,
          email: updatedIntervention.customer.email,
          first_name: updatedIntervention.customer.customerProfile?.first_name || '',
          last_name: updatedIntervention.customer.customerProfile?.last_name || ''
        };
        
        console.log(`📤 Envoi notification assignation au client user_id: ${customer.id}`);
        console.log(`👤 Client: ${customer.first_name} ${customer.last_name}`);
        await notifyTechnicianAssignedToCustomer(updatedIntervention, customer, technician);
        console.log('✅ Notification envoyée au client pour l\'assignation du technicien');
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
      where: { id, technician_id: technicianId }
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
      where: { id, technician_id: technicianId }
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
    
    if (intervention.status !== 'arrived') {
      return res.status(400).json({
        success: false,
        message: 'Vous devez d\'abord signaler votre arrivée'
      });
    }
    
    await intervention.update({
      status: 'in_progress',
      started_at: new Date()
    });
    
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
    
    // TODO: Notifier le client que l'intervention est terminée
    
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
          { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] },
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

    const intervention = await Intervention.findByPk(id);
    if (!intervention) {
      return res.status(404).json({ success: false, message: 'Intervention non trouvée' });
    }

    await intervention.update({ status });

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
    const customerId = req.user.id;

    console.log('⭐ Évaluation intervention:', { id, customerId, rating, review });

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
          actionUrl: `/interventions/${fullIntervention.id}`
        });
      }
      console.log(`📧 Notifications envoyées à ${admins.length} admin(s)`);
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
  rateIntervention
};
