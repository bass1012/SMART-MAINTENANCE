// Test du service technicians depuis la console du navigateur
// Coller ce code dans la console du navigateur après connexion

(async () => {
  try {
    console.log('=== TEST SERVICE TECHNICIANS ===');
    
    // Vérifier le token
    const token = localStorage.getItem('token') || sessionStorage.getItem('token');
    console.log('Token présent:', !!token);
    console.log('Token (10 premiers chars):', token?.substring(0, 10));
    
    // Test direct de l'API
    const response = await fetch('/api/admin/technicians', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('Response status:', response.status);
    const data = await response.json();
    console.log('Response data:', data);
    
    if (data.success) {
      console.log('Technicians count:', data.data.technicians.length);
      console.log('First technician:', data.data.technicians[0]);
    }
    
  } catch (error) {
    console.error('Erreur test:', error);
  }
})();