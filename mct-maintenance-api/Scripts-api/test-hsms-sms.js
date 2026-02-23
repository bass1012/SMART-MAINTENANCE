const { 
  sendVerificationCodeSMS, 
  sendPasswordResetCodeSMS,
  checkSMSBalance,
  formatPhoneNumber,
  isValidIvoryCoastPhone
} = require('../src/services/smsService');

require('dotenv').config();

/**
 * Script de test pour HSMS.ci
 * 
 * Usage:
 * node Scripts-api/test-hsms-sms.js <phone> [test_type]
 * 
 * Exemples:
 * node Scripts-api/test-hsms-sms.js 0170793131 verification
 * node Scripts-api/test-hsms-sms.js 0170793131 reset
 * node Scripts-api/test-hsms-sms.js 0170793131 balance
 */

const testSMSService = async () => {
  console.log('\n🧪 === Test HSMS.ci SMS Service ===\n');

  // Vérifier la configuration
  const hasToken = !!process.env.HSMS_TOKEN;
  const hasClientCredentials = !!(process.env.HSMS_CLIENT_ID && process.env.HSMS_CLIENT_SECRET);

  if (!hasToken && !hasClientCredentials) {
    console.error('❌ Erreur: Identifiants HSMS.ci non configurés dans .env');
    console.log('\n📝 Configurez UNE des deux options dans votre fichier .env:\n');
    console.log('Option 1 (RECOMMANDÉ) - Avec TOKEN:');
    console.log('HSMS_TOKEN=votre_token_ici\n');
    console.log('Option 2 - Avec Client ID + Secret:');
    console.log('HSMS_CLIENT_ID=votre_client_id_ici');
    console.log('HSMS_CLIENT_SECRET=votre_client_secret_ici\n');
    console.log('Autres variables:');
    console.log('HSMS_API_URL=https://api.hsms.ci/api/v1');
    console.log('HSMS_SENDER_NAME=MCT-MAINT\n');
    process.exit(1);
  }

  console.log('✅ Configuration HSMS.ci chargée:');
  console.log(`   API URL: ${process.env.HSMS_API_URL || 'https://api.hsms.ci/api/v1'}`);
  
  if (hasToken) {
    console.log(`   Méthode: TOKEN`);
    console.log(`   Token: ${process.env.HSMS_TOKEN.substring(0, 15)}...`);
  } else {
    console.log(`   Méthode: Client ID + Secret`);
    console.log(`   Client ID: ${process.env.HSMS_CLIENT_ID.substring(0, 10)}...`);
    console.log(`   Client Secret: ${process.env.HSMS_CLIENT_SECRET.substring(0, 10)}...`);
  }
  
  console.log(`   Sender: ${process.env.HSMS_SENDER_NAME || 'MCT-MAINT'}\n`);

  // Récupérer les arguments
  const phone = process.argv[2];
  const testType = process.argv[3] || 'verification';

  if (!phone) {
    console.error('❌ Usage: node test-hsms-sms.js <phone> [verification|reset|balance]');
    console.log('\nExemple: node test-hsms-sms.js 0170793131 verification');
    process.exit(1);
  }

  // Tester le formatage du numéro
  console.log('📱 Test de formatage du numéro:');
  console.log(`   Numéro brut: ${phone}`);
  const formattedPhone = formatPhoneNumber(phone);
  console.log(`   Numéro formaté: ${formattedPhone}`);
  const isValid = isValidIvoryCoastPhone(phone);
  console.log(`   Valide (CI): ${isValid ? '✅ Oui' : '❌ Non'}\n`);

  if (!isValid) {
    console.warn('⚠️ Attention: Le numéro ne semble pas être un numéro ivoirien valide');
    console.log('   Format attendu: 0170793131 ou 2250170793131\n');
  }

  try {
    if (testType === 'balance') {
      // Test du solde
      console.log('💰 Vérification du solde SMS...\n');
      const balanceResult = await checkSMSBalance();
      
      if (balanceResult.success) {
        console.log('✅ Solde récupéré avec succès:');
        console.log(`   Crédits disponibles: ${balanceResult.balance} SMS`);
        console.log('\n📊 Détails:', JSON.stringify(balanceResult.data, null, 2));
      } else {
        console.error('❌ Erreur lors de la récupération du solde:', balanceResult.error);
      }
    } else if (testType === 'reset') {
      // Test du code de réinitialisation
      console.log('🔑 Envoi d\'un code de réinitialisation de mot de passe...\n');
      const code = '123456'; // Code de test
      const result = await sendPasswordResetCodeSMS(formattedPhone, code, 'Test');
      
      if (result.success) {
        console.log('✅ SMS de réinitialisation envoyé avec succès !');
        console.log(`   Message ID: ${result.messageId}`);
        console.log(`   Statut: ${result.status}`);
        console.log('\n📨 Détails:', JSON.stringify(result.data, null, 2));
      } else {
        console.error('❌ Échec de l\'envoi du SMS:', result.error);
        if (result.statusCode) {
          console.error(`   Code HTTP: ${result.statusCode}`);
        }
      }
    } else {
      // Test du code de vérification (par défaut)
      console.log('📬 Envoi d\'un code de vérification...\n');
      const code = '654321'; // Code de test
      const result = await sendVerificationCodeSMS(formattedPhone, code, 'Test');
      
      if (result.success) {
        console.log('✅ SMS de vérification envoyé avec succès !');
        console.log(`   Message ID: ${result.messageId}`);
        console.log(`   Statut: ${result.status}`);
        console.log('\n📨 Détails:', JSON.stringify(result.data, null, 2));
      } else {
        console.error('❌ Échec de l\'envoi du SMS:', result.error);
        if (result.statusCode) {
          console.error(`   Code HTTP: ${result.statusCode}`);
        }
      }
    }

    console.log('\n✅ Test terminé avec succès\n');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ Erreur lors du test:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
};

// Lancer le test
testSMSService();
