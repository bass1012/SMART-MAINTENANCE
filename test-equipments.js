#!/usr/bin/env node
/**
 * Test script for equipment management endpoints
 * Tests: Create, Read, Update, Delete operations
 */

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3000';
let authToken = '';
let createdEquipmentId = null;

// Test credentials - use a real customer account
const TEST_CREDENTIALS = {
  email: 'client@test.com',  // Change to a real customer email
  password: 'password123'
};

// Color codes for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function logSection(title) {
  console.log('\n' + '='.repeat(60));
  log(title, colors.cyan);
  console.log('='.repeat(60));
}

function logSuccess(message) {
  log(`✅ ${message}`, colors.green);
}

function logError(message) {
  log(`❌ ${message}`, colors.red);
}

function logInfo(message) {
  log(`ℹ️  ${message}`, colors.blue);
}

// Test 1: Login as customer
async function testLogin() {
  logSection('TEST 1: Login as Customer');
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, TEST_CREDENTIALS);
    
    if (response.data.token) {
      authToken = response.data.token;
      logSuccess('Login successful');
      logInfo(`Token: ${authToken.substring(0, 20)}...`);
      return true;
    } else {
      logError('No token received');
      return false;
    }
  } catch (error) {
    logError(`Login failed: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// Test 2: Get user's equipments (should be empty initially)
async function testGetEquipments() {
  logSection('TEST 2: Get My Equipments');
  try {
    const response = await axios.get(`${BASE_URL}/api/equipments/my-equipments`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    logSuccess(`Retrieved ${response.data.equipments?.length || 0} equipment(s)`);
    if (response.data.equipments?.length > 0) {
      logInfo('Existing equipments:');
      response.data.equipments.forEach((eq, idx) => {
        console.log(`  ${idx + 1}. ${eq.name} (${eq.type}) - ${eq.serial_number || 'No S/N'}`);
      });
    }
    return true;
  } catch (error) {
    logError(`Get equipments failed: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// Test 3: Create new equipment
async function testCreateEquipment() {
  logSection('TEST 3: Create New Equipment');
  
  const newEquipment = {
    name: 'Climatiseur Test',
    type: 'climatiseur',
    brand: 'Samsung',
    model: 'AR12TXHQASINEU',
    serial_number: `TEST-${Date.now()}`,
    location: 'Salon',
    installation_date: '2024-01-15',
    status: 'active',
    notes: 'Équipement de test - à supprimer'
  };
  
  try {
    const response = await axios.post(`${BASE_URL}/api/equipments`, newEquipment, {
      headers: { 
        Authorization: `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.data.success && response.data.equipment) {
      createdEquipmentId = response.data.equipment.id;
      logSuccess(`Equipment created with ID: ${createdEquipmentId}`);
      logInfo(`Name: ${response.data.equipment.name}`);
      logInfo(`Serial: ${response.data.equipment.serial_number}`);
      return true;
    } else {
      logError('Create failed - no equipment returned');
      return false;
    }
  } catch (error) {
    logError(`Create equipment failed: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// Test 4: Get specific equipment
async function testGetSingleEquipment() {
  if (!createdEquipmentId) {
    logError('TEST 4: Skipped - no equipment ID');
    return false;
  }
  
  logSection('TEST 4: Get Single Equipment');
  try {
    const response = await axios.get(`${BASE_URL}/api/equipments/${createdEquipmentId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    logSuccess('Equipment retrieved successfully');
    logInfo(`Name: ${response.data.equipment.name}`);
    logInfo(`Type: ${response.data.equipment.type}`);
    logInfo(`Status: ${response.data.equipment.status}`);
    return true;
  } catch (error) {
    logError(`Get equipment failed: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// Test 5: Update equipment
async function testUpdateEquipment() {
  if (!createdEquipmentId) {
    logError('TEST 5: Skipped - no equipment ID');
    return false;
  }
  
  logSection('TEST 5: Update Equipment');
  
  const updates = {
    location: 'Chambre 1',
    notes: 'Équipement de test - mis à jour',
    status: 'maintenance'
  };
  
  try {
    const response = await axios.put(`${BASE_URL}/api/equipments/${createdEquipmentId}`, updates, {
      headers: { 
        Authorization: `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    logSuccess('Equipment updated successfully');
    logInfo(`New location: ${response.data.equipment.location}`);
    logInfo(`New status: ${response.data.equipment.status}`);
    return true;
  } catch (error) {
    logError(`Update equipment failed: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// Test 6: Delete equipment
async function testDeleteEquipment() {
  if (!createdEquipmentId) {
    logError('TEST 6: Skipped - no equipment ID');
    return false;
  }
  
  logSection('TEST 6: Delete Equipment');
  try {
    const response = await axios.delete(`${BASE_URL}/api/equipments/${createdEquipmentId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    logSuccess('Equipment deleted successfully');
    return true;
  } catch (error) {
    logError(`Delete equipment failed: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// Test 7: Verify deletion
async function testVerifyDeletion() {
  if (!createdEquipmentId) {
    logError('TEST 7: Skipped - no equipment ID');
    return false;
  }
  
  logSection('TEST 7: Verify Deletion');
  try {
    await axios.get(`${BASE_URL}/api/equipments/${createdEquipmentId}`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    logError('Equipment still exists after deletion');
    return false;
  } catch (error) {
    if (error.response?.status === 404) {
      logSuccess('Equipment successfully deleted (404 confirmed)');
      return true;
    } else {
      logError(`Unexpected error: ${error.message}`);
      return false;
    }
  }
}

// Main test runner
async function runTests() {
  console.clear();
  log('\n🧪 EQUIPMENT MANAGEMENT API TESTS', colors.cyan);
  log('====================================\n', colors.cyan);
  
  const results = {
    total: 0,
    passed: 0,
    failed: 0
  };
  
  const tests = [
    testLogin,
    testGetEquipments,
    testCreateEquipment,
    testGetSingleEquipment,
    testUpdateEquipment,
    testDeleteEquipment,
    testVerifyDeletion
  ];
  
  for (const test of tests) {
    results.total++;
    const passed = await test();
    if (passed) {
      results.passed++;
    } else {
      results.failed++;
    }
    await new Promise(resolve => setTimeout(resolve, 500)); // Small delay between tests
  }
  
  // Summary
  logSection('TEST SUMMARY');
  log(`Total Tests: ${results.total}`, colors.blue);
  log(`Passed: ${results.passed}`, colors.green);
  log(`Failed: ${results.failed}`, results.failed > 0 ? colors.red : colors.green);
  log(`Success Rate: ${((results.passed / results.total) * 100).toFixed(1)}%\n`, 
      results.failed === 0 ? colors.green : colors.yellow);
  
  process.exit(results.failed === 0 ? 0 : 1);
}

// Run tests
runTests().catch(error => {
  logError(`Test suite error: ${error.message}`);
  process.exit(1);
});
