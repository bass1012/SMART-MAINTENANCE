const { Op } = require('sequelize');
const User = require('../../models/User');

// GET /api/users
exports.listUsers = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const { search, role, status } = req.query;

    const where = {};
    if (role) where.role = role;
    if (status) where.status = status;
    
    // Exclure les utilisateurs supprimés par défaut
    if (!status) {
      where.status = { [Op.ne]: 'deleted' };
    }
    
    if (search) {
      // Utilisation de Op.like pour compatibilité SQLite (pas de iLike natif)
      const pattern = `%${search}%`;
      where[Op.or] = [
        { email: { [Op.like]: pattern } },
        { phone: { [Op.like]: pattern } },
        { first_name: { [Op.like]: pattern } },
        { last_name: { [Op.like]: pattern } }
      ];
    }

    const { rows, count } = await User.findAndCountAll({
      where,
      limit,
      offset,
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: {
        users: rows,
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit)
      }
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/users/:id
exports.getUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    return res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

// PATCH /api/users/:id/status
exports.updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!['active', 'inactive', 'pending'].includes(status)) {
      return res.status(400).json({ success: false, error: 'Invalid status' });
    }
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    user.status = status;
    await user.save();
    return res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

// PUT /api/users/:id
exports.updateUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    
  const allowed = ['email', 'phone', 'role', 'status', 'preferences', 'first_name', 'last_name', 'profile_image'];
    for (const key of allowed) {
      if (req.body[key] !== undefined) user[key] = req.body[key];
    }
    
    // Gérer le mot de passe séparément (hashage nécessaire)
    if (req.body.password) {
      user.password_hash = req.body.password; // Le hook beforeUpdate s'occupera du hashage
    }
    
    await user.save();
    
    // ✅ SYNCHRONISER avec CustomerProfile si l'utilisateur est un client
    if (user.role === 'customer') {
      const { CustomerProfile } = require('../../models');
      const customerProfile = await CustomerProfile.findOne({ where: { user_id: user.id } });
      
      if (customerProfile) {
        // Mettre à jour first_name et last_name dans customer_profiles
        if (req.body.first_name !== undefined) {
          customerProfile.first_name = req.body.first_name;
        }
        if (req.body.last_name !== undefined) {
          customerProfile.last_name = req.body.last_name;
        }
        await customerProfile.save();
        console.log(`✅ CustomerProfile synchronisé pour user_id: ${user.id}`);
      }
    }
    
    return res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/users/:id
exports.deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    
    // 🔒 RESTRICTION: Pour supprimer un admin ou manager, l'admin doit l'avoir créé lui-même
    if (user.role === 'admin' || user.role === 'manager') {
      const currentUser = req.user; // L'utilisateur connecté via middleware authenticate
      
      if (!currentUser || currentUser.role !== 'admin') {
        return res.status(403).json({ 
          success: false, 
          error: 'Seul un administrateur peut supprimer un compte admin ou manager' 
        });
      }
      
      // Vérifier que l'admin actuel a créé cet utilisateur
      if (user.created_by !== currentUser.id) {
        return res.status(403).json({ 
          success: false, 
          error: 'Vous ne pouvez supprimer que les comptes admin/manager que vous avez créés' 
        });
      }
      
      console.log(`🗑️ Admin ${currentUser.id} supprime le ${user.role} ${user.id} qu'il a créé`);
    }
    
    // Soft delete: change status to 'deleted' instead of destroying
    user.status = 'deleted';
    await user.save();
    
    // Clear from cache if exists
    const { cache } = require('../../config/redis');
    if (cache) {
      await cache.del(`user:${user.id}`);
    }
    
    return res.json({ success: true, message: 'User deleted' });
  } catch (err) {
    next(err);
  }
};
