import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { OAuth2Client } from 'google-auth-library';
import runtimeConfig from '../config/runtime.js';
import { toAppError } from '../services/common.service.js';

const googleOAuthClient = new OAuth2Client();

function normalizePrivateKey(value) {
  return String(value || '').replace(/\\n/g, '\n').trim();
}

function decodeJwtPayload(idToken) {
  const rawToken = String(idToken || '').trim();
  const segments = rawToken.split('.');
  if (segments.length < 2) {
    return null;
  }

  try {
    const normalizedPayload = segments[1]
      .replace(/-/g, '+')
      .replace(/_/g, '/')
      .padEnd(Math.ceil(segments[1].length / 4) * 4, '=');
    return JSON.parse(
      Buffer.from(normalizedPayload, 'base64').toString('utf8')
    );
  } catch (_error) {
    return null;
  }
}

function isGoogleOidcIssuer(issuer) {
  return (
    issuer === 'accounts.google.com' ||
    issuer === 'https://accounts.google.com'
  );
}

function isFirebaseIssuer(issuer, projectId) {
  if (!issuer) {
    return false;
  }

  if (projectId) {
    return issuer === `https://securetoken.google.com/${projectId}`;
  }

  return issuer.startsWith('https://securetoken.google.com/');
}

function getGoogleClientIds(dependencies = {}) {
  return Array.isArray(dependencies.googleClientIds)
    ? dependencies.googleClientIds.filter(Boolean)
    : runtimeConfig.google.clientIds;
}

function getFirebaseProjectId(dependencies = {}) {
  return dependencies.firebaseProjectId ?? runtimeConfig.firebase.projectId;
}

function buildFirebaseCredentialConfig() {
  const serviceAccount = runtimeConfig.firebase.serviceAccountJson;
  if (
    serviceAccount &&
    typeof serviceAccount === 'object' &&
    !Array.isArray(serviceAccount)
  ) {
    const normalizedServiceAccount = {
      projectId:
        serviceAccount.projectId || serviceAccount.project_id || undefined,
      clientEmail:
        serviceAccount.clientEmail || serviceAccount.client_email || undefined,
      privateKey: normalizePrivateKey(
        serviceAccount.privateKey || serviceAccount.private_key
      )
    };

    if (
      normalizedServiceAccount.projectId &&
      normalizedServiceAccount.clientEmail &&
      normalizedServiceAccount.privateKey
    ) {
      return {
        credential: cert(normalizedServiceAccount),
        projectId: normalizedServiceAccount.projectId
      };
    }

    if (normalizedServiceAccount.projectId) {
      return {
        credential: applicationDefault(),
        projectId: normalizedServiceAccount.projectId
      };
    }
  }

  const privateKey = normalizePrivateKey(runtimeConfig.firebase.privateKey);
  if (
    runtimeConfig.firebase.projectId &&
    runtimeConfig.firebase.clientEmail &&
    privateKey
  ) {
    return {
      credential: cert({
        projectId: runtimeConfig.firebase.projectId,
        clientEmail: runtimeConfig.firebase.clientEmail,
        privateKey
      }),
      projectId: runtimeConfig.firebase.projectId
    };
  }

  if (runtimeConfig.firebase.projectId) {
    return {
      credential: applicationDefault(),
      projectId: runtimeConfig.firebase.projectId
    };
  }

  return null;
}

function getFirebaseApp() {
  const existingApp = getApps()[0];
  if (existingApp) {
    return existingApp;
  }

  const config = buildFirebaseCredentialConfig();
  if (!config) {
    throw toAppError(
      'Authentification Google non configuree sur le serveur',
      503,
      'GOOGLE_AUTH_NOT_CONFIGURED'
    );
  }

  return initializeApp(config);
}

function isFirebaseAuthConfigured(dependencies = {}) {
  if (typeof dependencies.firebaseConfigured === 'boolean') {
    return dependencies.firebaseConfigured;
  }

  return buildFirebaseCredentialConfig() !== null;
}

function isGoogleOidcConfigured(dependencies = {}) {
  return getGoogleClientIds(dependencies).length > 0;
}

export function isGoogleAuthConfigured(dependencies = {}) {
  return (
    isFirebaseAuthConfigured(dependencies) ||
    isGoogleOidcConfigured(dependencies)
  );
}

