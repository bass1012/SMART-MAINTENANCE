// Script pour vérifier les admins dans la base de données
const { User } = require('./mct-maintenance-api/src/models');

async function checkAdmins() {
  try {
    console.log('🔍 Recherche des utilisateurs avec role=admin...\n');
    
    const admins = await User.findAll({
      where: { role: 'admin' },
      attributes: ['id', 'email', 'role', 'status']
    });
    
    console.log(`📊 ${admins.length} admin(s) trouvé(s):\n`);
    admins.forEach(admin => {
      console.log(`  - ID: ${admin.id}`);
      console.log(`    Email: ${admin.email}`);
      console.log(`    Role: ${admin.role}`);
      console.log(`    Status: ${admin.status}`);
      console.log('');
    });
    
    const activeAdmins = admins.filter(a => a.status === 'active');
    console.log(`✅ ${activeAdmins.length} admin(s) actif(s)\n`);
    
    if (activeAdmins.length === 0) {
      console.log('⚠️  AUCUN ADMIN ACTIF ! Les notifications aux admins ne fonctionneront pas.\n');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

checkAdmins();
