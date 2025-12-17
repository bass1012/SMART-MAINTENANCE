const path = require('path');
const { processImage, generateThumbnail, deleteFile } = require('../services/uploadService');
const User = require('../models/User');
const Product = require('../models/Product');
const Equipment = require('../models/Equipment');

// Upload avatar utilisateur
const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni' });
    }

    const userId = req.user.id;
    const inputPath = req.file.path;
    const filename = `avatar-${userId}-${Date.now()}.jpg`;
    const outputPath = path.join(path.dirname(inputPath), filename);

    // Compression et redimensionnement
    await processImage(inputPath, outputPath, {
      width: 400,
      height: 400,
      quality: 85,
      fit: 'cover'
    });

    // Génération du thumbnail
    const thumbnailPath = path.join(
      path.dirname(outputPath),
      `thumb-${filename}`
    );
    await generateThumbnail(outputPath, thumbnailPath, 150);

    // Mise à jour de l'utilisateur
    const user = await User.findByPk(userId);
    if (!user) {
      await deleteFile(outputPath);
      await deleteFile(thumbnailPath);
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Supprimer l'ancien avatar si existant
    if (user.profile_image) {
      const oldAvatarPath = path.join(__dirname, '../../uploads/avatars', user.profile_image);
      const oldThumbPath = path.join(__dirname, '../../uploads/avatars', `thumb-${user.profile_image}`);
      await deleteFile(oldAvatarPath);
      await deleteFile(oldThumbPath);
    }

    user.profile_image = filename;
    await user.save();
    
    console.log(`✅ Avatar sauvegardé en DB pour userId ${userId}: ${filename}`);

    res.json({
      message: 'Avatar uploadé avec succès',
      avatar: filename,
      thumbnail: `thumb-${filename}`,
      url: `/uploads/avatars/${filename}`,
      thumbnailUrl: `/uploads/avatars/thumb-${filename}`
    });
  } catch (error) {
    console.error('Erreur upload avatar:', error);
    res.status(500).json({ error: 'Erreur lors de l\'upload de l\'avatar' });
  }
};

// Upload image produit
const uploadProductImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'Aucun fichier fourni' });
    }

    const { productId } = req.body;
    
    const inputPath = req.file.path;
    const filename = `product-${productId || 'new'}-${Date.now()}.jpg`;
    const outputPath = path.join(path.dirname(inputPath), filename);

    // Compression et redimensionnement
    await processImage(inputPath, outputPath, {
      width: 800,
      height: 800,
      quality: 80,
      fit: 'inside'
    });

    // Génération du thumbnail
    const thumbnailPath = path.join(
      path.dirname(outputPath),
      `thumb-${filename}`
    );
    await generateThumbnail(outputPath, thumbnailPath, 200);

    // Si un productId est fourni, mettre à jour le produit
    if (productId) {
      const product = await Product.findByPk(productId);
      if (product) {
        // Supprimer l'ancienne image si existante
        if (product.imageUrl) {
          const oldImagePath = path.join(__dirname, '../../uploads/products', product.imageUrl);
          const oldThumbPath = path.join(__dirname, '../../uploads/products', `thumb-${product.imageUrl}`);
          await deleteFile(oldImagePath);
          await deleteFile(oldThumbPath);
        }

        product.imageUrl = filename;
        await product.save();
      }
    }

    res.json({
      success: true,
      message: 'Image produit uploadée avec succès',
      image: filename,
      thumbnail: `thumb-${filename}`,
      url: `/uploads/products/${filename}`,
      thumbnailUrl: `/uploads/products/thumb-${filename}`,
      filename: filename
    });
  } catch (error) {
    console.error('Erreur upload image produit:', error);
    res.status(500).json({ success: false, error: 'Erreur lors de l\'upload de l\'image' });
  }
};

// Upload image équipement
const uploadEquipmentImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni' });
    }

    const { equipmentId } = req.body;
    if (!equipmentId) {
      await deleteFile(req.file.path);
      return res.status(400).json({ error: 'ID équipement manquant' });
    }

    const inputPath = req.file.path;
    const filename = `equipment-${equipmentId}-${Date.now()}.jpg`;
    const outputPath = path.join(path.dirname(inputPath), filename);

    // Compression et redimensionnement
    await processImage(inputPath, outputPath, {
      width: 800,
      height: 800,
      quality: 80,
      fit: 'inside'
    });

    // Génération du thumbnail
    const thumbnailPath = path.join(
      path.dirname(outputPath),
      `thumb-${filename}`
    );
    await generateThumbnail(outputPath, thumbnailPath, 200);

    // Mise à jour de l'équipement
    const equipment = await Equipment.findByPk(equipmentId);
    if (!equipment) {
      await deleteFile(outputPath);
      await deleteFile(thumbnailPath);
      return res.status(404).json({ error: 'Équipement non trouvé' });
    }

    // Supprimer l'ancienne image si existante
    if (equipment.imageUrl) {
      const oldImagePath = path.join(__dirname, '../../uploads/equipments', equipment.imageUrl);
      const oldThumbPath = path.join(__dirname, '../../uploads/equipments', `thumb-${equipment.imageUrl}`);
      await deleteFile(oldImagePath);
      await deleteFile(oldThumbPath);
    }

    equipment.imageUrl = filename;
    await equipment.save();

    res.json({
      message: 'Image équipement uploadée avec succès',
      image: filename,
      thumbnail: `thumb-${filename}`,
      url: `/uploads/equipments/${filename}`,
      thumbnailUrl: `/uploads/equipments/thumb-${filename}`
    });
  } catch (error) {
    console.error('Erreur upload image équipement:', error);
    res.status(500).json({ error: 'Erreur lors de l\'upload de l\'image' });
  }
};

// Upload document
const uploadDocument = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni' });
    }

    const { type, relatedId } = req.body;
    const filename = req.file.filename;

    res.json({
      message: 'Document uploadé avec succès',
      document: filename,
      url: `/uploads/documents/${filename}`,
      type: type || 'general',
      relatedId: relatedId || null
    });
  } catch (error) {
    console.error('Erreur upload document:', error);
    res.status(500).json({ error: 'Erreur lors de l\'upload du document' });
  }
};

// Supprimer un fichier
const deleteUploadedFile = async (req, res) => {
  try {
    const { type, filename } = req.params;
    
    let filePath;
    switch (type) {
      case 'avatar':
        filePath = path.join(__dirname, '../../uploads/avatars', filename);
        break;
      case 'product':
        filePath = path.join(__dirname, '../../uploads/products', filename);
        break;
      case 'equipment':
        filePath = path.join(__dirname, '../../uploads/equipments', filename);
        break;
      case 'document':
        filePath = path.join(__dirname, '../../uploads/documents', filename);
        break;
      default:
        return res.status(400).json({ error: 'Type de fichier invalide' });
    }

    const deleted = await deleteFile(filePath);
    
    if (deleted) {
      res.json({ message: 'Fichier supprimé avec succès' });
    } else {
      res.status(404).json({ error: 'Fichier non trouvé' });
    }
  } catch (error) {
    console.error('Erreur suppression fichier:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression du fichier' });
  }
};

module.exports = {
  uploadAvatar,
  uploadProductImage,
  uploadEquipmentImage,
  uploadDocument,
  deleteUploadedFile
};
