const request = require('supertest');
const express = require('express');
const authRoutes = require('../../src/routes/authRoutes');

jest.mock('../../src/models', () => ({
  User: {
    findOne: jest.fn(),
    findByPk: jest.fn(),
    create: jest.fn()
  },
  CustomerProfile: {
    findOne: jest.fn(),
    create: jest.fn()
  },
  TechnicianProfile: {
    findOne: jest.fn(),
    create: jest.fn()
  },
  EmailVerificationCode: {
    findOne: jest.fn()
  },
  Intervention: {}
}));

jest.mock('../../src/config/redis', () => ({
  cache: {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
    exists: jest.fn().mockResolvedValue(false)
  }
}));

describe('Auth Integration Tests', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/auth', authRoutes);
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('GET /api/auth/profile without token should return 401', async () => {
    const response = await request(app).get('/api/auth/profile');

    expect(response.status).toBe(401);
    expect(response.body).toEqual(
      expect.objectContaining({
        success: false
      })
    );
  });

  it('POST /api/auth/login with missing payload should return error', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({});

    expect(response.status).toBeGreaterThanOrEqual(400);
    expect(response.body.success).toBe(false);
  });
});
