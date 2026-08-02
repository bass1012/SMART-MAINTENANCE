const express = require('express');
const fs = require('fs');
const path = require('path');
const { InterventionImage, Intervention } = require('../models');
const { authenticate, requireRole } = require('../middleware/auth');
const { buildInterventionReadWhere } = require('../policies/interventionAccessPolicy');

const router = express.Router();
const uploadsRoot = path.resolve(__dirname, '../../uploads');

const safeFilename = (rawFilename) => {
  const filename = path.basename(rawFilename || '');
  return filename && filename === rawFilename && /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(filename)
    ? filename
    : null;
};

const sendFileIfPresent = (res, directory, filename) => {
  const filePath = path.resolve(uploadsRoot, directory, filename);
  const allowedDirectory = path.resolve(uploadsRoot, directory);

  if (!filePath.startsWith(`${allowedDirectory}${path.sep}`) || !fs.existsSync(filePath)) {
    return res.status(404).json({ success: false, message: 'Fichier introuvable' });
  }

  res.setHeader('Cache-Control', 'private, max-age=3600');
  return res.sendFile(filePath);
};

// Une photo d'intervention contient des données du client : sa lecture doit
// suivre exactement la même politique que celle de l'intervention associée.
router.get('/interventions/:filename', authenticate, async (req, res, next) => {
  try {
    const filename = safeFilename(req.params.filename);
    if (!filename) {
      return res.status(404).json({ success: false, message: 'Fichier introuvable' });
    }

    const image = await InterventionImage.findOne({
      where: { image_url: `/uploads/interventions/${filename}` },
      attributes: ['intervention_id']
    });
    if (!image) {
      return res.status(404).json({ success: false, message: 'Fichier introuvable' });
    }

    const where = await buildInterventionReadWhere({
      interventionId: image.intervention_id,
      user: req.user
    });
    const intervention = await Intervention.findOne({ where, attributes: ['id'] });
    if (!intervention) {
      // Ne jamais révéler qu'une photo existe hors du périmètre de l'appelant.
      return res.status(404).json({ success: false, message: 'Fichier introuvable' });
    }

    return sendFileIfPresent(res, 'interventions', filename);
  } catch (error) {
    return next(error);
  }
});

// Les documents génériques sont déposés par l'administration et ne sont pas
// associés à une ressource métier permettant une délégation au client.
router.get('/documents/:filename', authenticate, requireRole('admin', 'manager'), (req, res) => {
  const filename = safeFilename(req.params.filename);
  if (!filename) {
    return res.status(404).json({ success: false, message: 'Fichier introuvable' });
  }
  return sendFileIfPresent(res, 'documents', filename);
});

module.exports = router;
