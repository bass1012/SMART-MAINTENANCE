const RepairService = require('../models/RepairService');

// Récupérer tous les services de réparation
exports.getAllRepairServices = async (req, res) => {
  try {
    const services = await RepairService.findAll({
      order: [['created_at', 'DESC']]
    });
    res.json(services);
  } catch (error) {
    console.error('Erreur lors de la récupération des services:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Récupérer les services actifs
exports.getActiveRepairServices = async (req, res) => {
  try {
    const services = await RepairService.findAll({
      where: { isActive: true },
      order: [['created_at', 'DESC']]
    });
    res.json(services);
  } catch (error) {
    console.error('Erreur lors de la récupération des services:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Récupérer un service par ID
exports.getRepairServiceById = async (req, res) => {
  try {
    const service = await RepairService.findByPk(req.params.id);
    if (!service) {
      return res.status(404).json({ message: 'Service non trouvé' });
    }
    res.json(service);
  } catch (error) {
    console.error('Erreur lors de la récupération du service:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Créer un nouveau service
exports.createRepairService = async (req, res) => {
  try {
    const { title, model, price, description, duration, isActive } = req.body;

    if (!title || !model || !price) {
      return res.status(400).json({ 
        message: 'Titre, modèle et prix sont obligatoires' 
      });
    }

    const service = await RepairService.create({
      title,
      model,
      price,
      description,
      duration,
      isActive: isActive !== undefined ? isActive : true
    });

    res.status(201).json(service);
  } catch (error) {
    console.error('Erreur lors de la création du service:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Mettre à jour un service
exports.updateRepairService = async (req, res) => {
  try {
    const service = await RepairService.findByPk(req.params.id);
    if (!service) {
      return res.status(404).json({ message: 'Service non trouvé' });
    }

    const { title, model, price, description, duration, isActive } = req.body;

    await service.update({
      title: title !== undefined ? title : service.title,
      model: model !== undefined ? model : service.model,
      price: price !== undefined ? price : service.price,
      description: description !== undefined ? description : service.description,
      duration: duration !== undefined ? duration : service.duration,
      isActive: isActive !== undefined ? isActive : service.isActive
    });

    res.json(service);
  } catch (error) {
    console.error('Erreur lors de la mise à jour du service:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Supprimer un service
exports.deleteRepairService = async (req, res) => {
  try {
    const service = await RepairService.findByPk(req.params.id);
    if (!service) {
      return res.status(404).json({ message: 'Service non trouvé' });
    }

    await service.destroy();
    res.json({ message: 'Service supprimé avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression du service:', error);
    
    // Si le service est référencé par des souscriptions/interventions, le désactiver au lieu de le supprimer
    if (error.name === 'SequelizeForeignKeyConstraintError') {
      try {
        const service = await RepairService.findByPk(req.params.id);
        if (service) {
          await service.update({ isActive: false });
          return res.json({ 
            message: 'Ce service est utilisé par des souscriptions ou interventions. Il a été désactivé au lieu d\'être supprimé.',
            softDeleted: true
          });
        }
      } catch (softDeleteError) {
        console.error('Erreur lors de la désactivation du service:', softDeleteError);
      }
    }
    
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Activer/désactiver un service
exports.toggleRepairServiceStatus = async (req, res) => {
  try {
    const service = await RepairService.findByPk(req.params.id);
    if (!service) {
      return res.status(404).json({ message: 'Service non trouvé' });
    }

    await service.update({ isActive: !service.isActive });
    res.json(service);
  } catch (error) {
    console.error('Erreur lors du changement de statut:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
