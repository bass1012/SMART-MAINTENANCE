const { sequelize, Brand } = require('../src/models');

const fixBrand = async () => {
  try {
    console.log('🔧 Correction de la marque LG vers LK...');
    
    // Synchroniser les tables
    await sequelize.sync();
    
    // Supprimer la marque LG (id: 4)
    const lgBrand = await Brand.findOne({ where: { nom: 'LG' } });
    
    if (lgBrand) {
      await lgBrand.destroy();
      console.log('✅ Marque LG supprimée');
    } else {
      console.log('ℹ️  Marque LG déjà supprimée');
    }
    
    // Vérifier que LK existe
    const lkBrand = await Brand.findOne({ where: { nom: 'LK' } });
    
    if (lkBrand) {
      console.log('✅ Marque LK existe déjà');
    } else {
      console.log('⚠️  Marque LK n\'existe pas, création...');
      await Brand.create({
        nom: 'LK',
        description: 'Électronique grand public',
        actif: true
      });
      console.log('✅ Marque LK créée');
    }
    
    // Afficher toutes les marques
    const allBrands = await Brand.findAll({ order: [['nom', 'ASC']] });
    console.log('\n📋 Marques actuelles:');
    allBrands.forEach(brand => {
      console.log(`  - ${brand.nom} (ID: ${brand.id})`);
    });
    
    console.log('\n🎉 Correction terminée avec succès !');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de la correction:', error);
    process.exit(1);
  }
};

fixBrand();
