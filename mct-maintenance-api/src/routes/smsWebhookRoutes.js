const express = require('express');
const router = express.Router();

/**
 * Routes pour les webhooks HSMS.ci
 * Ces URLs sont à configurer dans le back-office HSMS.ci
 */

/**
 * Webhook de notification SMS
 * Appelé par HSMS.ci pour notifier du statut d'envoi des SMS
 * 
 * URL à configurer dans HSMS.ci: 
 * http://votre-domaine.com/api/sms/notification
 * ou en dev: http://192.168.1.139:3000/api/sms/notification
 */
router.post('/notification', async (req, res) => {
  try {
    console.log('📬 Notification HSMS.ci reçue:', req.body);

    const {
      message_id,      // ID du message
      recipient,       // Numéro destinataire
      status,          // Status: delivered, failed, pending
      delivery_time,   // Heure de livraison
      error_code,      // Code erreur si échec
      error_message    // Message d'erreur si échec
    } = req.body;

    // Logger les informations
    if (status === 'delivered') {
      console.log(`✅ SMS ${message_id} livré à ${recipient} à ${delivery_time}`);
    } else if (status === 'failed') {
      console.error(`❌ SMS ${message_id} échoué pour ${recipient}:`, error_message);
      console.error(`   Code erreur: ${error_code}`);
    } else {
      console.log(`⏳ SMS ${message_id} en attente pour ${recipient}`);
    }

    // TODO: Sauvegarder dans la base de données pour tracking
    // Exemple:
    // await SMSLog.create({
    //   message_id,
    //   recipient,
    //   status,
    //   delivery_time,
    //   error_code,
    //   error_message
    // });

    // Répondre à HSMS.ci
    res.json({
      success: true,
      message: 'Notification reçue'
    });

  } catch (error) {
    console.error('❌ Erreur traitement notification HSMS:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

/**
 * Webhook de désabonnement (STOP)
 * Appelé quand un utilisateur répond "STOP" à un SMS
 * 
 * URL à configurer dans HSMS.ci:
 * http://votre-domaine.com/api/sms/stop
 * ou en dev: http://192.168.1.139:3000/api/sms/stop
 */
router.post('/stop', async (req, res) => {
  try {
    console.log('🛑 Demande de désabonnement HSMS.ci:', req.body);

    const {
      phone_number,    // Numéro qui veut se désabonner
      message,         // Message reçu (généralement "STOP")
      timestamp        // Horodatage
    } = req.body;

    console.log(`🛑 Désabonnement demandé par ${phone_number}`);

    // TODO: Marquer l'utilisateur comme désabonné dans la BDD
    // Exemple:
    // const user = await User.findOne({ where: { phone: phone_number }});
    // if (user) {
    //   await user.update({ sms_opt_out: true });
    //   console.log(`✅ Utilisateur ${user.email} désabonné des SMS`);
    // }

    // Répondre à HSMS.ci
    res.json({
      success: true,
      message: 'Désabonnement enregistré'
    });

  } catch (error) {
    console.error('❌ Erreur traitement désabonnement:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

/**
 * Route de test pour vérifier que les webhooks fonctionnent
 * GET /api/sms/test
 */
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Webhooks HSMS.ci opérationnels',
    endpoints: {
      notification: `${process.env.BACKEND_URL}/api/sms/notification`,
      stop: `${process.env.BACKEND_URL}/api/sms/stop`
    }
  });
});

module.exports = router;
