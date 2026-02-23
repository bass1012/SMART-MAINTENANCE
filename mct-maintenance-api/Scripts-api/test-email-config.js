require('dotenv').config();
const { testEmailConfiguration, sendPasswordResetEmail } = require('../src/services/emailService');

async function testEmail() {
  console.log('🧪 Test de la configuration email...\n');
  
  // Vérifier les variables d'environnement
  console.log('📋 Variables d\'environnement:');
  console.log('   EMAIL_SERVICE:', process.env.EMAIL_SERVICE || 'non défini');
  console.log('   EMAIL_USER:', process.env.EMAIL_USER ? '***défini***' : '❌ non défini');
  console.log('   EMAIL_PASSWORD:', process.env.EMAIL_PASSWORD ? '***défini***' : '❌ non défini');
  console.log('   EMAIL_FROM:', process.env.EMAIL_FROM || process.env.EMAIL_USER || 'non défini');
  console.log('   SMTP_HOST:', process.env.SMTP_HOST || 'non défini (utilisera smtp.gmail.com par défaut)');
  console.log('   SMTP_PORT:', process.env.SMTP_PORT || 'non défini (utilisera 587 par défaut)');
  console.log('');
  
  // Tester la configuration
  try {
    const isValid = await testEmailConfiguration();
    if (isValid) {
      console.log('✅ Configuration email valide !\n');
      
      // Tester l'envoi d'un email de test
      console.log('📧 Test d\'envoi d\'email de réinitialisation...');
      const testEmail = process.env.EMAIL_USER || 'test@example.com';
      const testLink = 'http://localhost:3001/reset-password?token=test-token';
      
      try {
        const result = await sendPasswordResetEmail(
          testEmail,
          'Test User',
          testLink
        );
        console.log('✅ Email de test envoyé avec succès !');
        console.log('   Message ID:', result.messageId);
        console.log('   Destinataire:', result.recipient);
      } catch (sendError) {
        console.error('❌ Erreur lors de l\'envoi de l\'email de test:');
        console.error('   Message:', sendError.message);
        console.error('   Stack:', sendError.stack);
      }
    } else {
      console.log('❌ Configuration email invalide !');
    }
  } catch (error) {
    console.error('❌ Erreur lors du test de configuration:');
    console.error('   Message:', error.message);
    console.error('   Stack:', error.stack);
  }
}

testEmail().then(() => {
  console.log('\n✅ Test terminé');
  process.exit(0);
}).catch(error => {
  console.error('\n❌ Erreur fatale:', error);
  process.exit(1);
});

