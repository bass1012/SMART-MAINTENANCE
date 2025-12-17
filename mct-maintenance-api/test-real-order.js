/**
 * Test avec une vraie commande de la base de données
 */

const { Order, User } = require('./src/models');
const { generateInvoicePDF } = require('./src/services/pdfService');
const fs = require('fs');

async function testRealOrder() {
  try {
    console.log('🔍 Récupération de la commande 4...\n');
    
    const order = await Order.findByPk(4, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
        },
        {
          model: require('./src/models').OrderItem,
          as: 'items',
          include: [
            {
              model: require('./src/models').Product,
              as: 'product',
              attributes: ['id', 'nom', 'reference', 'prix']
            }
          ]
        }
      ]
    });

    if (!order) {
      console.error('❌ Commande non trouvée');
      process.exit(1);
    }

    console.log('✅ Commande trouvée:');
    console.log('   ID:', order.id);
    console.log('   Référence:', order.reference);
    console.log('   Total:', order.totalAmount, 'FCFA');
    console.log('   Items:', order.items?.length || 0);
    console.log('   Customer:', order.customer ? `${order.customer.first_name} ${order.customer.last_name}` : 'N/A');
    
    // Convertir en objet plain
    const orderData = order.toJSON();
    
    console.log('\n📦 Données complètes:');
    console.log(JSON.stringify(orderData, null, 2));
    
    console.log('\n🔄 Génération du PDF...\n');
    
    const pdfBuffer = await generateInvoicePDF(orderData);
    
    console.log('\n✅ PDF généré!');
    console.log('📊 Taille:', pdfBuffer.length, 'bytes');
    console.log('📊 Taille en MB:', (pdfBuffer.length / 1024 / 1024).toFixed(2), 'MB');
    
    // Sauvegarder
    const filename = `test-real-order-${order.id}.pdf`;
    fs.writeFileSync(filename, pdfBuffer);
    console.log('💾 PDF sauvegardé:', filename);
    
    // Vérifier si le PDF est valide
    const header = pdfBuffer.slice(0, 5).toString();
    console.log('📄 Header PDF:', header);
    
    if (header === '%PDF-') {
      console.log('✅ Le PDF semble valide');
    } else {
      console.log('❌ Le PDF semble corrompu (header invalide)');
    }
    
    console.log('\n🎉 Test terminé! Essayez d\'ouvrir le fichier:', filename);
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Erreur:', error);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

testRealOrder();
