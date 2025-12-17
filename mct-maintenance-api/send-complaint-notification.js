// Script pour envoyer une notification de réclamation
const { Complaint, CustomerProfile, User } = require('./src/models');
const { notifyNewComplaint } = require('./src/services/notificationHelpers');

async function sendComplaintNotification() {
  try {
    console.log('🔔 Envoi de notification pour la dernière réclamation\n');

    // Trouver la dernière réclamation
    const complaint = await Complaint.findOne({
      order: [['created_at', 'DESC']],
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'email', 'first_name', 'last_name']
            }
          ]
        }
      ]
    });

    if (!complaint) {
      console.log('❌ Aucune réclamation trouvée');
      return;
    }

    console.log('✅ Réclamation trouvée:');
    console.log(`   ID: ${complaint.id}`);
    console.log(`   Référence: ${complaint.reference}`);
    console.log(`   Sujet: ${complaint.subject}`);
    console.log('');

    if (!complaint.customer) {
      console.log('❌ Pas de customer associé');
      return;
    }

    if (!complaint.customer.user) {
      console.log('❌ Le customer n\'a pas de user actif');
      console.log(`   Customer ID: ${complaint.customer.id}`);
      console.log(`   Nom: ${complaint.customer.first_name} ${complaint.customer.last_name}`);
      return;
    }

    const customerData = {
      id: complaint.customer.user.id,
      first_name: complaint.customer.first_name,
      last_name: complaint.customer.last_name,
      email: complaint.customer.user.email
    };

    console.log('📤 Envoi de la notification...');
    console.log(`   Admin recevra: "${customerData.first_name} ${customerData.last_name} a créé une réclamation"`);
    console.log('');

    await notifyNewComplaint(complaint, customerData);

    console.log('✅ Notification envoyée avec succès !');
    console.log('');
    console.log('👀 Vérifiez le dashboard:');
    console.log('   - Badge sur la cloche 🔔');
    console.log('   - Toast "Nouvelle réclamation"');
    console.log('   - Clic sur notification → /reclamations/' + complaint.id);

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error.stack);
  }
  
  process.exit(0);
}

sendComplaintNotification();
