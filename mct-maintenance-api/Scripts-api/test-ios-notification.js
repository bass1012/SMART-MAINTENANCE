const admin = require('firebase-admin');
const path = require('path');

// Initialiser Firebase Admin
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

console.log('✅ Firebase Admin initialisé');
console.log(`   Project ID: ${serviceAccount.project_id}`);

// Token FCM de l'utilisateur iOS (user_id = 14)
const fcmToken = 'cv4aheaESSKXzoGOOqmZgO:APA91bEfbdH3UVrOrXKUKdv7uAbDa1TWsumlc5baAfsf4Lfc1k2HqXIweNXdkhBx0gBupm4YjIiDD3fRvKr1wGWs6TOsiZdCgdw8faYUA6zRiRwy0_SCH8w';

// Message de test
const message = {
  token: fcmToken,
  notification: {
    title: '🔔 Test iOS Notification',
    body: 'Si vous recevez ceci, les notifications iOS fonctionnent !'
  },
  data: {
    type: 'test',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    test_id: Date.now().toString()
  },
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1,
        alert: {
          title: '🔔 Test iOS Notification',
          body: 'Si vous recevez ceci, les notifications iOS fonctionnent !'
        }
      }
    },
    headers: {
      'apns-priority': '10'
    }
  },
  android: {
    priority: 'high',
    notification: {
      sound: 'default',
      color: '#0a543d'
    }
  }
};

console.log('\n📤 Envoi de la notification de test...');
console.log(`   Token: ${fcmToken.substring(0, 30)}...`);

admin.messaging().send(message)
  .then((response) => {
    console.log('\n✅ SUCCÈS ! Notification envoyée');
    console.log(`   Message ID: ${response}`);
    console.log('\n🎉 Vérifiez votre iPhone maintenant !');
    console.log('   - App ouverte : popup en haut');
    console.log('   - App fermée : bannière sur l\'écran d\'accueil');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ ERREUR lors de l\'envoi:');
    console.error(`   Code: ${error.code}`);
    console.error(`   Message: ${error.message}`);
    
    if (error.code === 'messaging/invalid-apns-credentials') {
      console.error('\n🔧 PROBLÈME: Clé APNs invalide ou mal configurée');
      console.error('   Solutions:');
      console.error('   1. Vérifier que la clé .p8 est bien uploadée dans Firebase');
      console.error('   2. Vérifier le Key ID et Team ID');
      console.error('   3. Vérifier que le Bundle ID correspond: com.bassoued.mctMaintenanceMobile');
    } else if (error.code === 'messaging/registration-token-not-registered') {
      console.error('\n🔧 PROBLÈME: Token FCM invalide ou expiré');
      console.error('   Solutions:');
      console.error('   1. Désinstaller et réinstaller l\'app iOS');
      console.error('   2. Le token sera régénéré au prochain login');
    } else if (error.code === 'messaging/invalid-registration-token') {
      console.error('\n🔧 PROBLÈME: Format du token incorrect');
      console.error('   Le token dans la DB est peut-être corrompu');
    }
    
    process.exit(1);
  });
