const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  hasValidFileSignature,
  validateUploadedFileSignatures
} = require('../../../src/middleware/fileSignatureValidation');

const createTempFile = (extension, content) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'mct-upload-test-'));
  const filePath = path.join(directory, `upload${extension}`);
  fs.writeFileSync(filePath, content);
  return { directory, filePath };
};

describe('validation de signature des fichiers', () => {
  const directories = [];

  afterEach(() => {
    for (const directory of directories.splice(0)) {
      fs.rmSync(directory, { recursive: true, force: true });
    }
  });

  test('accepte une image PNG dont la signature est valide', async () => {
    const { directory, filePath } = createTempFile('.png', Buffer.from([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00
    ]));
    directories.push(directory);

    await expect(hasValidFileSignature({
      path: filePath,
      originalname: 'photo.png'
    })).resolves.toBe(true);
  });

  test('refuse et supprime un exécutable renommé en image', async () => {
    const { directory, filePath } = createTempFile('.jpg', Buffer.from('MZ executable'));
    directories.push(directory);
    const req = {
      file: { path: filePath, originalname: 'photo.jpg' }
    };
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis()
    };
    const next = jest.fn();

    await validateUploadedFileSignatures(req, res, next);

    expect(res.status).toHaveBeenCalledWith(415);
    expect(next).not.toHaveBeenCalled();
    expect(fs.existsSync(filePath)).toBe(false);
  });

  test('accepte les conteneurs Office ZIP et refuse un faux PDF', async () => {
    const office = createTempFile('.docx', Buffer.from([0x50, 0x4b, 0x03, 0x04, 0x00]));
    const fakePdf = createTempFile('.pdf', Buffer.from('not a pdf'));
    directories.push(office.directory, fakePdf.directory);

    await expect(hasValidFileSignature({
      path: office.filePath,
      originalname: 'contrat.docx'
    })).resolves.toBe(true);
    await expect(hasValidFileSignature({
      path: fakePdf.filePath,
      originalname: 'contrat.pdf'
    })).resolves.toBe(false);
  });
});
