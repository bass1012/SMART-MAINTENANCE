// Script de test pour déboguer les notifications
const { Intervention, User } = require('./src/models');
const { notifyNewIntervention } = require('./src/services/notificationHelpers');

async function testNotification() {
  try {
    console.log('🔍 Test de notification...\n');

    // 1. Trouver la dernière intervention
    const intervention = await Intervention.findOne({
      order: [['created_at', 'DESC']],
      include: [
        { model: User, as: 'customer', attributes: ['id', 'first_name', 'last_name', 'email'] }
      ]
    });

    if (!intervention) {
      console.log('❌ Aucune intervention trouvée');
      return;
    }

    console.log('✅ Intervention trouvée:');
    console.log('   ID:', intervention.id);
    console.log('   Title:', intervention.title);
    console.log('   Customer ID:', intervention.customer_id);
    console.log('');

    // 2. Vérifier le customer
    if (!intervention.customer) {
      console.log('❌ Customer non chargé dans l\'intervention');
      console.log('   Chargement manuel du customer...');
      
      const customer = await User.findByPk(intervention.customer_id);
      if (customer) {
        console.log('✅ Customer trouvé:');
        console.log('   ID:', customer.id);
        console.log('   Name:', customer.first_name, customer.last_name);
        console.log('   Email:', customer.email);
        console.log('');

        // 3. Tester la notification
        console.log('📤 Envoi de la notification...');
        await notifyNewIntervention(intervention, customer);
        console.log('✅ Notification envoyée avec succès!');
      } else {
        console.log('❌ Customer introuvable avec ID:', intervention.customer_id);
      }
    } else {
      console.log('✅ Customer chargé:');
      console.log('   ID:', intervention.customer.id);
      console.log('   Name:', intervention.customer.first_name, intervention.customer.last_name);
      console.log('');

      // 3. Tester la notification
      console.log('📤 Envoi de la notification...');
      await notifyNewIntervention(intervention, intervention.customer);
      console.log('✅ Notification envoyée avec succès!');
    }

    // 4. Vérifier en base
    const { Notification } = require('./src/models');
    const notifCount = await Notification.count({
      where: { type: 'intervention_request' }
    });
    console.log('');
    console.log('📊 Total notifications intervention_request:', notifCount);

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error('Stack:', error.stack);
  }
  
  process.exit(0);
}

testNotification();
