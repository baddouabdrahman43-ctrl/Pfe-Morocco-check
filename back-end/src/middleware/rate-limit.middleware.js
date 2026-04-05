import { createClient } from 'redis';
import runtimeConfig from '../config/runtime.js';
import { errorResponse } from '../utils/response.utils.js';

function getClientKey(req, prefix) {
  return `${prefix}:${req.ip || 'unknown-ip'}`;
}

class MemoryRateLimitStore {
  constructor() {
    this.store = new Map();
  }

  async increment(key, windowMs) {
    const now = Date.now();
    const existing = this.store.get(key);

    const currentWindow =
      !existing || existing.resetAt <= now
        ? {
            count: 0,
            resetAt: now + windowMs
          }
        : existing;

    currentWindow.count += 1;
    this.store.set(key, currentWindow);
    return currentWindow;
  }
}

const memoryStore = new MemoryRateLimitStore();
let redisClientPromise = null;

async function getRedisClient() {
  if (
    runtimeConfig.rateLimit.store !== 'redis' ||
    !runtimeConfig.rateLimit.redisUrl
  ) {
    return null;
  }

  if (!redisClientPromise) {
    const client = createClient({
      url: runtimeConfig.rateLimit.redisUrl
    });

    client.on('error', (error) => {
      console.error('Redis rate-limit client error:', error.message);
    });

    redisClientPromise = client
      .connect()
      .then(() => client)
      .catch((error) => {
        console.error('Unable to connect Redis rate-limit store:', error.message);
        redisClientPromise = null;
        return null;
      });
  }

  return redisClientPromise;
}

async function incrementRedisWindow(client, key, windowMs) {
  const now = Date.now();
  const [countResult, ttlResult] = await client
    .multi()
    .incr(key)
    .pTTL(key)
    .exec();

  const count = Number(countResult);
  let ttlMs = Number(ttlResult);

  if (!Number.isFinite(ttlMs) || ttlMs <= 0) {
    await client.pExpire(key, windowMs);
    ttlMs = windowMs;
  }

  return {
    count,
    resetAt: now + ttlMs
  };
}

export function createRateLimiter({
  windowMs,
  maxRequests,
  prefix,
  message,
  code
}) {
  return async (req, res, next) => {
    if (!runtimeConfig.rateLimit.enabled) {
      return next();
    }

    const now = Date.now();
    const key = `${runtimeConfig.rateLimit.redisKeyPrefix}:${getClientKey(req, prefix)}`;

    let currentWindow;
    try {
      const redisClient = await getRedisClient();
      currentWindow = redisClient
        ? await incrementRedisWindow(redisClient, key, windowMs)
        : await memoryStore.increment(key, windowMs);
    } catch (_error) {
      currentWindow = await memoryStore.increment(key, windowMs);
    }

    const remaining = Math.max(maxRequests - currentWindow.count, 0);
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((currentWindow.resetAt - now) / 1000)
    );

    res.setHeader('X-RateLimit-Limit', String(maxRequests));
    res.setHeader('X-RateLimit-Remaining', String(remaining));
    res.setHeader(
      'X-RateLimit-Reset',
      String(Math.ceil(currentWindow.resetAt / 1000))
    );

    if (currentWindow.count > maxRequests) {
      res.setHeader('Retry-After', String(retryAfterSeconds));
      return errorResponse(
        res,
        message,
        429,
        code,
        {
          retry_after_seconds: retryAfterSeconds
        }
      );
    }

    return next();
  };
}

export const registerRateLimit = createRateLimiter({
  windowMs: runtimeConfig.rateLimit.windowMs,
  maxRequests: runtimeConfig.rateLimit.registerMax,
  prefix: 'register',
  message: 'Trop de tentatives de creation de compte. Reessayez plus tard.',
  code: 'RATE_LIMIT_REGISTER'
});

export const loginRateLimit = createRateLimiter({
  windowMs: runtimeConfig.rateLimit.windowMs,
  maxRequests: runtimeConfig.rateLimit.loginMax,
  prefix: 'login',
  message: 'Trop de tentatives de connexion. Reessayez plus tard.',
  code: 'RATE_LIMIT_LOGIN'
});

export const refreshRateLimit = createRateLimiter({
  windowMs: runtimeConfig.rateLimit.windowMs,
  maxRequests: runtimeConfig.rateLimit.maxRequests,
  prefix: 'refresh',
  message: 'Trop de demandes de rafraichissement. Reessayez plus tard.',
  code: 'RATE_LIMIT_REFRESH'
});

export const adminRateLimit = createRateLimiter({
  windowMs: runtimeConfig.rateLimit.windowMs,
  maxRequests: runtimeConfig.rateLimit.adminMax,
  prefix: 'admin',
  message: 'Trop de requetes admin sur une courte periode. Reessayez plus tard.',
  code: 'RATE_LIMIT_ADMIN'
});

export default {
  createRateLimiter,
  registerRateLimit,
  loginRateLimit,
  refreshRateLimit,
  adminRateLimit
};
