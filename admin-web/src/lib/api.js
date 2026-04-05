import { signOutFirebaseSilently } from './firebase.js';

const runtimeEnv =
  typeof import.meta !== 'undefined' && import.meta.env
    ? import.meta.env
    : {};

function normalizeApiBaseUrl(value) {
  const trimmed = `${value || ''}`.trim();
  if (!trimmed) {
    return '';
  }

  const normalized = trimmed.endsWith('/')
    ? trimmed.slice(0, -1)
    : trimmed;
  return normalized.endsWith('/api') ? normalized : `${normalized}/api`;
}

function resolveApiBaseUrl() {
  const configuredBaseUrl = normalizeApiBaseUrl(runtimeEnv.VITE_API_BASE_URL);
  if (configuredBaseUrl) {
    return configuredBaseUrl;
  }

  if (typeof window !== 'undefined') {
    const { hostname, origin, protocol } = window.location;
    const isLocalHost =
      hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1';

    if (!isLocalHost && protocol === 'https:') {
      return `${origin}/api`;
    }
  }

  return 'http://127.0.0.1:5001/api';
}

const API_BASE_URL = resolveApiBaseUrl();

const TOKEN_KEY = 'moroccocheck_admin_token';
const USER_KEY = 'moroccocheck_admin_user';
const SESSION_CHANGE_EVENT = 'moroccocheck-admin-session-change';

function readJson(response) {
  return response.json().catch(() => ({}));
}

function emitSessionChange(detail = {}) {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent(SESSION_CHANGE_EVENT, { detail }));
  }
}

async function request(path, options = {}) {
  const token = getStoredToken();
  const headers = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    ...(options.headers || {})
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers
  });

  const payload = await readJson(response);
  if (!response.ok) {
    const isAuthBootstrapRoute =
      path === '/auth/login' ||
      path === '/auth/google' ||
      path === '/auth/logout';

    if (response.status === 401 && token && !isAuthBootstrapRoute) {
      clearSession({ reason: 'expired' });
    }

    const error = new Error(
      payload.message || `Erreur API (${response.status})`
    );
    error.status = response.status;
    error.payload = payload;
    if (response.status === 401 && token && !isAuthBootstrapRoute) {
      error.code = 'SESSION_EXPIRED';
      error.message = 'Votre session admin a expire. Reconnectez-vous.';
    }
    throw error;
  }

  return payload;
}

export async function login(email, password) {
  const payload = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password })
  });

  const data = payload.data || payload;
  const user = data.user || {};
  const token = data.access_token || data.token;

  if (!token) {
    throw new Error('Token manquant dans la reponse serveur');
  }

  persistSession({ token, user });
  return { token, user };
}

export async function loginWithGoogle(idToken) {
  const payload = await request('/auth/google', {
    method: 'POST',
    body: JSON.stringify({ id_token: idToken })
  });

  const data = payload.data || payload;
  const user = data.user || {};
  const token = data.access_token || data.token;

  if (!token) {
    throw new Error('Token manquant dans la reponse serveur');
  }

  persistSession({ token, user });
  return { token, user };
}

export async function logout() {
  try {
    await request('/auth/logout', { method: 'POST' });
  } catch (_error) {
    // We still clear the local session even if the server logout call fails.
  } finally {
    await signOutFirebaseSilently();
    clearSession();
  }
}

export async function fetchAdminStats() {
  const payload = await request('/admin/stats');
  return payload.data || payload;
}

function normalizePagination(meta = {}) {
  return meta.pagination || meta || {};
}

export async function fetchPendingSites(query = {}) {
  const params = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      params.set(key, value);
    }
  });

  const suffix = params.toString() ? `?${params.toString()}` : '';
  const payload = await request(`/admin/sites/pending${suffix}`);
  return {
    items: payload.data || [],
    meta: normalizePagination(payload.meta || {})
  };
}

export async function moderateSite(siteId, action, notes) {
  const payload = await request(`/admin/sites/${siteId}/review`, {
    method: 'PUT',
    body: JSON.stringify({ action, notes })
  });
  return payload.data || payload;
}

export async function fetchAdminSiteDetail(siteId) {
  const payload = await request(`/admin/sites/${siteId}`);
  return payload.data || payload;
}

export async function fetchPendingReviews(query = {}) {
  const params = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      params.set(key, value);
    }
  });

  const suffix = params.toString() ? `?${params.toString()}` : '';
  const payload = await request(`/admin/reviews/pending${suffix}`);
  return {
    items: payload.data || [],
    meta: normalizePagination(payload.meta || {})
  };
}

export async function moderateReview(reviewId, action, notes) {
  const payload = await request(`/admin/reviews/${reviewId}/moderate`, {
    method: 'PUT',
    body: JSON.stringify({ action, notes })
  });
  return payload.data || payload;
}

export async function fetchAdminReviewDetail(reviewId) {
  const payload = await request(`/admin/reviews/${reviewId}`);
  return payload.data || payload;
}

export async function deleteReviewPhoto(reviewId, photoId) {
  const payload = await request(`/admin/reviews/${reviewId}/photos/${photoId}`, {
    method: 'DELETE'
  });
  return payload.data || payload;
}

export async function fetchContributorRequests(query = {}) {
  const params = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      params.set(key, value);
    }
  });

  const suffix = params.toString() ? `?${params.toString()}` : '';
  const payload = await request(`/admin/contributor-requests${suffix}`);
  return {
    items: payload.data || [],
    meta: normalizePagination(payload.meta || {})
  };
}

export async function reviewContributorRequest(requestId, action, adminNotes) {
  const payload = await request(`/admin/contributor-requests/${requestId}`, {
    method: 'PATCH',
    body: JSON.stringify({ action, admin_notes: adminNotes })
  });
  return payload.data || payload;
}

export async function fetchUsers(query = {}) {
  const params = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      params.set(key, value);
    }
  });

  const suffix = params.toString() ? `?${params.toString()}` : '';
  const payload = await request(`/admin/users${suffix}`);
  return {
    items: payload.data || [],
    meta: normalizePagination(payload.meta || {})
  };
}

export async function fetchUserById(userId) {
  const payload = await request(`/admin/users/${userId}`);
  return payload.data || payload;
}

export async function updateUserStatus(userId, status) {
  const payload = await request(`/admin/users/${userId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status })
  });
  return payload.data || payload;
}

export async function updateUserRole(userId, role) {
  const payload = await request(`/admin/users/${userId}/role`, {
    method: 'PATCH',
    body: JSON.stringify({ role })
  });
  return payload.data || payload;
}

export function persistSession({ token, user }) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
  emitSessionChange({ reason: 'updated' });
}

export function clearSession(detail = {}) {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
  emitSessionChange(detail);
}

export function getStoredToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getStoredUser() {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch (_error) {
    return null;
  }
}

export function isAdminRole(role) {
  return role === 'ADMIN';
}

export {
  API_BASE_URL,
  SESSION_CHANGE_EVENT,
  normalizeApiBaseUrl,
  resolveApiBaseUrl
};
