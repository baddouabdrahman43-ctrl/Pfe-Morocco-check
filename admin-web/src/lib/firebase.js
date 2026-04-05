import { initializeApp } from 'firebase/app';
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  signOut
} from 'firebase/auth';

const runtimeEnv =
  typeof import.meta !== 'undefined' && import.meta.env
    ? import.meta.env
    : {};

const firebaseConfig = {
  apiKey: `${runtimeEnv.VITE_FIREBASE_API_KEY || ''}`.trim(),
  authDomain: `${runtimeEnv.VITE_FIREBASE_AUTH_DOMAIN || ''}`.trim(),
  projectId: `${runtimeEnv.VITE_FIREBASE_PROJECT_ID || ''}`.trim(),
  storageBucket: `${runtimeEnv.VITE_FIREBASE_STORAGE_BUCKET || ''}`.trim(),
  messagingSenderId: `${runtimeEnv.VITE_FIREBASE_MESSAGING_SENDER_ID || ''}`.trim(),
  appId: `${runtimeEnv.VITE_FIREBASE_APP_ID || ''}`.trim()
};

let firebaseApp;
let firebaseAuth;

export function isFirebaseAuthConfigured() {
  return Boolean(
    firebaseConfig.apiKey &&
      firebaseConfig.authDomain &&
      firebaseConfig.projectId &&
      firebaseConfig.messagingSenderId &&
      firebaseConfig.appId
  );
}

function getFirebaseAuthInstance() {
  if (!isFirebaseAuthConfigured()) {
    throw new Error(
      'La configuration Firebase du dashboard admin est incomplete.'
    );
  }

  if (!firebaseApp) {
    firebaseApp = initializeApp(firebaseConfig);
  }

  if (!firebaseAuth) {
    firebaseAuth = getAuth(firebaseApp);
  }

  return firebaseAuth;
}

export async function getGoogleFirebaseIdToken() {
  try {
    const auth = getFirebaseAuthInstance();
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });

    const result = await signInWithPopup(auth, provider);
    const idToken = await result.user.getIdToken(true);

    if (!idToken) {
      throw new Error(
        'Firebase n a pas fourni de jeton d identification exploitable.'
      );
    }

    return idToken;
  } catch (error) {
    throw new Error(mapFirebaseError(error));
  }
}

export async function signOutFirebaseSilently() {
  if (!firebaseAuth) {
    return;
  }

  try {
    await signOut(firebaseAuth);
  } catch (_error) {
    // Best effort only.
  }
}

function mapFirebaseError(error) {
  switch (error?.code) {
    case 'auth/popup-closed-by-user':
      return 'Connexion Google annulee.';
    case 'auth/popup-blocked':
      return 'Le navigateur a bloque la fenetre de connexion Google.';
    case 'auth/cancelled-popup-request':
      return 'Une autre tentative de connexion Google est deja en cours.';
    case 'auth/network-request-failed':
      return 'Impossible de contacter Firebase pour le moment.';
    case 'auth/account-exists-with-different-credential':
      return 'Ce compte Google est deja associe a une autre methode de connexion.';
    default:
      return error?.message || 'Connexion Google impossible.';
  }
}
