const { Brand } = require('../models');

// Récupérer toutes les marques
const getAllBrands = async (req, res) => {
  try {
    const brands = await Brand.findAll({
      where: { actif: true },
      order: [['nom', 'ASC']]
    });
    
    res.status(200).json({
      success: true,
      data: brands
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des marques:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des marques',
      error: error.message
    });
  }
};

// Récupérer une marque par ID
const getBrandById = async (req, res) => {
  try {
    const { id } = req.params;
    const brand = await Brand.findByPk(id);
    
    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Marque non trouvée'
      });
    }
    
    res.status(200).json({
      success: true,
      data: brand
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de la marque:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la marque',
      error: error.message
    });
  }
};

// Créer une nouvelle marque
const createBrand = async (req, res) => {
  try {
    const brand = await Brand.create(req.body);
    
    res.status(201).json({
      success: true,
      data: brand,
      message: 'Marque créée avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la création de la marque:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la marque',
      error: error.message
    });
  }
};

// Mettre à jour une marque
const updateBrand = async (req, res) => {
  try {
    const { id } = req.params;
    const brand = await Brand.findByPk(id);
    
    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Marque non trouvée'
      });
    }
    
    await brand.update(req.body);
    
    res.status(200).json({
      success: true,
      data: brand,
      message: 'Marque mise à jour avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de la marque:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de la marque',
      error: error.message
    });
  }
};

// Supprimer une marque
const deleteBrand = async (req, res) => {
  try {
    const { id } = req.params;
    const brand = await Brand.findByPk(id);
    
    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Marque non trouvée'
      });
    }
    
    await brand.destroy();
    
    res.status(200).json({
      success: true,
      message: 'Marque supprimée avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la suppression de la marque:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de la marque',
      error: error.message
    });
  }
};

module.exports = {
  getAllBrands,
  getBrandById,
  createBrand,
  updateBrand,
  deleteBrand
};
