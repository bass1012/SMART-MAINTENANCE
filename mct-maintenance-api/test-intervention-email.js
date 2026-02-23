/**
 * Script de test pour l'envoi d'emails d'intervention
 * Usage: node test-intervention-email.js <email_destinataire>
 */

require('dotenv').config();
const { sendInterventionCreatedEmail } = require('./src/services/emailHelper');

// Données de test
const mockIntervention = {
  id: 999,
  title: 'Test intervention email',
  description: 'Ceci est un test d\'envoi d\'email d\'intervention',
  intervention_type: 'maintenance',
  priority: 'normal',
  status: 'pending',
  scheduled_date: new Date(),
  address: '1600 Amphitheatre Pkwy, Mountain View, United States',
  equipment_count: 1,
  diagnostic_fee: 4000,
  is_free_diagnosis: false
};

const mockCustomer = {
  id: 1,
  email: process.argv[2] || 'test@example.com',
  first_name: 'Test',
  last_name: 'Client'
};

async function testInterventionEmail() {
  console.log('🧪 Test d\'envoi d\'email d\'intervention');
  console.log('📧 Destinataire:', mockCustomer.email);
  console.log('📋 Intervention:', mockIntervention.title);
  console.log('');

  try {
    console.log('⏳ Envoi en cours...');
    const result = await sendInterventionCreatedEmail(mockIntervention, mockCustomer);
    
    console.log('');
    if (result.success) {
      console.log('✅ EMAIL ENVOYÉ AVEC SUCCÈS !');
      console.log('📧 Message ID:', result.messageId);
      console.log('✉️  Destinataire accepté:', result.accepted);
      console.log('📨 Réponse serveur:', result.response);
    } else {
      console.log('❌ ÉCHEC DE L\'ENVOI');
      console.log('⚠️  Raison:', result.reason || result.error);
    }
  } catch (error) {
    console.error('❌ ERREUR:', error.message);
    console.error(error);
  }
}

// Vérification EMAIL_ENABLED
if (process.env.EMAIL_ENABLED === 'false') {
  console.log('⚠️  EMAIL_ENABLED=false dans .env');
  console.log('   Changez EMAIL_ENABLED=true pour activer les emails');
  process.exit(1);
}

// Exécution
testInterventionEmail();
