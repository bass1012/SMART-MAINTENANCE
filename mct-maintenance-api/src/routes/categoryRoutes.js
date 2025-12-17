const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const categoryController = require('../controllers/categoryController');

// Routes publiques
router.get('/', categoryController.getAllCategories);
router.get('/:id', categoryController.getCategoryById);

// Routes protégées (admin seulement)
router.post('/', authenticate, authorize('admin'), categoryController.createCategory);
router.put('/:id', authenticate, authorize('admin'), categoryController.updateCategory);
router.delete('/:id', authenticate, authorize('admin'), categoryController.deleteCategory);

module.exports = router;
