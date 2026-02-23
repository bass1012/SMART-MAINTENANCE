const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { cache } = require('../config/redis');

// JWT Authentication middleware
const authenticate = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    // Check if token is blacklisted
    const isBlacklisted = await cache.exists(`blacklist:${token}`);
    if (isBlacklisted) {
      return res.status(401).json({
        success: false,
        message: 'Token is blacklisted. Please login again.'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const user = await User.findByPk(decoded.id);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. User not found.'
      });
    }

    // Check if user is active
    // Permettre l'accès pour les comptes pending (pour qu'ils puissent vérifier leur email)
    // Bloquer uniquement les comptes deleted ou inactive
    if (user.status === 'deleted' || user.status === 'inactive') {
      return res.status(401).json({
        success: false,
        message: 'Account is not active. Please contact support.'
      });
    }

    // Attacher le user à la requête (même si pending)
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token.'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired. Please login again.'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Internal server error.'
    });
  }
};

// Role-based access control middleware
const authorize = (...roles) => {
  return (req, res, next) => {
    console.log(`🔐 Authorization check - Required roles: [${roles.join(', ')}]`);
    console.log(`   User: ${req.user ? `ID=${req.user.id}, Role=${req.user.role}` : 'NOT AUTHENTICATED'}`);
    
    if (!req.user) {
      console.log('❌ Authorization failed: No user authenticated');
      return res.status(401).json({
        success: false,
        message: 'Access denied. User not authenticated.'
      });
    }

    // Le rôle 'manager' a les mêmes droits que 'admin'
    const effectiveRoles = [...roles];
    if (roles.includes('admin') && !roles.includes('manager')) {
      effectiveRoles.push('manager');
    }

    if (!effectiveRoles.includes(req.user.role)) {
      console.log(`❌ Authorization failed: User role '${req.user.role}' not in [${effectiveRoles.join(', ')}]`);
      return res.status(403).json({
        success: false,
        message: 'Access denied. Insufficient permissions.'
      });
    }

    console.log('✅ Authorization successful');
    next();
  };
};

// Optional authentication middleware (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findByPk(decoded.id);
      
      if (user && user.status === 'active') {
        req.user = user;
      }
    }
    
    next();
  } catch (error) {
    // Continue without authentication
    next();
  }
};

// Refresh token middleware
const refreshToken = async (req, res, next) => {
  try {
    const refreshToken = req.body.refreshToken;
    
    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token required.'
      });
    }

    // Check if refresh token is blacklisted
    const isBlacklisted = await cache.exists(`blacklist:${refreshToken}`);
    if (isBlacklisted) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token is blacklisted. Please login again.'
      });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const user = await User.findByPk(decoded.id);
    
    if (!user || user.status !== 'active') {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token.'
      });
    }

    // Generate new access token
    const accessToken = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.json({
      success: true,
      accessToken,
      user: user.toJSON()
    });
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid refresh token.'
    });
  }
};

// Logout middleware (blacklist tokens)
const logout = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    const refreshToken = req.body.refreshToken;

    if (token) {
      // Blacklist access token
      const decoded = jwt.decode(token);
      const expiresIn = decoded.exp - Math.floor(Date.now() / 1000);
      if (expiresIn > 0) {
        await cache.set(`blacklist:${token}`, true, expiresIn);
      }
    }

    if (refreshToken) {
      // Blacklist refresh token
      const decoded = jwt.decode(refreshToken);
      const expiresIn = decoded.exp - Math.floor(Date.now() / 1000);
      if (expiresIn > 0) {
        await cache.set(`blacklist:${refreshToken}`, true, expiresIn);
      }
    }

    next();
  } catch (error) {
    next();
  }
};

module.exports = {
  authenticate,
  authorize,
  optionalAuth,
  refreshToken,
  logout
};
