const { getProfile, updateProfile } = require('../../../src/controllers/auth/authController');
const { CustomerProfile, TechnicianProfile } = require('../../../src/models');

jest.mock('../../../src/models', () => ({
  User: {
    findByPk: jest.fn(),
    findOne: jest.fn(),
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

describe('Auth Controller Unit Tests', () => {
  let req, res;

  beforeEach(() => {
    jest.clearAllMocks();
    req = {
      user: {
        id: 1,
        email: 'test@example.com',
        role: 'customer',
        toJSON: jest.fn().mockReturnValue({ id: 1, email: 'test@example.com', role: 'customer' }),
        update: jest.fn().mockResolvedValue(true),
        reload: jest.fn().mockResolvedValue(true)
      },
      body: {}
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
  });

  describe('getProfile', () => {
    it('should return profile data for customer user', async () => {
      CustomerProfile.findOne.mockResolvedValue({
        id: 10,
        user_id: 1,
        address: '123 Main St',
        toJSON: () => ({ id: 10, user_id: 1, address: '123 Main St' })
      });

      await getProfile(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            user: expect.objectContaining({ id: 1, email: 'test@example.com' })
          })
        })
      );
    });
  });

  describe('updateProfile', () => {
    it('should update user fields successfully', async () => {
      req.body = { first_name: 'Updated' };
      CustomerProfile.findOne.mockResolvedValue(null);

      await updateProfile(req, res);

      expect(req.user.update).toHaveBeenCalledWith(expect.objectContaining({ first_name: 'Updated' }));
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Profile updated successfully'
        })
      );
    });
  });
});
