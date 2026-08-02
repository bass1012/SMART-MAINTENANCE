const { listUsers, deleteUser } = require('../../../src/controllers/user/userController');
const User = require('../../../src/models/User');

jest.mock('../../../src/models/User', () => ({
  findAndCountAll: jest.fn(),
  findByPk: jest.fn()
}));

jest.mock('../../../src/models/TechnicianProfile', () => ({}));

describe('User Controller Unit Tests', () => {
  let req, res, next;

  beforeEach(() => {
    jest.clearAllMocks();
    req = {
      query: {},
      params: {},
      user: { id: 1, role: 'admin' }
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    next = jest.fn();
  });

  describe('listUsers', () => {
    it('should return formatted user list with pagination', async () => {
      const mockUsers = [
        {
          id: 1,
          email: 'user1@example.com',
          role: 'customer',
          toJSON: () => ({ id: 1, email: 'user1@example.com', role: 'customer' })
        }
      ];
      User.findAndCountAll.mockResolvedValue({ count: 1, rows: mockUsers });

      await listUsers(req, res, next);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            total: 1,
            page: 1,
            limit: 10
          })
        })
      );
    });
  });

  describe('deleteUser', () => {
    it('should prevent self-deletion', async () => {
      req.params.id = '1';
      req.user = { id: 1, role: 'admin' };
      User.findByPk.mockResolvedValue({ id: 1, role: 'admin' });

      await deleteUser(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: 'Vous ne pouvez pas supprimer votre propre compte.'
        })
      );
    });

    it('should soft delete user when allowed', async () => {
      req.params.id = '2';
      req.user = { id: 1, role: 'admin' };
      const mockUser = {
        id: 2,
        role: 'customer',
        status: 'active',
        save: jest.fn().mockResolvedValue(true)
      };
      User.findByPk.mockResolvedValue(mockUser);

      await deleteUser(req, res, next);

      expect(mockUser.status).toBe('deleted');
      expect(mockUser.save).toHaveBeenCalled();
      expect(res.json).toHaveBeenCalledWith({ success: true, message: 'User deleted' });
    });
  });
});
