// Contrôleur pour la gestion des clients
const { CustomerProfile } = require('../models');
const { Op } = require('sequelize');

exports.listCustomers = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const search = req.query.search || '';
    const offset = (page - 1) * limit;

    // Filtrer par recherche si besoin
    const where = search
      ? { name: { [Op.like]: `%${search}%` } }
      : {};

  const { rows, count } = await CustomerProfile.findAndCountAll({
      where,
      offset,
      limit,
      order: [['createdAt', 'DESC']],
      include: [
        {
          model: require('../models').User,
          as: 'user',
          attributes: ['email', 'phone']
        }
      ]
    });

    res.json({
      success: true,
      data: {
        customers: rows,
        total: count,
        page,
        limit
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur serveur', error: error.message });
  }
};

exports.getCustomer = async (req, res) => {
  try {
  const customer = await CustomerProfile.findByPk(req.params.id, { include: ['user'] });
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Client non trouvé' });
    }
    res.json({ success: true, data: customer });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur serveur', error: error.message });
  }
};

exports.createCustomer = async (req, res) => {
  res.status(501).json({ success: false, message: 'Not implemented' });
};

exports.updateCustomer = async (req, res) => {
  try {
    const customerId = req.params.id;
    const updateData = req.body;
    const { User } = require('../models');
    const customer = await CustomerProfile.findByPk(customerId, { include: ['user'] });
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Client non trouvé' });
    }
    // Mise à jour du profil client
    await customer.update(updateData);
    // Mise à jour du mail et téléphone si présents dans le body
    if (updateData.email || updateData.phone) {
      const userUpdate = {};
      if (updateData.email) userUpdate.email = updateData.email;
      if (updateData.phone) userUpdate.phone = updateData.phone;
      if (Object.keys(userUpdate).length > 0 && customer.user) {
        await customer.user.update(userUpdate);
      }
    }
    // Recharger le client avec l'utilisateur mis à jour
    const updatedCustomer = await CustomerProfile.findByPk(customerId, { include: [{ model: User, as: 'user', attributes: ['email', 'phone'] }] });
    return res.json({ success: true, message: 'Client mis à jour', customer: updatedCustomer });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du client:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors de la sauvegarde du client', error: error.message });
  }
}

exports.deleteCustomer = async (req, res) => {
  try {
    const customerId = req.params.id;
    const { User } = require('../models');
    const customer = await CustomerProfile.findByPk(customerId);
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Client non trouvé' });
    }
    // Récupérer l'utilisateur associé
    const user = await User.findByPk(customer.user_id);
    // Supprimer le profil client
    await customer.destroy();
    // Supprimer l'utilisateur associé si trouvé
    if (user) {
      await user.destroy();
    }
    return res.json({ success: true, message: 'Client et utilisateur supprimés' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Erreur serveur', error: error.message });
  }
};
