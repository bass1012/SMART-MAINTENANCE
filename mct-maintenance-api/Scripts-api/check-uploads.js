const fs = require('fs');
const path = require('path');

const uploadDirs = [
  'uploads',
  'uploads/avatars',
  'uploads/products',
  'uploads/equipments',
  'uploads/documents'
];

console.log('🔍 Vérification des dossiers d\'upload...\n');

uploadDirs.forEach(dir => {
  const fullPath = path.join(__dirname, dir);
  
  if (!fs.existsSync(fullPath)) {
    console.log(`❌ Dossier manquant: ${dir}`);
    console.log(`   Création...`);
    fs.mkdirSync(fullPath, { recursive: true });
    console.log(`   ✅ Créé: ${fullPath}\n`);
  } else {
    console.log(`✅ Dossier existe: ${dir}`);
    
    // Vérifier les permissions
    try {
      fs.accessSync(fullPath, fs.constants.W_OK);
      console.log(`   ✅ Permissions d'écriture OK\n`);
    } catch (err) {
      console.log(`   ❌ Pas de permissions d'écriture !`);
      console.log(`   Exécutez: chmod 755 ${fullPath}\n`);
    }
  }
});

console.log('✅ Vérification terminée !');
console.log('\nPour tester l\'upload:');
console.log('1. Redémarrez le serveur: npm start');
console.log('2. Essayez de changer votre avatar sur mobile');
console.log('3. Vérifiez les logs backend et mobile');