function normalizeVerifiedGoogleProfile(payload, options = {}) {
  const subject = payload?.uid || payload?.sub;

  if (!subject) {
    throw toAppError('Token Google invalide', 401, 'INVALID_GOOGLE_TOKEN');
  }

  if (options.requireGoogleProvider) {
    if (payload.firebase?.sign_in_provider !== 'google.com') {
      throw toAppError(
        'Ce jeton Firebase ne provient pas d une connexion Google',
        401,
        'INVALID_GOOGLE_TOKEN'
      );
    }
  }

  if (!payload.email) {
    throw toAppError(
      'Votre compte Google ne fournit pas d adresse email exploitable',
      400,
      'GOOGLE_EMAIL_REQUIRED'
    );
  }

  return {
    sub: subject,
    email: String(payload.email).trim().toLowerCase(),
    email_verified: Boolean(payload.email_verified),
    given_name: payload.given_name || null,
    family_name: payload.family_name || null,
    name: payload.name || null,
    picture: payload.picture || null
  };
}

async function verifyFirebaseGoogleIdToken(idToken, dependencies = {}) {
  const verifyFirebaseToken =
    dependencies.verifyFirebaseToken ||
    (async (token) => getAuth(getFirebaseApp()).verifyIdToken(token));

  try {
    const payload = await verifyFirebaseToken(idToken);
    return normalizeVerifiedGoogleProfile(payload, {
      requireGoogleProvider: true
    });
  } catch (error) {
    if (error?.code) {
      throw error;
    }

    throw toAppError(
      'Token Google invalide ou expire',
      401,
      'INVALID_GOOGLE_TOKEN'
    );
  }
}

async function verifyGoogleOidcIdToken(idToken, dependencies = {}) {
  const googleClientIds = getGoogleClientIds(dependencies);
  if (!googleClientIds.length) {
    throw toAppError(
      'Authentification Google non configuree sur le serveur',
      503,
      'GOOGLE_AUTH_NOT_CONFIGURED'
    );
  }

  const verifyGoogleOauthToken =
    dependencies.verifyGoogleOauthToken ||
    (async (token, audiences) => {
      const ticket = await (dependencies.oauthClient || googleOAuthClient).verifyIdToken({
        idToken: token,
        audience: audiences
      });
      return ticket.getPayload();
    });

  try {
    const payload = await verifyGoogleOauthToken(idToken, googleClientIds);
    return normalizeVerifiedGoogleProfile(payload);
  } catch (error) {
    if (error?.code) {
      throw error;
    }

    throw toAppError(
      'Token Google invalide ou expire',
      401,
      'INVALID_GOOGLE_TOKEN'
    );
  }
}

export async function verifyGoogleIdToken(idToken, dependencies = {}) {
  if (!isGoogleAuthConfigured(dependencies)) {
    throw toAppError(
      'Authentification Google non configuree sur le serveur',
      503,
      'GOOGLE_AUTH_NOT_CONFIGURED'
    );
  }

  const decodedPayload = decodeJwtPayload(idToken);
  const issuer = String(decodedPayload?.iss || '').trim();
  const verificationSteps = [];

  const addFirebaseVerification = () => {
    if (isFirebaseAuthConfigured(dependencies)) {
      verificationSteps.push(() =>
        verifyFirebaseGoogleIdToken(idToken, dependencies)
      );
    }
  };

  const addGoogleOidcVerification = () => {
    if (isGoogleOidcConfigured(dependencies)) {
      verificationSteps.push(() =>
        verifyGoogleOidcIdToken(idToken, dependencies)
      );
    }
  };

  if (isGoogleOidcIssuer(issuer)) {
    addGoogleOidcVerification();
    addFirebaseVerification();
  } else if (isFirebaseIssuer(issuer, getFirebaseProjectId(dependencies))) {
    addFirebaseVerification();
    addGoogleOidcVerification();
  } else {
    addFirebaseVerification();
    addGoogleOidcVerification();
  }

  let lastError = null;
  for (const verifyStep of verificationSteps) {
    try {
      return await verifyStep();
    } catch (error) {
      lastError = error;
      if (error?.code && error.code !== 'INVALID_GOOGLE_TOKEN') {
        throw error;
      }
    }
  }

  throw (
    lastError ||
    toAppError('Token Google invalide ou expire', 401, 'INVALID_GOOGLE_TOKEN')
  );
}
