const { sequelize } = require('./src/config/database');
const Promotion = require('./src/models/Promotion');

async function createTestPromoCodes() {
  try {
    console.log('🎁 Création des codes promo de test...\n');
    
    // Code promo 1: Réduction de 10%
    const promo1 = await Promotion.findOrCreate({
      where: { code: 'PROMO10' },
      defaults: {
        name: 'Réduction 10%',
        code: 'PROMO10',
        type: 'percentage',
        value: 10,
        startDate: new Date(),
        endDate: new Date('2026-12-31'),
        usageLimit: 100,
        target: 'all',
        isActive: true,
        description: 'Réduction de 10% sur toute commande'
      }
    });
    console.log(promo1[1] ? '✅ Code PROMO10 créé (10% de réduction)' : 'ℹ️  Code PROMO10 existe déjà');
    
    // Code promo 2: Réduction de 5000 FCFA
    const promo2 = await Promotion.findOrCreate({
      where: { code: 'WELCOME5000' },
      defaults: {
        name: 'Bienvenue - 5000 FCFA',
        code: 'WELCOME5000',
        type: 'fixed',
        value: 5000,
        startDate: new Date(),
        endDate: new Date('2026-12-31'),
        usageLimit: 50,
        target: 'customers',
        isActive: true,
        description: 'Réduction fixe de 5000 FCFA pour nouveaux clients'
      }
    });
    console.log(promo2[1] ? '✅ Code WELCOME5000 créé (5000 FCFA de réduction)' : 'ℹ️  Code WELCOME5000 existe déjà');
    
    // Code promo 3: Réduction de 20%
    const promo3 = await Promotion.findOrCreate({
      where: { code: 'NOEL2025' },
      defaults: {
        name: 'Noël 2025',
        code: 'NOEL2025',
        type: 'percentage',
        value: 20,
        startDate: new Date('2025-12-01'),
        endDate: new Date('2025-12-31'),
        usageLimit: 200,
        target: 'all',
        isActive: true,
        description: 'Promotion de Noël - 20% de réduction'
      }
    });
    console.log(promo3[1] ? '✅ Code NOEL2025 créé (20% de réduction)' : 'ℹ️  Code NOEL2025 existe déjà');
    
    // Code promo 4: Réduction de 2000 FCFA
    const promo4 = await Promotion.findOrCreate({
      where: { code: 'SAVE2000' },
      defaults: {
        name: 'Économisez 2000 FCFA',
        code: 'SAVE2000',
        type: 'fixed',
        value: 2000,
        startDate: new Date(),
        endDate: new Date('2026-06-30'),
        usageLimit: 150,
        target: 'all',
        isActive: true,
        description: 'Réduction de 2000 FCFA sur toute commande'
      }
    });
    console.log(promo4[1] ? '✅ Code SAVE2000 créé (2000 FCFA de réduction)' : 'ℹ️  Code SAVE2000 existe déjà');
    
    console.log('\n✅ Codes promo de test créés avec succès !');
    console.log('\n📋 Codes disponibles pour les tests :');
    console.log('   - PROMO10 (10% de réduction)');
    console.log('   - WELCOME5000 (5000 FCFA de réduction)');
    console.log('   - NOEL2025 (20% de réduction)');
    console.log('   - SAVE2000 (2000 FCFA de réduction)');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de la création des codes promo:', error);
    process.exit(1);
  }
}

createTestPromoCodes();
