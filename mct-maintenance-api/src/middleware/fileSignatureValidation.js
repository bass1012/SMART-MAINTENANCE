const fs = require('fs');
const path = require('path');

const startsWith = (buffer, bytes) => bytes.every((byte, index) => buffer[index] === byte);
const ascii = (buffer, start, end) => buffer.subarray(start, end).toString('ascii');

const signatureValidators = {
  '.jpg': (buffer) => startsWith(buffer, [0xff, 0xd8, 0xff]),
  '.jpeg': (buffer) => startsWith(buffer, [0xff, 0xd8, 0xff]),
  '.png': (buffer) => startsWith(buffer, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  '.gif': (buffer) => ['GIF87a', 'GIF89a'].includes(ascii(buffer, 0, 6)),
  '.webp': (buffer) => ascii(buffer, 0, 4) === 'RIFF' && ascii(buffer, 8, 12) === 'WEBP',
  '.pdf': (buffer) => ascii(buffer, 0, 5) === '%PDF-',
  '.doc': (buffer) => startsWith(buffer, [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1]),
  '.xls': (buffer) => startsWith(buffer, [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1]),
  '.docx': (buffer) => startsWith(buffer, [0x50, 0x4b, 0x03, 0x04]),
  '.xlsx': (buffer) => startsWith(buffer, [0x50, 0x4b, 0x03, 0x04]),
  '.mp4': (buffer) => ascii(buffer, 4, 8) === 'ftyp',
  '.mov': (buffer) => ascii(buffer, 4, 8) === 'ftyp',
  '.avi': (buffer) => ascii(buffer, 0, 4) === 'RIFF' && ascii(buffer, 8, 11) === 'AVI',
  '.txt': (buffer) => !buffer.includes(0x00)
};

const getUploadedFiles = (req) => {
  if (req.file) return [req.file];
  if (Array.isArray(req.files)) return req.files;
  if (req.files && typeof req.files === 'object') return Object.values(req.files).flat();
  return [];
};

const removeFiles = async (files) => {
  await Promise.all(files.map(async (file) => {
    if (!file?.path) return;
    try {
      await fs.promises.unlink(file.path);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }));
};

const hasValidFileSignature = async (file) => {
  const extension = path.extname(file.originalname || file.filename || '').toLowerCase();
  const validate = signatureValidators[extension];
  if (!validate || !file.path) return false;

  const handle = await fs.promises.open(file.path, 'r');
  try {
    const buffer = Buffer.alloc(32);
    const { bytesRead } = await handle.read(buffer, 0, buffer.length, 0);
    return bytesRead > 0 && validate(buffer.subarray(0, bytesRead));
  } finally {
    await handle.close();
  }
};

const validateUploadedFileSignatures = async (req, res, next) => {
  const files = getUploadedFiles(req);
  if (files.length === 0) return next();

  try {
    const validations = await Promise.all(files.map(hasValidFileSignature));
    if (validations.every(Boolean)) return next();

    await removeFiles(files);
    return res.status(415).json({
      success: false,
      message: 'Le contenu du fichier ne correspond pas à son format déclaré'
    });
  } catch (error) {
    try {
      await removeFiles(files);
    } catch (cleanupError) {
      error.cleanupError = cleanupError.message;
    }
    return next(error);
  }
};

module.exports = {
  hasValidFileSignature,
  validateUploadedFileSignatures
};
