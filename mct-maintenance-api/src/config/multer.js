/**
 * Configuration Multer pour l'upload d'images
 * Gère l'upload des images d'interventions
 */

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Créer le dossier uploads si n'existe pas
const uploadDir = path.join(__dirname, '../../uploads/interventions');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  console.log('📁 Dossier uploads/interventions créé');
}

// Configuration du stockage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Générer un nom unique : intervention-timestamp-random.ext
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const filename = `intervention-${uniqueSuffix}${ext}`;
    
    console.log(`📸 Upload: ${file.originalname} → ${filename}`);
    cb(null, filename);
  }
});

// Filtrage des types de fichiers autorisés
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Seules les images (JPEG, PNG, GIF) sont autorisées'));
  }
};

// Configuration multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max par image
    files: 10, // Maximum 10 images
    fieldSize: 10 * 1024 * 1024 // 10MB max pour les champs
  },
  fileFilter: fileFilter
});

// Gestion des erreurs multer
upload.onError = (err, next) => {
  console.error('❌ Erreur Multer:', err);
  next(err);
};

module.exports = upload;
