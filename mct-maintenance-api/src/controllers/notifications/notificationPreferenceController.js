const NotificationPreference = require('../../models/NotificationPreference');
const User = require('../../models/User');

/**
 * Récupérer les préférences de notifications d'un utilisateur
 */
exports.getPreferences = async (req, res) => {
  try {
    console.log('📋 getPreferences - req.user:', req.user);
    const userId = req.user.id;
    console.log('👤 userId:', userId);
    
    let preferences = await NotificationPreference.findOne({
      where: { user_id: userId }
    });
    console.log('🔍 preferences trouvées:', preferences ? 'OUI' : 'NON');
    
    // Créer des préférences par défaut si elles n'existent pas
    if (!preferences) {
      console.log('📝 Création préférences par défaut...');
      preferences = await NotificationPreference.create({
        user_id: userId
      });
      console.log('✅ Préférences créées:', preferences.id);
    }
    
    res.json({
      success: true,
      data: preferences
    });
  } catch (error) {
    console.error('❌ Erreur récupération préférences:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des préférences'
    });
  }
};

/**
 * Mettre à jour les préférences de notifications
 */
exports.updatePreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    const updates = req.body;
    
    // Vérifier si les préférences existent
    let preferences = await NotificationPreference.findOne({
      where: { user_id: userId }
    });
    
    if (!preferences) {
      // Créer les préférences avec les valeurs fournies
      preferences = await NotificationPreference.create({
        user_id: userId,
        ...updates
      });
    } else {
      // Mettre à jour les préférences existantes
      await preferences.update(updates);
    }
    
    res.json({
      success: true,
      message: 'Préférences mises à jour avec succès',
      data: preferences
    });
  } catch (error) {
    console.error('Erreur mise à jour préférences:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour des préférences'
    });
  }
};

/**
 * Réinitialiser les préférences aux valeurs par défaut
 */
exports.resetPreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    
    await NotificationPreference.destroy({
      where: { user_id: userId }
    });
    
    const preferences = await NotificationPreference.create({
      user_id: userId
    });
    
    res.json({
      success: true,
      message: 'Préférences réinitialisées aux valeurs par défaut',
      data: preferences
    });
  } catch (error) {
    console.error('Erreur réinitialisation préférences:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la réinitialisation des préférences'
    });
  }
};

/**
 * Activer/Désactiver toutes les notifications email
 */
exports.toggleEmail = async (req, res) => {
  try {
    const userId = req.user.id;
    const { enabled } = req.body;
    
    let preferences = await NotificationPreference.findOne({
      where: { user_id: userId }
    });
    
    if (!preferences) {
      preferences = await NotificationPreference.create({
        user_id: userId,
        email_enabled: enabled
      });
    } else {
      await preferences.update({ email_enabled: enabled });
    }
    
    res.json({
      success: true,
      message: `Notifications email ${enabled ? 'activées' : 'désactivées'}`,
      data: { email_enabled: enabled }
    });
  } catch (error) {
    console.error('Erreur toggle email:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la modification'
    });
  }
};

/**
 * Activer/Désactiver toutes les notifications push
 */
exports.togglePush = async (req, res) => {
  try {
    const userId = req.user.id;
    const { enabled } = req.body;
    
    let preferences = await NotificationPreference.findOne({
      where: { user_id: userId }
    });
    
    if (!preferences) {
      preferences = await NotificationPreference.create({
        user_id: userId,
        push_enabled: enabled
      });
    } else {
      await preferences.update({ push_enabled: enabled });
    }
    
    res.json({
      success: true,
      message: `Notifications push ${enabled ? 'activées' : 'désactivées'}`,
      data: { push_enabled: enabled }
    });
  } catch (error) {
    console.error('Erreur toggle push:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la modification'
    });
  }
};

/**
 * Configurer les heures de silence
 */
exports.setQuietHours = async (req, res) => {
  try {
    const userId = req.user.id;
    const { enabled, start, end } = req.body;
    
    let preferences = await NotificationPreference.findOne({
      where: { user_id: userId }
    });
    
    const updates = {
      quiet_hours_enabled: enabled,
      quiet_hours_start: start || null,
      quiet_hours_end: end || null
    };
    
    if (!preferences) {
      preferences = await NotificationPreference.create({
        user_id: userId,
        ...updates
      });
    } else {
      await preferences.update(updates);
    }
    
    res.json({
      success: true,
      message: 'Heures de silence configurées',
      data: updates
    });
  } catch (error) {
    console.error('Erreur configuration heures de silence:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la configuration'
    });
  }
};

module.exports = exports;
