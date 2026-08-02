const express = require('express');
const router = express.Router();
const { getSystemCatalog } = require('../services/systemConfigCatalogService');

/**
 * GET /api/config/catalog
 * Endpoint public / client : Récupère les tarifs, garanties, contacts et contrats configurés sur le serveur
 */
router.get('/catalog', async (req, res) => {
  try {
    const catalog = await getSystemCatalog();
    res.status(200).json({ success: true, data: catalog });
  } catch (error) {
    console.error('❌ Erreur lecture catalogue config:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du catalogue de configuration',
      error: error.message
    });
  }
});

module.exports = router;
