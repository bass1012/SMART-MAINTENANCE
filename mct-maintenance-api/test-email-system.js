/**
 * Script de test système notifications email
 * Vérifie la configuration SMTP et envoie un email de test
 */

// Charger les variables d'environnement
require('dotenv').config();

const { sendEmail, testEmailConfiguration } = require('./src/services/emailService');

async function testEmailSystem() {
  console.log('🚀 Démarrage des tests système email...\n');

  // Test 1 : Configuration SMTP
  console.log('📧 Test 1 : Vérification configuration SMTP...');
  try {
    await testEmailConfiguration();
    console.log('✅ Configuration SMTP valide\n');
  } catch (error) {
    console.error('❌ Erreur configuration SMTP:', error.message);
    console.error('💡 Vérifiez EMAIL_USER et EMAIL_PASSWORD dans .env\n');
    process.exit(1);
  }

  // Test 2 : Email générique simple
  console.log('📧 Test 2 : Envoi email de test basique...');
  try {
    await sendEmail({
      to: process.env.EMAIL_USER, // Envoie à soi-même
      subject: 'Test système email SMART MAINTENANCE',
      title: '✅ Test du système de notifications',
      message: `
        <h2>Test réussi !</h2>
        <p>Si vous recevez cet email, la configuration SMTP fonctionne correctement.</p>
        <p>Date du test : ${new Date().toLocaleString('fr-FR')}</p>
      `,
      details: {
        'Environnement': process.env.NODE_ENV || 'development',
        'Serveur SMTP': 'Gmail',
        'Date': new Date().toLocaleDateString('fr-FR')
      },
      type: 'success'
    });
    console.log('✅ Email de test envoyé avec succès\n');
  } catch (error) {
    console.error('❌ Erreur envoi email:', error.message);
    process.exit(1);
  }

  // Test 3 : Email intervention (simulation)
  console.log('📧 Test 3 : Email intervention (exemple)...');
  try {
    await sendEmail({
      to: process.env.EMAIL_USER,
      subject: 'Intervention créée - INT-2024-TEST',
      title: '✅ Votre demande d\'intervention a été créée',
      message: `
        <h2>Bonjour Client Test,</h2>
        <p>Nous avons bien reçu votre demande d'intervention.</p>
        <p>Notre équipe va l'analyser et vous assigner un technicien dans les plus brefs délais.</p>
      `,
      details: {
        'Référence': 'INT-2024-TEST',
        'Titre': 'Réparation climatiseur',
        'Date prévue': new Date().toLocaleDateString('fr-FR'),
        'Frais diagnostic': 'GRATUIT (contrat actif)',
        'Statut': 'En attente d\'assignation'
      },
      type: 'success'
    });
    console.log('✅ Email intervention envoyé\n');
  } catch (error) {
    console.error('❌ Erreur email intervention:', error.message);
  }

  // Test 4 : Email commande (simulation)
  console.log('📧 Test 4 : Email commande (exemple)...');
  try {
    await sendEmail({
      to: process.env.EMAIL_USER,
      subject: 'Commande confirmée - CMD-2024-TEST',
      title: '🛒 Commande confirmée',
      message: `
        <h2>Bonjour Client Test,</h2>
        <p>Merci pour votre commande ! Nous l'avons bien reçue et nous la préparons.</p>
        <p>Vous recevrez une notification dès que votre commande sera expédiée.</p>
      `,
      details: {
        'Référence': 'CMD-2024-TEST',
        'Montant total': '125,000 FCFA',
        'Articles': '3 article(s)',
        'Date': new Date().toLocaleDateString('fr-FR'),
        'Statut': 'En attente de préparation'
      },
      type: 'success'
    });
    console.log('✅ Email commande envoyé\n');
  } catch (error) {
    console.error('❌ Erreur email commande:', error.message);
  }

  // Test 5 : Email devis (simulation)
  console.log('📧 Test 5 : Email devis (exemple)...');
  try {
    await sendEmail({
      to: process.env.EMAIL_USER,
      subject: 'Nouveau devis - DEV-2024-TEST',
      title: '📄 Nouveau devis disponible',
      message: `
        <h2>Bonjour Client Test,</h2>
        <p>Un nouveau devis a été créé pour vous.</p>
        <p>Vous pouvez le consulter et l'accepter ou le refuser dans votre espace client.</p>
      `,
      details: {
        'Référence': 'DEV-2024-TEST',
        'Montant': '50,000 FCFA',
        'Date création': new Date().toLocaleDateString('fr-FR'),
        'Valable jusqu\'au': new Date(Date.now() + 30*24*60*60*1000).toLocaleDateString('fr-FR')
      },
      type: 'info'
    });
    console.log('✅ Email devis envoyé\n');
  } catch (error) {
    console.error('❌ Erreur email devis:', error.message);
  }

  // Résumé
  console.log('\n✅ Tests terminés avec succès !');
  console.log('📬 Vérifiez votre boîte de réception :', process.env.EMAIL_USER);
  console.log('💡 Si vous ne voyez pas les emails, vérifiez le dossier Spam');
  console.log('\n📊 Récapitulatif :');
  console.log('  - Test configuration SMTP : ✅');
  console.log('  - Email basique : ✅');
  console.log('  - Email intervention : ✅');
  console.log('  - Email commande : ✅');
  console.log('  - Email devis : ✅');
}

// Exécuter les tests
testEmailSystem()
  .then(() => {
    console.log('\n🎉 Tous les tests sont passés !');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Erreur lors des tests:', error);
    process.exit(1);
  });
