const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const brandController = require('../controllers/brandController');

// Routes publiques
router.get('/', brandController.getAllBrands);
router.get('/:id', brandController.getBrandById);

// Routes protégées (admin seulement)
router.post('/', authenticate, authorize('admin'), brandController.createBrand);
router.put('/:id', authenticate, authorize('admin'), brandController.updateBrand);
router.delete('/:id', authenticate, authorize('admin'), brandController.deleteBrand);

module.exports = router;
