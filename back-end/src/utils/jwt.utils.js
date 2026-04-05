/**
 * Utilitaires JWT — génération et vérification des tokens
 * Payload : userId, email, role. Expiration depuis .env (JWT_EXPIRES_IN).
 */

import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import runtimeConfig from '../config/runtime.js';

const JWT_SECRET =
  runtimeConfig.jwt.secret ||
  (runtimeConfig.isTest ? 'test-secret-key' : undefined);
const JWT_EXPIRES_IN = runtimeConfig.jwt.expiresIn;

/**
 * Génère un token d'accès pour un utilisateur
 * @param {Object} user - { userId, email, role }
 * @param {string} [expiresIn] - Override expiration (ex: '7d', '15m')
 * @returns {string} Token JWT
 */
export function generateToken(user, expiresIn = JWT_EXPIRES_IN) {
  if (!JWT_SECRET) throw new Error('JWT_SECRET is not configured');
  const payload = {
    userId: user.userId ?? user.id,
    email: user.email,
    role: user.role,
    jti: randomUUID()
  };
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

/**
 * Vérifie un token et retourne le payload décodé
 * @param {string} token - Token JWT (sans le préfixe "Bearer ")
 * @returns {Object} Payload décodé { userId, email, role, iat, exp }
 * @throws {jwt.JsonWebTokenError} Token invalide
 * @throws {jwt.TokenExpiredError} Token expiré
 */
export function verifyToken(token) {
  if (!JWT_SECRET) throw new Error('JWT_SECRET is not configured');
  return jwt.verify(token, JWT_SECRET);
}

/**
 * Décode un token sans vérifier la signature (utile pour debug uniquement)
 * @param {string} token
 * @returns {Object|null} Payload ou null
 */
export function decodeToken(token) {
  return jwt.decode(token);
}
