const { createClient } = require('redis');

class MemoryCache {
  constructor() {
    this.cache = new Map();
    this.timeouts = new Map();
  }

  async setEx(key, ttl, value) {
    this.cache.set(key, value);
    if (this.timeouts.has(key)) clearTimeout(this.timeouts.get(key));
    const timeout = setTimeout(() => {
      this.cache.delete(key);
      this.timeouts.delete(key);
    }, ttl * 1000);
    this.timeouts.set(key, timeout);
    return 'OK';
  }

  async exists(key) {
    return this.cache.has(key) ? 1 : 0;
  }

  async get(key) {
    return this.cache.get(key) ?? null;
  }

  async del(key) {
    if (this.timeouts.has(key)) clearTimeout(this.timeouts.get(key));
    this.timeouts.delete(key);
    return this.cache.delete(key) ? 1 : 0;
  }

  async flushDb() {
    this.cache.clear();
    for (const timeout of this.timeouts.values()) clearTimeout(timeout);
    this.timeouts.clear();
    return 'OK';
  }

  async quit() {
    return this.flushDb();
  }
}

const isProduction = process.env.NODE_ENV === 'production';
const redisUrl = process.env.REDIS_URL;
const memoryClient = new MemoryCache();
let activeClient = memoryClient;
let sharedClient = null;

const connectRedis = async () => {
  if (!redisUrl) {
    if (isProduction) {
      throw new Error('REDIS_URL est obligatoire en production pour la révocation JWT et le rate limiting partagé');
    }
    activeClient = memoryClient;
    return { shared: false };
  }

  sharedClient = createClient({ url: redisUrl });
  sharedClient.on('error', (error) => {
    console.error(`❌ Redis partagé indisponible: ${error.message}`);
  });

  try {
    await sharedClient.connect();
    activeClient = sharedClient;
    console.log('✅ Redis partagé connecté');
    return { shared: true };
  } catch (error) {
    if (isProduction) throw error;
    activeClient = memoryClient;
    console.warn(`⚠️ Redis indisponible en développement, cache mémoire utilisé: ${error.message}`);
    return { shared: false };
  }
};

const disconnectRedis = async () => {
  if (sharedClient?.isOpen) await sharedClient.quit();
  await memoryClient.quit();
};

const runCacheOperation = async (operation) => {
  try {
    return await operation(activeClient);
  } catch (error) {
    if (isProduction) throw error;
    console.error(`Cache local indisponible: ${error.message}`);
    return null;
  }
};

const cache = {
  get: async (key) => runCacheOperation(async (client) => {
    const value = await client.get(key);
    return value ? JSON.parse(value) : null;
  }),
  set: async (key, value, expirationInSeconds = 3600) => runCacheOperation(async (client) => {
    await client.setEx(key, expirationInSeconds, JSON.stringify(value));
    return true;
  }),
  del: async (key) => runCacheOperation(async (client) => {
    await client.del(key);
    return true;
  }),
  flush: async () => runCacheOperation(async (client) => {
    await client.flushDb();
    return true;
  }),
  exists: async (key) => runCacheOperation(async (client) => (await client.exists(key)) === 1)
};

const createRedisRateLimitStore = ({ prefix, windowMs }) => ({
  async increment(key) {
    if (activeClient === memoryClient) {
      throw new Error('Le rate limiting partagé exige Redis');
    }
    const redisKey = `rate-limit:${prefix}:${key}`;
    const totalHits = await activeClient.incr(redisKey);
    if (totalHits === 1) await activeClient.pExpire(redisKey, windowMs);
    const ttl = await activeClient.pTTL(redisKey);
    return {
      totalHits,
      resetTime: new Date(Date.now() + Math.max(ttl, 0))
    };
  },
  async decrement(key) {
    if (activeClient !== memoryClient) await activeClient.decr(`rate-limit:${prefix}:${key}`);
  },
  async resetKey(key) {
    if (activeClient !== memoryClient) await activeClient.del(`rate-limit:${prefix}:${key}`);
  }
});

const getRedisStatus = () => {
  if (sharedClient && sharedClient.isOpen) return 'connected';
  if (!redisUrl && !isProduction) return 'memory_fallback';
  if (activeClient === memoryClient) return 'memory_fallback';
  return 'disconnected';
};

module.exports = {
  MemoryCache,
  connectRedis,
  disconnectRedis,
  createRedisRateLimitStore,
  getRedisStatus,
  cache
};
