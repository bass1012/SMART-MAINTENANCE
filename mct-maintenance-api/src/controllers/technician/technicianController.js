// Technician Controller
const { User, TechnicianProfile } = require('../../models');

const getTechnicianProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findByPk(userId, {
      attributes: [
        'id', 
        'email', 
        'first_name', 
        'last_name', 
        'phone', 
        'profile_image', 
        'status',
        'availability_status' // Ajout du champ availability_status
      ]
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Essayer de récupérer le profil technicien séparément
    let techProfile = null;
    try {
      techProfile = await TechnicianProfile.findOne({
        where: { user_id: userId }
      });
    } catch (err) {
      console.log('⚠️ TechnicianProfile non disponible:', err.message);
    }

    res.status(200).json({
      success: true,
      message: 'Profil technicien récupéré avec succès',
      data: {
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          phone: user.phone,
          profile_image: user.profile_image,
          status: user.status,
          availability_status: user.availability_status || 'available'
        },
        profile: techProfile || {}
      }
    });
  } catch (error) {
    console.error('❌ Erreur getTechnicianProfile:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération du profil',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

const updateTechnicianProfile = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Update technician profile - To be implemented',
    data: {}
  });
};

const getTechnicianInterventions = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get technician interventions - To be implemented',
    data: []
  });
};

const getAvailableInterventions = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get available interventions - To be implemented',
    data: []
  });
};

const updateAvailability = async (req, res) => {
  try {
    const { availability_status } = req.body;
    const userId = req.user.id;

    // Valider le statut
    const validStatuses = ['available', 'busy', 'offline'];
    if (!availability_status || !validStatuses.includes(availability_status)) {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide. Valeurs acceptées: available, busy, offline'
      });
    }

    // Mettre à jour le profil technicien
    const [updatedCount] = await TechnicianProfile.update(
      { availability_status },
      { where: { user_id: userId } }
    );

    if (updatedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Profil technicien non trouvé'
      });
    }

    console.log(`✅ Disponibilité technicien ${userId} mise à jour: ${availability_status}`);

    // Emettre l'événement Socket.io pour la mise à jour en temps réel
    const notificationService = require('../../services/notificationService');
    if (notificationService.io) {
      notificationService.io.emit('technician_status_changed', {
        user_id: userId,
        availability_status
      });
    }

    res.status(200).json({
      success: true,
      message: 'Disponibilité mise à jour avec succès',
      data: { availability_status }
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour disponibilité:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour'
    });
  }
};

const updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const userId = req.user.id;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude et longitude sont requises'
      });
    }

    const [updatedCount] = await TechnicianProfile.update(
      { 
        current_location_lat: latitude,
        current_location_lng: longitude,
        last_location_update: new Date()
      },
      { where: { user_id: userId } }
    );

    if (updatedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Profil technicien non trouvé'
      });
    }

    // Emettre l'événement Socket.io
    const notificationService = require('../../services/notificationService');
    if (notificationService.io) {
      notificationService.io.emit('technician_moved', {
        user_id: userId,
        latitude,
        longitude,
        last_location_update: new Date()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Location updated successfully'
    });
  } catch (error) {
    console.error('❌ Erreur updateLocation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour de la localisation'
    });
  }
};

const getAllTechnicianLocations = async (req, res) => {
  try {
    const technicians = await User.findAll({
      where: { role: 'technician', status: 'active' },
      attributes: ['id', 'first_name', 'last_name', 'profile_image'],
      include: [{
        model: TechnicianProfile,
        as: 'technicianProfile',
        attributes: ['current_location_lat', 'current_location_lng', 'last_location_update', 'availability_status']
      }]
    });

    const locations = technicians
      .filter(t => t.technicianProfile && t.technicianProfile.current_location_lat)
      .map(t => ({
        user_id: t.id,
        first_name: t.first_name,
        last_name: t.last_name,
        profile_image: t.profile_image,
        latitude: t.technicianProfile.current_location_lat,
        longitude: t.technicianProfile.current_location_lng,
        last_location_update: t.technicianProfile.last_location_update,
        availability_status: t.technicianProfile.availability_status
      }));

    res.status(200).json({
      success: true,
      data: locations
    });
  } catch (error) {
    console.error('❌ Erreur getAllTechnicianLocations:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des localisations'
    });
  }
};

module.exports = {
  getTechnicianProfile,
  updateTechnicianProfile,
  getTechnicianInterventions,
  getAvailableInterventions,
  updateAvailability,
  updateLocation,
  getAllTechnicianLocations
};
