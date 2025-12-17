// Simple in-memory cache for development (instead of Redis)
class MemoryCache {
  // Redis: set key with expiration (seconds)
  async setEx(key, ttl, value) {
    await this.set(key, value, ttl);
    return 'OK';
  }

  // Redis: check if key exists (returns 1 if exists, 0 if not)
  async exists(key) {
    return this.cache.has(key) ? 1 : 0;
  }

  // Redis: flush all keys
  async flushDb() {
    this.cache.clear();
    for (const timeout of this.timeouts.values()) {
      clearTimeout(timeout);
    }
    this.timeouts.clear();
    return 'OK';
  }
  constructor() {
    this.cache = new Map();
    this.timeouts = new Map();
  }

  async set(key, value, ttl = null) {
    this.cache.set(key, value);
    
    // Clear any existing timeout for this key
    if (this.timeouts.has(key)) {
      clearTimeout(this.timeouts.get(key));
    }
    
    // Set new timeout if TTL is provided
    if (ttl) {
      const timeout = setTimeout(() => {
        this.cache.delete(key);
        this.timeouts.delete(key);
      }, ttl * 1000);
      this.timeouts.set(key, timeout);
    }
    
    return 'OK';
  }

  async get(key) {
    return this.cache.get(key);
  }

  async del(key) {
    if (this.timeouts.has(key)) {
      clearTimeout(this.timeouts.get(key));
      this.timeouts.delete(key);
    }
    return this.cache.delete(key);
  }

  async quit() {
    // Clear all timeouts
    for (const timeout of this.timeouts.values()) {
      clearTimeout(timeout);
    }
    this.cache.clear();
    this.timeouts.clear();
  }
}

const redisClient = new MemoryCache();

// Mock Redis event handlers
redisClient.on = function(event, callback) {
  if (event === 'connect') {
    setTimeout(callback, 0);
  } else if (event === 'ready') {
    setTimeout(callback, 10);
  }
  return this;
};

// Mock connect method
redisClient.connect = async function() {
  console.log('✅ Connected to Redis server (memory cache)');
  return Promise.resolve();
};

// Connect to Redis
const connectRedis = async () => {
  try {
    await redisClient.connect();
  } catch (error) {
    console.error('❌ Failed to connect to Redis:', error.message);
  }
};

// Cache helper functions
const cache = {
  // Get value from cache
  get: async (key) => {
    try {
      const value = await redisClient.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error('Cache get error:', error.message);
      return null;
    }
  },

  // Set value in cache with expiration
  set: async (key, value, expirationInSeconds = 3600) => {
    try {
      await redisClient.setEx(key, expirationInSeconds, JSON.stringify(value));
      return true;
    } catch (error) {
      console.error('Cache set error:', error.message);
      return false;
    }
  },

  // Delete value from cache
  del: async (key) => {
    try {
      await redisClient.del(key);
      return true;
    } catch (error) {
      console.error('Cache delete error:', error.message);
      return false;
    }
  },

  // Clear all cache
  flush: async () => {
    try {
      await redisClient.flushDb();
      return true;
    } catch (error) {
      console.error('Cache flush error:', error.message);
      return false;
    }
  },

  // Check if key exists
  exists: async (key) => {
    try {
      const result = await redisClient.exists(key);
      return result === 1;
    } catch (error) {
      console.error('Cache exists error:', error.message);
      return false;
    }
  }
};

module.exports = {
  redisClient,
  connectRedis,
  cache
};
