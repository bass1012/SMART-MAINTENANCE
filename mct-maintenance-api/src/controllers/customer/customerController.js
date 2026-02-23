// Customer Controller - Implementation with basic REST handlers
const { CustomerProfile, User } = require('../../models');
const { deleteCustomerCompletely, softDeleteCustomer } = require('../../services/customerDeletionService');
const bcrypt = require('bcryptjs');

const getCustomerProfile = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get customer profile - To be implemented',
    data: {}
  });
};

const updateCustomerProfile = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Update customer profile - To be implemented',
    data: {}
  });
};

const getCustomerInterventions = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get customer interventions - To be implemented',
    data: []
  });
};

const getCustomerContracts = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get customer contracts - To be implemented',
    data: []
  });
};

const getCustomerQuotes = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get customer quotes - To be implemented',
    data: []
  });
};

// === API REST pour gestion des clients ===

// Liste paginée des clients
const listCustomers = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const { User } = require('../../models');
    const { count, rows } = await CustomerProfile.findAndCountAll({
      limit,
      offset,
      order: [['createdAt', 'DESC']],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'phone', 'role', 'status']
        }
      ]
    });
    // Adapter la structure pour exposer email, phone, entreprise, date maj
    const customers = rows.map(profile => {
      const user = profile.user || {};
      return {
        id: profile.id,
        user_id: profile.user_id, // ✅ Ajout du user_id pour les foreign keys
        first_name: profile.first_name,
        last_name: profile.last_name,
        email: user.email || '',
        phone: user.phone || '',
        company: profile.company_name || '',
        updated_at: profile.updatedAt,
        created_at: profile.createdAt,
        status: user.status || 'actif',
        city: profile.city || '',
        commune: profile.commune || '',
        address: profile.address || '',
        latitude: profile.latitude !== undefined && profile.latitude !== null ? Number(profile.latitude) : null,
        longitude: profile.longitude !== undefined && profile.longitude !== null ? Number(profile.longitude) : null
      };
    });
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
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur lors du chargement des clients', error: err.message });
  }
};

// Détail d'un client
const getCustomer = async (req, res) => {
  try {
    const customer = await CustomerProfile.findByPk(req.params.id);
    if (!customer) return res.status(404).json({ success: false, message: 'Client non trouvé' });
    // Récupérer l'utilisateur lié manuellement
    console.log('[DEBUG] customer.user_id =', customer.user_id);
    const user = await User.findByPk(customer.user_id, {
      attributes: ['id', 'email', 'phone', 'role', 'status']
    });
    console.log('[DEBUG] user trouvé =', user ? user.toJSON() : null);
    const data = customer.toJSON();
    data.user = user ? user.toJSON() : null;
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur lors du chargement du client', error: err.message });
  }
};

// Création d'un client
const createCustomer = async (req, res) => {
  try {
    const { 
      first_name, 
      last_name, 
      email,
      phone,
      company_name, 
      city, 
      commune, 
      latitude, 
      longitude, 
      country, 
      company_type, 
      gender 
    } = req.body;

    // Générer un email par défaut si non fourni
    const userEmail = email || `${first_name?.toLowerCase() || 'client'}.${last_name?.toLowerCase() || Date.now()}@client.local`;

    // Créer d'abord l'utilisateur
    const user = await User.create({
      email: userEmail,
      first_name,
      last_name,
      phone,
      password_hash: await bcrypt.hash('defaultpassword123', 10), // Mot de passe par défaut
      role: 'customer',
      status: 'active'
    });

    // Puis créer le profil client
    const customer = await CustomerProfile.create({
      user_id: user.id,
      first_name,
      last_name,
      company_name,
      city,
      commune,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      country: country || 'Côte d\'Ivoire',
      company_type,
      gender
    });

    // Retourner le client avec les données utilisateur
    const customerWithUser = await CustomerProfile.findByPk(customer.id, {
      include: [{ model: User, as: 'user' }]
    });

    res.status(201).json({ 
      success: true, 
      data: customerWithUser 
    });
  } catch (err) {
    console.error('Erreur lors de la création du client:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la création du client', 
      error: err.message 
    });
  }
};
// Mise à jour d'un client
const updateCustomer = async (req, res) => {
  try {
    const customer = await CustomerProfile.findByPk(req.params.id, {
      include: [{ model: User, as: 'user' }]
    });
    if (!customer) return res.status(404).json({ success: false, message: 'Client non trouvé' });
    
    // Champs autorisés à la modification pour CustomerProfile
    const customerFields = [
      'first_name', 'last_name', 'company_name', 'city', 'commune', 'latitude', 'longitude', 'country', 'company_type', 'gender'
    ];
    
    // Mettre à jour les champs du CustomerProfile
    customerFields.forEach(field => {
      if (req.body[field] !== undefined) customer[field] = req.body[field];
    });
    
    // Mettre à jour le statut dans la table User si fourni
    if (req.body.status !== undefined && customer.user) {
      customer.user.status = req.body.status;
      await customer.user.save();
    }
    
    await customer.save();
    
    // Retourner le client avec les données utilisateur mises à jour
    const updatedCustomer = await CustomerProfile.findByPk(customer.id, {
      include: [{ model: User, as: 'user' }]
    });
    
    res.json({ success: true, data: updatedCustomer });
  } catch (err) {
    console.error('Erreur lors de la mise à jour du client:', err);
    res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour du client', error: err.message });
  }
};
// Suppression d'un client
/**
 * Supprimer un client COMPLÈTEMENT (hard delete)
 * Supprime le client et TOUTES ses données associées
 */
