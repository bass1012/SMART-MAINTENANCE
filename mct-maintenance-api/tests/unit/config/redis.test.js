describe('configuration Redis partagée', () => {
  const originalEnvironment = process.env.NODE_ENV;
  const originalRedisUrl = process.env.REDIS_URL;

  afterEach(() => {
    jest.resetModules();
    process.env.NODE_ENV = originalEnvironment;
    if (originalRedisUrl === undefined) delete process.env.REDIS_URL;
    else process.env.REDIS_URL = originalRedisUrl;
  });

  test('refuse de démarrer en production sans REDIS_URL', async () => {
    jest.resetModules();
    process.env.NODE_ENV = 'production';
    delete process.env.REDIS_URL;
    const { connectRedis } = require('../../../src/config/redis');

    await expect(connectRedis()).rejects.toThrow('REDIS_URL est obligatoire');
  });

  test('utilise le cache mémoire uniquement hors production', async () => {
    jest.resetModules();
    process.env.NODE_ENV = 'test';
    delete process.env.REDIS_URL;
    const { connectRedis, cache, disconnectRedis } = require('../../../src/config/redis');

    await expect(connectRedis()).resolves.toEqual({ shared: false });
    await cache.set('blacklist:test-token', true, 60);
    await expect(cache.exists('blacklist:test-token')).resolves.toBe(true);
    await disconnectRedis();
  });
});
