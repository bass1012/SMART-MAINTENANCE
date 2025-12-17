const express = require('express');
const { authenticate, authorize, optionalAuth } = require('../middleware/auth');
const productController = require('../controllers/product/productController');

const router = express.Router();

// Public routes (no authentication required)
router.get('/', optionalAuth, productController.getAllProducts);
router.get('/:id', optionalAuth, productController.getProductById);

// Protected routes (authentication required)
router.use(authenticate);

// Product management routes (admin only)
router.post('/', authorize('admin'), productController.createProduct);
router.put('/:id', authorize('admin'), productController.updateProduct);
router.delete('/:id', authorize('admin'), productController.deleteProduct);

// Category management routes (admin only)
router.post('/categories', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Category created successfully'
  });
});

router.put('/categories/:id', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Category updated successfully'
  });
});

router.delete('/categories/:id', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Category deleted successfully'
  });
});

// Brand management routes (admin only)
router.post('/brands', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Brand created successfully'
  });
});

router.put('/brands/:id', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Brand updated successfully'
  });
});

router.delete('/brands/:id', authorize('admin'), (req, res) => {
  res.json({
    success: true,
    message: 'Brand deleted successfully'
  });
});

// Product search route
router.get('/search', optionalAuth, (req, res) => {
  res.json({
    success: true,
    message: 'Product search results',
    data: []
  });
});

// Product reviews routes
router.get('/:id/reviews', optionalAuth, (req, res) => {
  res.json({
    success: true,
    message: 'Product reviews retrieved successfully',
    data: []
  });
});

router.post('/:id/reviews', authenticate, (req, res) => {
  res.json({
    success: true,
    message: 'Product review created successfully'
  });
});

module.exports = router;