const deleteCustomer = async (req, res) => {
  try {
    const customerId = parseInt(req.params.id);
    
    if (!customerId) {
      return res.status(400).json({ 
        success: false, 
        message: 'ID client invalide' 
      });
    }

    // Utiliser le service de suppression complète
    const result = await deleteCustomerCompletely(customerId);

    res.status(200).json({
      success: true,
      message: result.message,
      data: {
        deletedItems: result.deletedItems
      }
    });

  } catch (error) {
    console.error('❌ Erreur lors de la suppression du client:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Erreur lors de la suppression du client', 
      error: error.message 
    });
  }
};

/**
 * Désactiver un client (soft delete)
 * Le compte est désactivé mais les données sont conservées
 */
const deactivateCustomer = async (req, res) => {
  try {
    const customerId = parseInt(req.params.id);
    
    if (!customerId) {
      return res.status(400).json({ 
        success: false, 
        message: 'ID client invalide' 
      });
    }

    // Utiliser le service de soft delete
    const result = await softDeleteCustomer(customerId);

    res.status(200).json({
      success: true,
      message: result.message,
      data: {
        user: result.user
      }
    });

  } catch (error) {
    console.error('❌ Erreur lors de la désactivation du client:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Erreur lors de la désactivation du client', 
      error: error.message 
    });
  }
};

// Supprimer définitivement tous les clients marqués comme "deleted"
const purgeDeletedCustomers = async (req, res) => {
  try {
    const { User, CustomerProfile } = require('../../models');
    const { Op } = require('sequelize');

    // Trouver tous les utilisateurs avec email commençant par "deleted_"
    const deletedUsers = await User.findAll({
      where: {
        email: {
          [Op.like]: 'deleted_%'
        }
      },
      attributes: ['id', 'email', 'first_name', 'last_name']
    });

    if (deletedUsers.length === 0) {
      return res.json({
        success: true,
        message: 'Aucun client supprimé à purger',
        count: 0
      });
    }

    console.log(`🗑️ [Purge] ${deletedUsers.length} client(s) marqué(s) comme supprimé(s) trouvé(s)`);

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    // Supprimer chaque client définitivement
    for (const user of deletedUsers) {
      try {
        const result = await deleteCustomerCompletely(user.id);
        console.log(`✅ Client ${user.id} (${user.email}) purgé avec succès`);
        successCount++;
      } catch (error) {
        console.error(`❌ Erreur purge client ${user.id}:`, error.message);
        errorCount++;
        errors.push({
          userId: user.id,
          email: user.email,
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      message: `Purge terminée: ${successCount} supprimé(s), ${errorCount} erreur(s)`,
      total: deletedUsers.length,
      successCount,
      errorCount,
      errors: errors.length > 0 ? errors : undefined
    });

  } catch (error) {
    console.error('❌ Erreur lors de la purge des clients supprimés:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la purge des clients supprimés',
      error: error.message
    });
  }
};

module.exports = {
  getCustomerProfile,
  updateCustomerProfile,
  getCustomerInterventions,
  getCustomerContracts,
  getCustomerQuotes,
  listCustomers,
  getCustomer,
  createCustomer,
  updateCustomer,
  deleteCustomer,
  deactivateCustomer,
  purgeDeletedCustomers
};
