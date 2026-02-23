/**
 * Script de test pour la génération de PDF
 */

const { generateInvoicePDF } = require('../src/services/pdfService');
const fs = require('fs');

// Données de test
const testOrder = {
  id: 4,
  reference: 'CMD-TEST-001',
  totalAmount: 150000,
  status: 'pending',
  shippingAddress: 'Abidjan, Cocody, Côte d\'Ivoire',
  paymentMethod: 'Wave',
  notes: 'Livraison urgente',
  createdAt: new Date(),
  customer: {
    id: 1,
    email: 'test@example.com',
    first_name: 'Jean',
    last_name: 'Kouassi',
    phone: '+2250701234567'
  },
  items: [
    {
      id: 1,
      quantity: 2,
      unit_price: 50000,
      total: 100000,
      product: {
        id: 1,
        nom: 'Climatiseur Samsung 12000 BTU',
        reference: 'CLIM-SAM-12K',
        prix: 50000
      }
    },
    {
      id: 2,
      quantity: 1,
      unit_price: 50000,
      total: 50000,
      product: {
        id: 2,
        nom: 'Installation et mise en service',
        reference: 'SERV-INST',
        prix: 50000
      }
    }
  ]
};

async function testPDFGeneration() {
  try {
    console.log('🧪 Test de génération de PDF...\n');
    console.log('📦 Données de test:', JSON.stringify(testOrder, null, 2));
    console.log('\n🔄 Génération du PDF...\n');
    
    const pdfBuffer = await generateInvoicePDF(testOrder);
    
    console.log('\n✅ PDF généré avec succès!');
    console.log('📊 Taille du PDF:', pdfBuffer.length, 'bytes');
    
    // Sauvegarder le PDF pour inspection
    const filename = `test-facture-${Date.now()}.pdf`;
    fs.writeFileSync(filename, pdfBuffer);
    console.log('💾 PDF sauvegardé:', filename);
    console.log('\n🎉 Test réussi! Ouvrez le fichier pour vérifier le contenu.');
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Erreur lors du test:', error);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

testPDFGeneration();
