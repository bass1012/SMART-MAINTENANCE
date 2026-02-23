/**
 * Test Script - Planification Automatique
 * Teste les endpoints /suggest-technicians et /auto-assign
 */

const axios = require('axios');

const API_URL = 'http://localhost:3000/api';
const AUTH_TOKEN = 'YOUR_TOKEN_HERE'; // Remplacer par un vrai token admin

// Headers
const headers = {
  'Authorization': `Bearer ${AUTH_TOKEN}`,
  'Content-Type': 'application/json'
};

async function testSuggestTechnicians(interventionId) {
  console.log(`\n🧪 Test 1: Suggestions pour intervention ${interventionId}`);
  
  try {
    const response = await axios.post(
      `${API_URL}/interventions/${interventionId}/suggest-technicians`,
      {
        max_results: 5,
        weights: {
          distance: 30,
          skills: 25,
          availability: 20,
          workload: 15,
          performance: 10
        }
      },
      { headers }
    );

    console.log('✅ Succès!');
    console.log(`📊 ${response.data.data.suggestions.length} suggestions générées`);
    console.log(`⏱️  Temps calcul: ${response.data.data.computation_time_ms}ms`);
    
    response.data.data.suggestions.forEach((suggestion, index) => {
      console.log(`\n${index + 1}. ${suggestion.name}`);
      console.log(`   Score total: ${suggestion.total_score}/100`);
      console.log(`   Distance: ${suggestion.details.distance_km} km (${suggestion.details.distance_score}/100)`);
      console.log(`   Compétences: ${suggestion.details.skills_score}/100`);
      console.log(`   Disponibilité: ${suggestion.details.availability_score}/100`);
      console.log(`   Charge travail: ${suggestion.details.workload_score}/100`);
      console.log(`   Performance: ${suggestion.details.performance_score}/100 (${suggestion.details.avg_rating}/5)`);
    });

    return response.data;

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return null;
  }
}

async function testAutoAssign(interventionId) {
  console.log(`\n🧪 Test 2: Auto-assignation intervention ${interventionId}`);
  
  try {
    const response = await axios.post(
      `${API_URL}/interventions/${interventionId}/auto-assign`,
      {},
      { headers }
    );

    console.log('✅ Succès!');
    console.log(`👤 Technicien assigné: ${response.data.data.assigned_technician.name}`);
    console.log(`📧 Email: ${response.data.data.assigned_technician.email}`);
    console.log(`📊 Score: ${response.data.data.score}/100`);
    console.log(`🕐 Assigné à: ${response.data.data.assigned_at}`);

    return response.data;

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return null;
  }
}

// Exécution des tests
async function runTests() {
  console.log('🚀 Démarrage tests Planification Automatique\n');
  console.log('=' .repeat(60));

  // Remplacer par un vrai ID d'intervention non assignée
  const testInterventionId = 143;

  // Test 1: Suggestions
  await testSuggestTechnicians(testInterventionId);

  console.log('\n' + '='.repeat(60));

  // Test 2: Auto-assignation (commenter si déjà testé)
  // await testAutoAssign(testInterventionId);

  console.log('\n' + '='.repeat(60));
  console.log('\n✅ Tests terminés\n');
}

// Lancer les tests
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { testSuggestTechnicians, testAutoAssign };
