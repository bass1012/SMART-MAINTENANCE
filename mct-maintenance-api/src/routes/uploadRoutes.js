const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { authenticate } = require('../middleware/auth');
const {
  uploadAvatar,
  uploadProductImage,
  uploadEquipmentImage,
  uploadDocument,
  deleteUploadedFile
} = require('../controllers/uploadController');

// Configuration de multer pour différents types d'uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadPath = 'uploads/';
    
    // Déterminer le dossier selon le type d'upload
    if (req.path.includes('avatar')) {
      uploadPath += 'avatars/';
    } else if (req.path.includes('product')) {
      uploadPath += 'products/';
    } else if (req.path.includes('equipment')) {
      uploadPath += 'equipments/';
    } else if (req.path.includes('document')) {
      uploadPath += 'documents/';
    }
    
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'temp-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// Filtre pour les images
const imageFilter = (req, file, cb) => {
  console.log('📸 Image filter - originalname:', file.originalname);
  console.log('📸 Image filter - mimetype:', file.mimetype);
  
  const allowedExtensions = /jpeg|jpg|png|gif|webp/;
  const allowedMimetypes = /image\/(jpeg|jpg|png|gif|webp)/;
  
  const extname = allowedExtensions.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedMimetypes.test(file.mimetype);
  
  console.log('📸 Extension valide:', extname);
  console.log('📸 Mimetype valide:', mimetype);
  
  // Accepter si au moins l'extension OU le mimetype est valide
  if (mimetype || extname) {
    return cb(null, true);
  } else {
    console.log('❌ Fichier rejeté - Extension:', path.extname(file.originalname), 'Mimetype:', file.mimetype);
    cb(new Error('Seules les images sont autorisées (jpeg, jpg, png, gif, webp)'));
  }
};

// Filtre pour les documents
const documentFilter = (req, file, cb) => {
  const allowedTypes = /pdf|doc|docx|xls|xlsx|txt/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  
  if (extname) {
    return cb(null, true);
  } else {
    cb(new Error('Type de document non autorisé'));
  }
};

const uploadImage = multer({
  storage: storage,
  fileFilter: imageFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB max
});

const uploadDoc = multer({
  storage: storage,
  fileFilter: documentFilter,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB max
});

// Middleware pour accepter plusieurs noms de champs
const handleProductImage = (req, res, next) => {
  const upload = uploadImage.fields([
    { name: 'image', maxCount: 1 },
    { name: 'productImage', maxCount: 1 }
  ]);
  
  upload(req, res, (err) => {
    if (err) return next(err);
    
    // Normaliser le fichier
    if (req.files) {
      req.file = req.files.image?.[0] || req.files.productImage?.[0];
    }
    next();
  });
};

const handleEquipmentImage = (req, res, next) => {
  const upload = uploadImage.fields([
    { name: 'image', maxCount: 1 },
    { name: 'equipmentImage', maxCount: 1 }
  ]);
  
  upload(req, res, (err) => {
    if (err) return next(err);
    
    // Normaliser le fichier
    if (req.files) {
      req.file = req.files.image?.[0] || req.files.equipmentImage?.[0];
    }
    next();
  });
};

// Routes d'upload (authentification requise)
router.post('/avatar', authenticate, uploadImage.single('avatar'), uploadAvatar);
router.post('/product', authenticate, handleProductImage, uploadProductImage);
router.post('/equipment', authenticate, handleEquipmentImage, uploadEquipmentImage);
router.post('/document', authenticate, uploadDoc.single('document'), uploadDocument);

// Route de suppression
router.delete('/:type/:filename', authenticate, deleteUploadedFile);

module.exports = router;
