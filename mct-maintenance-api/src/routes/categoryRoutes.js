const express = require('express');
const router = express.Router();
const { authenticate, authorize, adminOnly } = require('../middleware/auth');
const categoryController = require('../controllers/categoryController');

// Routes publiques
router.get('/', categoryController.getAllCategories);
router.get('/:id', categoryController.getCategoryById);

// Routes protégées (admin et manager)
router.post('/', authenticate, authorize('admin', 'manager'), categoryController.createCategory);
router.put('/:id', authenticate, authorize('admin', 'manager'), categoryController.updateCategory);
router.delete('/:id', authenticate, adminOnly, categoryController.deleteCategory);

module.exports = router;
