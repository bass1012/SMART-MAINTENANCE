const express = require('express');
const request = require('supertest');

const mockInterventionImageFindOne = jest.fn();
const mockInterventionFindOne = jest.fn();
const mockBuildInterventionReadWhere = jest.fn();

jest.mock('../../../src/models', () => ({
  InterventionImage: { findOne: mockInterventionImageFindOne },
  Intervention: { findOne: mockInterventionFindOne }
}));

jest.mock('../../../src/policies/interventionAccessPolicy', () => ({
  buildInterventionReadWhere: mockBuildInterventionReadWhere
}));

jest.mock('../../../src/middleware/auth', () => ({
  authenticate: (req, res, next) => {
    const role = req.header('x-test-role');
    if (!role) return res.status(401).json({ success: false });
    req.user = { id: 10, role };
    return next();
  },
  requireRole: (...roles) => (req, res, next) => (
    roles.includes(req.user.role) ? next() : res.status(403).json({ success: false })
  )
}));

const fileRoutes = require('../../../src/routes/fileRoutes');

const createApp = () => {
  const app = express();
  app.use('/uploads', fileRoutes);
  app.use((error, req, res, next) => {
    void next;
    res.status(500).json({ error: error.message });
  });
  return app;
};

describe('protected uploaded files', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('requires authentication for intervention photos', async () => {
    await request(createApp())
      .get('/uploads/interventions/report-1.jpg')
      .expect(401);

    expect(mockInterventionImageFindOne).not.toHaveBeenCalled();
  });

  it('returns 404 without exposing a photo outside the intervention scope', async () => {
    mockInterventionImageFindOne.mockResolvedValue({ intervention_id: 42 });
    mockBuildInterventionReadWhere.mockResolvedValue({ id: 42, customer_id: 7 });
    mockInterventionFindOne.mockResolvedValue(null);

    await request(createApp())
      .get('/uploads/interventions/report-1.jpg')
      .set('x-test-role', 'customer')
      .expect(404);

    expect(mockBuildInterventionReadWhere).toHaveBeenCalledWith({
      interventionId: 42,
      user: { id: 10, role: 'customer' }
    });
  });

  it('rejects invalid filenames before querying the database', async () => {
    await request(createApp())
      .get('/uploads/interventions/%2e%2e%2fsecret.env')
      .set('x-test-role', 'admin')
      .expect(404);

    expect(mockInterventionImageFindOne).not.toHaveBeenCalled();
  });

  it('restricts administrative documents to internal roles', async () => {
    await request(createApp())
      .get('/uploads/documents/contract.pdf')
      .set('x-test-role', 'customer')
      .expect(403);
  });
});
