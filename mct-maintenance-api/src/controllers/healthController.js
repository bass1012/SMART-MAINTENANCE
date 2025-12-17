/**
 * @desc    Health check endpoint
 * @route   GET /health
 * @access  Public
 */
const healthCheck = (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'API is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    nodeVersion: process.version,
    platform: process.platform,
    env: process.env.NODE_ENV || 'development',
  });
};

module.exports = {
  healthCheck,
};
