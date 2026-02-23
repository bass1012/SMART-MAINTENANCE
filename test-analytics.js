// Test du système Analytics & Reporting
const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

// Remplacez par un token admin valide
const ADMIN_TOKEN = 'YOUR_ADMIN_TOKEN_HERE';

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Authorization': `Bearer ${ADMIN_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

async function testAnalytics() {
  console.log('🧪 Tests Analytics & Reporting\n');

  try {
    // 1. Test statistiques globales
    console.log('1️⃣  Test: Statistiques globales');
    const statsResponse = await api.get('/admin/analytics/stats');
    console.log('✅ Statistiques globales:', {
      interventions: statsResponse.data.data.interventions.total,
      orders: statsResponse.data.data.orders.total,
      revenue: statsResponse.data.data.orders.revenue,
      technicians: statsResponse.data.data.users.technicians
    });
    console.log('');

    // 2. Test performance techniciens
    console.log('2️⃣  Test: Performance techniciens');
    const techResponse = await api.get('/admin/analytics/technicians');
    console.log('✅ Performance:', techResponse.data.data.slice(0, 3));
    console.log('');

    // 3. Test graphiques - interventions timeline
    console.log('3️⃣  Test: Graphique timeline interventions');
    const chartResponse = await api.get('/admin/analytics/charts/interventions-timeline?period=3');
    console.log('✅ Données graphique:', chartResponse.data.data.slice(0, 5));
    console.log('');

    // 4. Test graphiques - revenue timeline
    console.log('4️⃣  Test: Graphique timeline chiffre d\'affaires');
    const revenueResponse = await api.get('/admin/analytics/charts/revenue-timeline?period=3');
    console.log('✅ Données revenue:', revenueResponse.data.data.slice(0, 5));
    console.log('');

    // 5. Test graphiques - par type
    console.log('5️⃣  Test: Graphique répartition par type');
    const typeResponse = await api.get('/admin/analytics/charts/interventions-by-type');
    console.log('✅ Répartition par type:', typeResponse.data.data);
    console.log('');

    // 6. Test graphiques - satisfaction
    console.log('6️⃣  Test: Graphique satisfaction client');
    const satisfactionResponse = await api.get('/admin/analytics/charts/customer-satisfaction');
    console.log('✅ Satisfaction:', satisfactionResponse.data.data);
    console.log('');

    // 7. Test graphiques - top produits
    console.log('7️⃣  Test: Top produits');
    const productsResponse = await api.get('/admin/analytics/charts/top-products');
    console.log('✅ Top produits:', productsResponse.data.data.slice(0, 5));
    console.log('');

    console.log('✅ TOUS LES TESTS SONT PASSÉS!\n');
    console.log('📊 Exports disponibles:');
    console.log('  - Excel: GET /admin/analytics/export/excel');
    console.log('  - PDF: GET /admin/analytics/export/pdf');
    console.log('\n💡 Pour tester les exports, utilisez:');
    console.log('  curl -X GET "http://localhost:5000/admin/analytics/export/excel" \\');
    console.log('    -H "Authorization: Bearer YOUR_TOKEN" --output rapport.xlsx');

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error.message);
    if (error.response) {
      console.error('Détails:', error.response.data);
    }
  }
}

// Lancer les tests
testAnalytics();
