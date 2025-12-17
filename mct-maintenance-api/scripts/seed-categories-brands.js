const { sequelize, Category, Brand } = require('../src/models');

const seedCategoriesAndBrands = async () => {
  try {
    console.log('🌱 Démarrage du seed des catégories et marques...');
    
    // Synchroniser les tables (sans alter pour éviter les conflits)
    await sequelize.sync();
    
    // Catégories
    const categories = [
      { nom: 'Climatisation', description: 'Systèmes de climatisation et refroidissement', icone: 'ac_unit', actif: true },
      { nom: 'Chauffage', description: 'Systèmes de chauffage', icone: 'local_fire_department', actif: true },
      { nom: 'Ventilation', description: 'Systèmes de ventilation et aération', icone: 'air', actif: true },
      { nom: 'Service', description: 'Services de maintenance et réparation', icone: 'build', actif: true },
      { nom: 'Filtration', description: 'Systèmes de filtration d\'air', icone: 'filter_alt', actif: true }
    ];
    
    for (const cat of categories) {
      await Category.findOrCreate({
        where: { nom: cat.nom },
        defaults: cat
      });
    }
    console.log('✅ Catégories créées');
    
    // Marques
    const brands = [
      { nom: 'Daikin', description: 'Leader mondial en climatisation', actif: true },
      { nom: 'Mitsubishi', description: 'Technologie japonaise de pointe', actif: true },
      { nom: 'Samsung', description: 'Innovation coréenne', actif: true },
      { nom: 'LK', description: 'Électronique grand public', actif: true },
      { nom: 'Carrier', description: 'Pionnier de la climatisation', actif: true }
    ];
    
    for (const brand of brands) {
      await Brand.findOrCreate({
        where: { nom: brand.nom },
        defaults: brand
      });
    }
    console.log('✅ Marques créées');
    
    console.log('🎉 Seed terminé avec succès !');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    process.exit(1);
  }
};

seedCategoriesAndBrands();
