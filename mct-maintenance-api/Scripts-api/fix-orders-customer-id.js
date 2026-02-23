const { Order, CustomerProfile, User } = require('../src/models');

async function fixOrdersCustomerId() {
  console.log('🔧 Correction des customer_id dans les commandes...\n');
  
  try {
    // Récupérer toutes les commandes
    const orders = await Order.findAll();
    
    console.log(`📊 ${orders.length} commandes trouvées\n`);
    
    let corrected = 0;
    let alreadyCorrect = 0;
    let errors = 0;
    
    for (const order of orders) {
      console.log(`\n📦 Commande #${order.id} (customer_id: ${order.customerId})`);
      
      // Vérifier si customer_id est un customer_profiles.id
      const customerProfile = await CustomerProfile.findByPk(order.customerId);
      
      if (customerProfile) {
        console.log(`   ⚠️  customer_id est un customer_profiles.id (incorrect)`);
        console.log(`   → Customer Profile ID: ${customerProfile.id}`);
        console.log(`   → User ID correspondant: ${customerProfile.user_id}`);
        console.log(`   → Client: ${customerProfile.first_name} ${customerProfile.last_name}`);
        
        // Vérifier que le user existe
        const user = await User.findByPk(customerProfile.user_id);
        if (user) {
          console.log(`   → User trouvé: ${user.first_name} ${user.last_name} (${user.email})`);
          
          // Mettre à jour avec le user_id
          await order.update({ customerId: customerProfile.user_id });
          console.log(`   ✅ CORRIGÉ: customer_id = ${customerProfile.user_id}`);
          corrected++;
        } else {
          console.log(`   ❌ ERREUR: User ${customerProfile.user_id} non trouvé`);
          errors++;
        }
      } else {
        // Vérifier si c'est un user_id valide
        const user = await User.findByPk(order.customerId);
        if (user) {
          console.log(`   ✅ Déjà correct (user_id valide)`);
          console.log(`   → User: ${user.first_name} ${user.last_name} (${user.email})`);
          alreadyCorrect++;
        } else {
          console.log(`   ⚠️  customer_id ${order.customerId} ne correspond ni à un profil ni à un user`);
          errors++;
        }
      }
    }
    
    console.log('\n\n' + '='.repeat(60));
    console.log('📊 RÉSUMÉ');
    console.log('='.repeat(60));
    console.log(`Total de commandes: ${orders.length}`);
    console.log(`✅ Corrigées: ${corrected}`);
    console.log(`ℹ️  Déjà correctes: ${alreadyCorrect}`);
    console.log(`❌ Erreurs: ${errors}`);
    console.log('='.repeat(60));
    
    if (corrected > 0) {
      console.log('\n✅ Correction terminée avec succès !');
    } else if (alreadyCorrect === orders.length) {
      console.log('\n✅ Toutes les commandes sont déjà correctes !');
    } else {
      console.log('\n⚠️  Certaines commandes ont des erreurs.');
    }
    
  } catch (error) {
    console.error('\n❌ Erreur lors de la correction:', error);
    console.error(error.stack);
  }
  
  process.exit(0);
}

// Exécuter le script
fixOrdersCustomerId();
