const { authenticate, authorize, adminOnly, requireRole } = require('../../../src/middleware/auth');

describe('Auth Middleware', () => {
  describe('authenticate', () => {
    it('should return 401 if no Authorization header is present', async () => {
      const req = { header: jest.fn().mockReturnValue(null) };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Access denied. No token provided.'
        })
      );
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('authorize', () => {
    it('should return 401 if user is not attached to req', () => {
      const req = {};
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      const middleware = authorize('admin');
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 if user role does not match required roles', () => {
      const req = { user: { id: 1, role: 'customer' } };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      const middleware = authorize('admin', 'technician');
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should call next() if user role is permitted', () => {
      const req = { user: { id: 1, role: 'admin' } };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      const middleware = authorize('admin');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('adminOnly', () => {
    it('should return 401 if no user is attached to req', () => {
      const req = {};
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      adminOnly(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 if user role is not admin', () => {
      const req = { user: { id: 1, role: 'technician' } };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      adminOnly(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should call next() if user role is admin', () => {
      const req = { user: { id: 1, role: 'admin' } };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      adminOnly(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('requireRole', () => {
    it('should return 401 if no user is present', () => {
      const req = {};
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      const middleware = requireRole('admin');
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 if user role is unauthorized', () => {
      const req = { user: { id: 1, role: 'customer' } };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      const middleware = requireRole('admin');
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should call next() if user role is authorized', () => {
      const req = { user: { id: 1, role: 'admin' } };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      const next = jest.fn();

      const middleware = requireRole('admin', 'manager');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });
});
