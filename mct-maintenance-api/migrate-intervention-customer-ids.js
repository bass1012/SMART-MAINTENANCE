const { Intervention, User, CustomerProfile } = require('./src/models');

/**
 * Migration pour corriger les customer_id des interventions
 * Convertir de User.id vers CustomerProfile.id
 */
async function migrateInterventionCustomerIds() {
  try {
    console.log('🔄 Début de la migration des customer_id des interventions...');
    
    // Récupérer toutes les interventions
    const interventions = await Intervention.findAll({
      attributes: ['id', 'customer_id']
    });
    
    console.log(`📋 ${interventions.length} interventions à vérifier`);
    
    let migratedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    
    for (const intervention of interventions) {
      try {
        const oldCustomerId = intervention.customer_id;
        
        // Vérifier si customer_id pointe vers un CustomerProfile
        const customerProfile = await CustomerProfile.findByPk(oldCustomerId);
        
        if (customerProfile) {
          // C'est déjà un CustomerProfile.id, pas besoin de migrer
          skippedCount++;
          continue;
        }
        
        // Sinon, c'est probablement un User.id, chercher le CustomerProfile correspondant
        const user = await User.findByPk(oldCustomerId);
        
        if (!user) {
          console.log(`⚠️  Intervention ${intervention.id}: customer_id ${oldCustomerId} n'existe ni dans users ni dans customer_profiles`);
          errorCount++;
          continue;
        }
        
        // Chercher le CustomerProfile avec ce user_id
        const correctProfile = await CustomerProfile.findOne({
          where: { user_id: oldCustomerId }
        });
        
        if (!correctProfile) {
          console.log(`⚠️  Intervention ${intervention.id}: Aucun CustomerProfile trouvé pour user_id ${oldCustomerId} (${user.email})`);
          errorCount++;
          continue;
        }
        
        // Mettre à jour l'intervention
        await intervention.update({ customer_id: correctProfile.id });
        
        console.log(`✅ Intervention ${intervention.id}: ${oldCustomerId} (User) → ${correctProfile.id} (CustomerProfile) - ${user.email}`);
        migratedCount++;
        
      } catch (err) {
        console.error(`❌ Erreur intervention ${intervention.id}:`, err.message);
        errorCount++;
      }
    }
    
    console.log('\n📊 Résumé de la migration:');
    console.log(`   ✅ Migrées: ${migratedCount}`);
    console.log(`   ⏭️  Déjà correctes: ${skippedCount}`);
    console.log(`   ❌ Erreurs: ${errorCount}`);
    console.log(`   📝 Total: ${interventions.length}`);
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Erreur globale:', error);
    process.exit(1);
  }
}

// Exécuter la migration
migrateInterventionCustomerIds();
