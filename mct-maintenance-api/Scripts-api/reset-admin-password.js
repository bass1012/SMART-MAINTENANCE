const bcrypt = require('bcrypt');
const { User } = require('../src/models');

async function resetAdminPassword() {
  try {
    const email = 'admin@mct-maintenance.com';
    const newPassword = 'Admin@123';
    
    console.log('🔍 Recherche de l\'admin...');
    console.log(`Email: ${email}`);
    
    // Trouver l'utilisateur
    const user = await User.findOne({ where: { email } });
    
    if (!user) {
      console.log('❌ Admin non trouvé');
      process.exit(1);
    }
    
    console.log(`✅ Admin trouvé: ${user.firstName} ${user.lastName}`);
    console.log(`   Role: ${user.role}`);
    
    // Hasher le nouveau mot de passe
    console.log('\n🔐 Hashage du nouveau mot de passe...');
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Mettre à jour le mot de passe
    await user.update({ password: hashedPassword });
    
    console.log('✅ Mot de passe réinitialisé avec succès!');
    console.log(`\n📋 Nouvelles informations de connexion:`);
    console.log(`   Email: ${email}`);
    console.log(`   Mot de passe: ${newPassword}`);
    console.log(`\n🔗 Test de connexion:`);
    console.log(`curl -X POST "http://localhost:3000/api/auth/login" \\`);
    console.log(`  -H "Content-Type: application/json" \\`);
    console.log(`  -d '{"email":"${email}","password":"${newPassword}"}'`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

resetAdminPassword();
