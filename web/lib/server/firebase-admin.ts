import { cert, getApps, getApp, initializeApp } from 'firebase-admin/app';
import type { App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

let app: App | undefined;

/**
 * Singleton firebase-admin app for the HOM server (Vercel API routes).
 *
 * Credentials come from the FIREBASE_SERVICE_ACCOUNT env var (the JSON of the
 * project's service-account key, set in Vercel env / .env.local). The Admin
 * SDK bypasses firestore.rules — it is the ONLY writer of hotels, user_roles
 * and invites, which is what makes the locked rules safe.
 */
export function getAdminApp(): App {
  if (app) return app;
  if (getApps().length) {
    app = getApp();
    return app;
  }
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT env var is not set.');
  }
  app = initializeApp({ credential: cert(JSON.parse(raw)) });
  return app;
}

export const adminDb = () => getFirestore(getAdminApp());
export const adminAuth = () => getAuth(getAdminApp());
