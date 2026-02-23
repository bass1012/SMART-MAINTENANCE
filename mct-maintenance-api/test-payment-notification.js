const { Notification, User } = require('./src/models');
const notificationService = require('./src/services/notificationService');

async function testPaymentNotification() {
  try {
    // Utilisateur 26 (bassirou.ouedraogo@mct.ci)
    const userId = 26;
    
    console.log('🧪 Test d\'envoi notification de paiement...\n');
    
    // Vérifier le token FCM de l'utilisateur
    const user = await User.findByPk(userId, { attributes: ['id', 'email', 'fcm_token'] });
    console.log('👤 Utilisateur:', user.email);
    console.log('📱 Token FCM:', user.fcm_token ? `${user.fcm_token.substring(0, 30)}...` : 'AUCUN');
    console.log('');
    
    // Créer une notification de paiement
    const notification = await notificationService.create({
      userId: userId,
      type: 'payment_confirmed',
      title: 'Test - Paiement confirmé',
      message: 'Ceci est un test de notification push pour paiement confirmé',
      priority: 'high',
      actionUrl: '/commandes/test',
      data: {
        orderId: 999,
        orderReference: 'CMD-TEST',
        paymentStatus: 'paid',
        amount: 100000
      }
    });
    
    console.log('\n✅ Notification créée avec ID:', notification.id);
    console.log('Vérifiez votre téléphone pour la notification push!');
    
    // Attendre 2 secondes pour voir les logs
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

testPaymentNotification();
