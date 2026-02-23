/**
 * Script de test pour l'inscription avec vérification SMS
 * Ce script teste le flux complet d'inscription avec code SMS
 */

const axios = require('axios');

const API_URL = process.env.API_URL || 'http://192.168.1.139:3000/api';

async function testRegistrationWithSMS() {
  console.log('🧪 === Test Inscription avec SMS ===\n');

  // Données de test
  const testUser = {
    email: `test.sms.${Date.now()}@example.com`,
    password: 'Test123456!',
    firstName: 'Jean',
    lastName: 'Dupont',
    phoneNumber: '0708205263', // Sera formaté en 2250170793131
    role: 'customer'
  };

  try {
    console.log('📝 Étape 1: Inscription d\'un nouvel utilisateur...');
    console.log('   Email:', testUser.email);
    console.log('   Téléphone:', testUser.phoneNumber);

    const registerResponse = await axios.post(`${API_URL}/auth/register`, testUser);

    console.log('\n✅ Inscription réussie!');
    console.log('   Message:', registerResponse.data.message);
    console.log('   User ID:', registerResponse.data.user?.id);
    console.log('   Vérification requise:', registerResponse.data.user?.isVerified === false ? 'Oui' : 'Non');

    if (registerResponse.data.user?.phoneNumber) {
      console.log('\n📱 SMS de vérification envoyé au:', registerResponse.data.user.phoneNumber);
      console.log('\n⚠️  IMPORTANT: Vérifiez votre téléphone pour le code SMS!');
      console.log('   Le code est valide pendant 15 minutes.');
      console.log('\n   Pour vérifier le compte, utilisez:');
      console.log(`   POST ${API_URL}/auth/verify-email`);
      console.log('   Body: { "email": "${testUser.email}", "code": "XXXXXX" }');
    }

    return {
      success: true,
      userId: registerResponse.data.user?.id,
      email: testUser.email,
      phoneNumber: registerResponse.data.user?.phoneNumber
    };

  } catch (error) {
    console.error('\n❌ Erreur lors de l\'inscription:');
    
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Message:', error.response.data.message || error.response.data.error);
      
      if (error.response.data.details) {
        console.error('   Détails:', error.response.data.details);
      }
    } else {
      console.error('   ', error.message);
    }

    return { success: false, error: error.message };
  }
}

async function testPasswordResetSMS() {
  console.log('\n\n🧪 === Test Réinitialisation Mot de Passe avec SMS ===\n');

  const testEmail = 'bassoued@gmail.com'; // Utilisez un email existant dans votre DB

  try {
    console.log('🔄 Demande de réinitialisation pour:', testEmail);

    const response = await axios.post(`${API_URL}/auth/request-reset-code`, {
      email: testEmail
    });

    console.log('\n✅ Code de réinitialisation envoyé!');
    console.log('   Message:', response.data.message);
    console.log('\n📱 Vérifiez votre téléphone pour le code SMS!');
    console.log('   Le code est valide pendant 15 minutes.');
    console.log('\n   Pour réinitialiser le mot de passe, utilisez:');
    console.log(`   POST ${API_URL}/auth/reset-password`);
    console.log('   Body: { "email": "${testEmail}", "code": "XXXXXX", "newPassword": "NouveauMotDePasse123!" }');

    return { success: true };

  } catch (error) {
    console.error('\n❌ Erreur lors de la demande de réinitialisation:');
    
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Message:', error.response.data.message || error.response.data.error);
    } else {
      console.error('   ', error.message);
    }

    return { success: false, error: error.message };
  }
}

// Exécution
(async () => {
  // Test 1: Inscription avec SMS
  const registrationResult = await testRegistrationWithSMS();

  // Test 2: Réinitialisation avec SMS (optionnel - décommentez si besoin)
  // await testPasswordResetSMS();

  console.log('\n\n📊 === Résumé ===');
  console.log('Inscription:', registrationResult.success ? '✅ Réussie' : '❌ Échouée');
  
  if (registrationResult.success) {
    console.log('\n💡 Prochaines étapes:');
    console.log('1. Vérifiez le SMS reçu sur le téléphone', registrationResult.phoneNumber);
    console.log('2. Utilisez le code reçu pour vérifier le compte');
    console.log('3. Connectez-vous avec les identifiants');
  }

  console.log('\n✅ Tests terminés!');
})();
