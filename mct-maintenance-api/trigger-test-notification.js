// Script pour déclencher une notification de test
const notificationService = require('./src/services/notificationService');

async function triggerTestNotification() {
  try {
    console.log('🧪 Déclenchement d\'une notification de test...\n');

    // Attendre 2 secondes pour laisser le temps de se connecter
    console.log('⏳ Attente de 5 secondes pour vous laisser vous connecter...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    console.log('\n📤 Envoi de la notification de test à l\'admin (user 6)...\n');

    // Créer une notification de test
    await notificationService.create({
      userId: 6,
      type: 'general',
      title: '🧪 Test de notification en temps réel',
      message: 'Si vous voyez ce message, Socket.IO fonctionne parfaitement !',
      data: { test: true, timestamp: new Date().toISOString() },
      priority: 'high',
      actionUrl: '/dashboard'
    });

    console.log('✅ Notification de test envoyée !');
    console.log('');
    console.log('👀 Vérifiez:');
    console.log('   - La page de test (test-socketio.html)');
    console.log('   - Le dashboard web (http://localhost:3001)');
    console.log('');

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
  
  process.exit(0);
}

triggerTestNotification();
