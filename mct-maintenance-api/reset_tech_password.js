const bcrypt = require('bcrypt');
const { User } = require('./src/models');

async function resetTechPassword() {
  try {
    const email = 'cissoko@gmail.com';
    const newPassword = 'Password123';
    
    console.log('🔍 Recherche du technicien...');
    console.log(`Email: ${email}`);
    
    // Trouver l'utilisateur
    const user = await User.findOne({ where: { email } });
    
    if (!user) {
      console.log('❌ Utilisateur non trouvé');
      console.log('\nUtilisateurs techniciens disponibles :');
      
      const technicians = await User.findAll({
        where: { role: 'technician' },
        attributes: ['id', 'email', 'first_name', 'last_name', 'role']
      });
      
      if (technicians.length === 0) {
        console.log('❌ Aucun technicien trouvé en base');
      } else {
        technicians.forEach(tech => {
          console.log(`- [${tech.id}] ${tech.email} (${tech.first_name} ${tech.last_name})`);
        });
      }
      
      process.exit(1);
    }
    
    console.log(`✅ Utilisateur trouvé: ${user.email}`);
    console.log(`   ID: ${user.id}`);
    console.log(`   Nom: ${user.first_name} ${user.last_name}`);
    console.log(`   Rôle: ${user.role}`);
    
    if (user.role !== 'technician') {
      console.log('\n⚠️  Attention: Ce compte n\'est pas un technicien !');
      console.log(`   Rôle actuel: ${user.role}`);
      console.log('   Voulez-vous continuer ? Changez le rôle d\'abord avec :');
      console.log(`   UPDATE users SET role = 'technician' WHERE id = ${user.id};`);
      process.exit(1);
    }
    
    // Générer le hash du nouveau mot de passe
    console.log('\n🔐 Génération du hash...');
    const passwordHash = await bcrypt.hash(newPassword, 10);
    
    // Mettre à jour le mot de passe
    await user.update({ password_hash: passwordHash });
    
    console.log('✅ Mot de passe réinitialisé avec succès !');
    console.log('\n📋 IDENTIFIANTS :');
    console.log(`   Email    : ${email}`);
    console.log(`   Password : ${newPassword}`);
    console.log('\nVous pouvez maintenant vous connecter avec ces identifiants.');
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  }
}

// Exécuter
resetTechPassword();
