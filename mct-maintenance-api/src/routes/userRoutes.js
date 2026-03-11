const express = require('express');
const { authenticate, adminOnly } = require('../middleware/auth');
const userController = require('../controllers/user/userController');

const router = express.Router();

// List & filter users
router.get('/', authenticate, userController.listUsers);
// Get one
router.get('/:id', authenticate, userController.getUser);
// Update full (limited fields)
router.put('/:id', authenticate, userController.updateUser);
// Update status only
router.patch('/:id/status', authenticate, userController.updateStatus);
// Delete (admin only)
router.delete('/:id', authenticate, adminOnly, userController.deleteUser);

module.exports = router;