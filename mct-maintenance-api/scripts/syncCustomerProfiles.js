// Script pour créer un CustomerProfile pour chaque utilisateur de rôle 'customer' sans profil
const { User, CustomerProfile, sequelize } = require('../src/models');

async function syncCustomerProfiles() {
  try {
    await sequelize.authenticate();
    const customers = await User.findAll({ where: { role: 'customer' } });
    let created = 0;
    for (const user of customers) {
      const existingProfile = await CustomerProfile.findOne({ where: { user_id: user.id } });
      if (!existingProfile) {
        await CustomerProfile.create({
          user_id: user.id,
          first_name: user.first_name || '',
          last_name: user.last_name || '',
          // Ajoute d'autres champs par défaut si besoin
        });
        created++;
        console.log(`Profil client créé pour l'utilisateur ${user.email}`);
      }
    }
    console.log(`Synchronisation terminée. Profils créés : ${created}`);
    process.exit(0);
  } catch (err) {
    console.error('Erreur lors de la synchronisation des profils clients :', err);
    process.exit(1);
  }
}

syncCustomerProfiles();