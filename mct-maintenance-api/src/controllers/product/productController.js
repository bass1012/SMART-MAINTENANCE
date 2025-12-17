const { Product } = require('../../models');

// Product Controller - Implementation with Sequelize
const getAllProducts = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const where = {};
    if (search) {
      where.nom = { $like: `%${search}%` };
    }
    const { rows: produits, count: total } = await Product.findAndCountAll({
      where,
      offset,
      limit,
      order: [['createdAt', 'DESC']]
    });
    const totalPages = Math.ceil(total / limit);
    res.status(200).json({
      success: true,
      data: produits,
      pagination: {
        total,
        page,
        limit,
        totalPages
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des produits:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des produits',
      error: error.message
    });
  }
};

const getProductById = async (req, res) => {
  try {
    const { id } = req.params;
    const produit = await Product.findByPk(id);
    if (!produit) {
      return res.status(404).json({ success: false, message: 'Produit non trouvé' });
    }
    res.status(200).json({ success: true, data: produit });
  } catch (error) {
    console.error('Erreur lors de la récupération du produit:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du produit',
      error: error.message
    });
  }
};

const createProduct = async (req, res) => {
  try {
    console.log('Reçu pour création produit:', req.body);
    const produit = await Product.create(req.body);
    res.status(201).json({
      success: true,
      data: produit
    });
  } catch (error) {
    console.error('Erreur lors de la création du produit:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du produit',
      error: error.message,
      body: req.body
    });
  }
};

const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const produit = await Product.findByPk(id);
    if (!produit) {
      return res.status(404).json({ success: false, message: 'Produit non trouvé' });
    }
    await produit.update(req.body);
    res.status(200).json({ success: true, data: produit });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du produit:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du produit',
      error: error.message
    });
  }
};

const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const produit = await Product.findByPk(id);
    if (!produit) {
      return res.status(404).json({ success: false, message: 'Produit non trouvé' });
    }
    await produit.destroy();
    res.status(200).json({ success: true, message: 'Produit supprimé' });
  } catch (error) {
    console.error('Erreur lors de la suppression du produit:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression du produit',
      error: error.message
    });
  }
};

module.exports = {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct
};
