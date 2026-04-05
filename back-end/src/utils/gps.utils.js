/**
 * Utilitaires GPS — Haversine, isWithinRadius, formatDistance
 * Pour check-in : distance max = 100 m (voir constants.js GPS_VALIDATION.MAX_DISTANCE)
 */

import { GPS_VALIDATION } from '../config/constants.js';

/**
 * Calcule la distance entre deux points GPS (formule de Haversine)
 * @param {number} lat1 - Latitude point 1 (degrés)
 * @param {number} lon1 - Longitude point 1 (degrés)
 * @param {number} lat2 - Latitude point 2 (degrés)
 * @param {number} lon2 - Longitude point 2 (degrés)
 * @returns {number} Distance en mètres
 */
export function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Rayon Terre en m
  const lat1Rad = (lat1 * Math.PI) / 180;
  const lon1Rad = (lon1 * Math.PI) / 180;
  const lat2Rad = (lat2 * Math.PI) / 180;
  const lon2Rad = (lon2 * Math.PI) / 180;
  const dLat = lat2Rad - lat1Rad;
  const dLon = lon2Rad - lon1Rad;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1Rad) * Math.cos(lat2Rad) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Vérifie si l'utilisateur est dans le rayon autorisé (défaut: MAX_DISTANCE du MPD = 100 m)
 * @param {number} userLat
 * @param {number} userLon
 * @param {number} siteLat
 * @param {number} siteLon
 * @param {number} [maxDistance] - Optionnel, sinon GPS_VALIDATION.MAX_DISTANCE
 * @returns {boolean}
 */
export function isWithinRadius(userLat, userLon, siteLat, siteLon, maxDistance = null) {
  const max = maxDistance ?? GPS_VALIDATION.MAX_DISTANCE;
  const distance = calculateDistance(userLat, userLon, siteLat, siteLon);
  return distance <= max;
}

/**
 * Formate une distance pour affichage (m ou km)
 * @param {number} meters
 * @returns {string} ex: "500 m" ou "1.5 km"
 */
export function formatDistance(meters) {
  if (meters < 1000) {
    return `${Math.round(meters)} m`;
  }
  return `${(meters / 1000).toFixed(1)} km`;
}
