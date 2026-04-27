const path = require('path');
const fs = require('fs');
const { processImage, generateThumbnail, deleteFile } = require('../services/uploadService');
const User = require('../models/User');
const Product = require('../models/Product');
const Equipment = require('../models/Equipment');

/**
 * Lit un fichier image compressé et retourne un data URL base64.
 * Supprime le fichier après lecture.
 */
const fileToBase64DataUrl = async (filePath) => {
  const buffer = fs.readFileSync(filePath);
  const ext = path.extname(filePath).toLowerCase().replace('.', '');
  const mime = ext === 'jpg' ? 'jpeg' : ext; // jpg → jpeg
  const dataUrl = `data:image/${mime};base64,${buffer.toString('base64')}`;
  await deleteFile(filePath);
  return dataUrl;
};

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

    // Supprimer le fichier temporaire d'entrée
    await deleteFile(inputPath);

    // Convertir l'image compressée en base64 data URL puis supprimer le fichier
    const dataUrl = await fileToBase64DataUrl(outputPath);

    // Mise à jour de l'utilisateur
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    user.profile_image = dataUrl;
    await user.save();

    console.log(`✅ Avatar sauvegardé en DB (base64) pour userId ${userId}`);

    res.json({
      message: 'Avatar uploadé avec succès',
      url: dataUrl,
      thumbnailUrl: dataUrl
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

    // Supprimer le fichier temporaire d'entrée
    await deleteFile(inputPath);

    // Convertir en base64 data URL puis supprimer le fichier
    const dataUrl = await fileToBase64DataUrl(outputPath);

    // Si un productId est fourni, mettre à jour le produit
    if (productId) {
      const product = await Product.findByPk(productId);
      if (product) {
        // Ajouter l'image à la liste JSON
        const images = Array.isArray(product.images) ? product.images : [];
        images.push(dataUrl);
        product.images = images;
        await product.save();
      }
    }

    res.json({
      success: true,
      message: 'Image produit uploadée avec succès',
      url: dataUrl,
      thumbnailUrl: dataUrl,
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

    // Supprimer le fichier temporaire d'entrée
    await deleteFile(inputPath);

    // Convertir en base64 data URL puis supprimer le fichier
    const dataUrl = await fileToBase64DataUrl(outputPath);

    // Mise à jour de l'équipement
    const equipment = await Equipment.findByPk(equipmentId);
    if (!equipment) {
      return res.status(404).json({ error: 'Équipement non trouvé' });
    }

    equipment.imageUrl = dataUrl;
    await equipment.save();

    console.log(`✅ Image équipement ${equipmentId} sauvegardée en DB (base64)`);

    res.json({
      message: 'Image équipement uploadée avec succès',
      url: dataUrl,
      thumbnailUrl: dataUrl
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
    const { filename } = req.params;
    // Normaliser : accepter 'products'/'product', 'equipments'/'equipment', 'avatars'/'avatar'
    const rawType = req.params.type;
    const type = rawType.replace(/s$/, ''); // strip trailing 's'
    
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
