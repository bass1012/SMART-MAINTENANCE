const request = require('supertest');
const { maskSensitiveData } = require('../../../src/utils/piiMasker');
const express = require('express');
const { correlationMiddleware } = require('../../../src/middleware/correlationMiddleware');

describe('Observabilité & Sécurité Logique', () => {
  describe('piiMasker', () => {
    it('devrait masquer les mots de passe et clés secrètes', () => {
      const payload = {
        username: 'john_doe',
        password: 'SuperSecretPassword123!',
        nested: {
          token: 'jwt.token.val',
          publicField: 'hello'
        }
      };

      const masked = maskSensitiveData(payload);
      expect(masked.username).toBe('john_doe');
      expect(masked.password).toBe('***MASKED***');
      expect(masked.nested.token).toBe('***MASKED***');
      expect(masked.nested.publicField).toBe('hello');
    });
  });

  describe('correlationMiddleware', () => {
    it('devrait ajouter un en-tête X-Correlation-ID si absent', async () => {
      const app = express();
      app.use(correlationMiddleware);
      app.get('/test', (req, res) => {
        res.status(200).json({ correlationId: req.correlationId });
      });

      const res = await request(app).get('/test');
      expect(res.status).toBe(200);
      expect(res.headers['x-correlation-id']).toBeDefined();
      expect(res.body.correlationId).toBe(res.headers['x-correlation-id']);
    });

    it('devrait réutiliser un X-Correlation-ID existant', async () => {
      const app = express();
      app.use(correlationMiddleware);
      app.get('/test', (req, res) => {
        res.status(200).json({ correlationId: req.correlationId });
      });

      const existingId = 'custom-uuid-1234';
      const res = await request(app)
        .get('/test')
        .set('x-correlation-id', existingId);

      expect(res.status).toBe(200);
      expect(res.headers['x-correlation-id']).toBe(existingId);
      expect(res.body.correlationId).toBe(existingId);
    });
  });
});
