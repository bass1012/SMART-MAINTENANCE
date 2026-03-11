const express = require('express');
const router = express.Router();
const { authenticate, authorize, adminOnly } = require('../middleware/auth');
const brandController = require('../controllers/brandController');

// Routes publiques
router.get('/', brandController.getAllBrands);
router.get('/:id', brandController.getBrandById);

// Routes protégées (admin et manager)
router.post('/', authenticate, authorize('admin', 'manager'), brandController.createBrand);
router.put('/:id', authenticate, authorize('admin', 'manager'), brandController.updateBrand);
router.delete('/:id', authenticate, adminOnly, brandController.deleteBrand);

module.exports = router;
