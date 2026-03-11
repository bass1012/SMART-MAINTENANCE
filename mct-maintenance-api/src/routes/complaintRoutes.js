const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const complaintController = require('../controllers/complaintController');
console.log('DEBUG complaintController keys:', Object.keys(complaintController));
const { authenticate, authorize, adminOnly } = require('../middleware/auth');

// Validation pour la création de réclamation
const createComplaintValidation = [
  body('customerId')
    .isInt({ min: 1 })
    .withMessage('ID client requis et doit être un entier positif'),
  body('subject')
    .trim()
    .isLength({ min: 1, max: 255 })
    .withMessage('Le sujet est requis et doit faire maximum 255 caractères'),
  body('description')
    .trim()
    .isLength({ min: 1 })
    .withMessage('La description est requise'),
  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high', 'urgent', 'critical']).withMessage('Priorité invalide'),
  body('category')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Catégorie doit faire maximum 100 caractères'),
  body('orderId')
    .optional()
    .isInt({ min: 1 }).withMessage('ID commande doit être un entier positif'),
  body('productId')
    .optional()
    .isInt({ min: 1 }).withMessage('ID produit doit être un entier positif'),
  body('interventionId')
    .optional()
    .isInt({ min: 1 }).withMessage('ID intervention doit être un entier positif')
];

// Validation pour la mise à jour de réclamation
const updateComplaintValidation = [
  body('subject')
    .optional()
    .trim()
    .isLength({ min: 1, max: 255 }).withMessage('Le sujet doit faire maximum 255 caractères'),
  body('description')
    .optional()
    .trim()
    .isLength({ min: 1 }).withMessage('La description ne peut pas être vide'),
  body('status')
    .optional()
    .isIn(['open', 'in_progress', 'resolved', 'closed', 'cancelled', 'rejected', 'on_hold']).withMessage('Statut invalide'),
  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high', 'urgent', 'critical']).withMessage('Priorité invalide'),
  body('category')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Catégorie doit faire maximum 100 caractères'),
  body('resolution')
    .optional()
    .trim(),
  body('assignedTo')
    .optional()
    .isInt({ min: 1 }).withMessage('Assigné à doit être un ID utilisateur valide')
];

// Validation pour la mise à jour du statut
const updateStatusValidation = [
  body('status')
    .isIn(['open', 'in_progress', 'resolved', 'closed', 'cancelled', 'rejected', 'on_hold']).withMessage('Statut requis et doit être valide'),
  body('resolution')
    .optional()
    .trim()
];

// Routes publiques (pour les clients)
router.get('/', authenticate, complaintController.getComplaints);
router.get('/:id', authenticate, complaintController.getComplaintById);
router.post('/', authenticate, createComplaintValidation, complaintController.createComplaint);

// Routes pour les clients (peuvent modifier leurs propres réclamations)
router.put('/:id', authenticate, updateComplaintValidation, complaintController.updateComplaint);

// Routes admin/tech/manager (peuvent modifier le statut et assigner)
router.patch('/:id/status', authenticate, authorize('admin', 'manager', 'technician'), updateStatusValidation, complaintController.updateComplaintStatus);

// Routes admin uniquement (suppression)
router.delete('/:id', authenticate, adminOnly, complaintController.deleteComplaint);

// POST /api/complaints/:id/notes - Ajouter une note à une réclamation (Admin/Tech)
router.post('/:id/notes', authenticate, authorize('admin', 'technician'), async (req, res) => {
  try {
    const { Complaint, ComplaintNote, User, CustomerProfile } = require('../models');
    const { notifyComplaintNoteAdded } = require('../services/notificationHelpers');
    const { id } = req.params;
    const { note, isInternal } = req.body;
    const userId = req.user.id;
    
    console.log(`📝 POST /api/complaints/${id}/notes - Admin/Tech User ID:`, userId);
    
    if (!note || note.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Le contenu de la note est requis',
      });
    }
    
    // Récupérer la réclamation avec le customer
    const complaint = await Complaint.findByPk(id, {
      include: [{
        model: CustomerProfile,
        as: 'customer',
        include: [{
          model: User,
          as: 'user'
        }]
      }]
    });
    
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Réclamation non trouvée',
      });
    }
    
    // Créer la note
    const complaintNote = await ComplaintNote.create({
      complaintId: id,
      userId: userId,
      note: note.trim(),
      isInternal: isInternal || false // Note visible par défaut
    });
    
    // Récupérer la note avec les informations de l'auteur
    const noteWithUser = await ComplaintNote.findByPk(complaintNote.id, {
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'first_name', 'last_name', 'role']
        }
      ]
    });
    
    // Notifier le client si la note n'est pas interne
    if (!isInternal && complaint.customer && complaint.customer.user) {
      try {
        const author = await User.findByPk(userId);
        await notifyComplaintNoteAdded(
          complaint, 
          complaint.customer.user, 
          note.trim(),
          author
        );
        console.log(`✅ Notification envoyée au client pour la note sur réclamation ${id}`);
      } catch (notifError) {
        console.error('⚠️  Erreur notification ajout note:', notifError);
        // Ne pas bloquer la création de la note
      }
    }
    
    console.log(`✅ Note added to complaint ${id} by ${req.user.role}`);
    
    res.status(201).json({
      success: true,
      message: 'Note ajoutée avec succès',
      data: noteWithUser
    });
  } catch (error) {
    console.error('❌ Error adding note to complaint:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'ajout de la note',
      error: error.message
    });
  }
});

module.exports = router;