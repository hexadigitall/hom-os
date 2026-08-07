'use client';

import { initializeApp, getApps, getApp } from 'firebase/app';
import type { FirebaseApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import type { Auth, User } from 'firebase/auth';
import {
  initializeFirestore,
  persistentLocalCache,
  persistentMultipleTabManager,
  CACHE_SIZE_UNLIMITED,
} from 'firebase/firestore';
import type { Firestore } from 'firebase/firestore';

// Firebase web app config (project hom-os) — mirrors mobile/lib/firebase_options.dart.
const FIREBASE_CONFIG = {
  apiKey: 'AIzaSyCIQYzEzDQEOcRSV_PriNCtPNjLOuOv4ps',
  appId: '1:925042136693:web:d790372a5338b4a6e64a3c',
  messagingSenderId: '925042136693',
  projectId: 'hom-os',
  authDomain: 'hom-os.firebaseapp.com',
  storageBucket: 'hom-os.firebasestorage.app',
  measurementId: 'G-0YVWRT9TZ9',
};

let appInstance: FirebaseApp | null = null;
let dbInstance: Firestore | null = null;

export function getAppInstance(): FirebaseApp {
  if (appInstance) return appInstance;
  if (getApps().length) {
    appInstance = getApp();
    return appInstance;
  }
  appInstance = initializeApp(FIREBASE_CONFIG);
  return appInstance;
}

export function getAuthInstance(): Auth {
  return getAuth(getAppInstance());
}

export function getFirestoreInstance(): Firestore {
  if (dbInstance) return dbInstance;
  // Persistent IndexedDB cache: reads and queued writes keep working offline,
  // and sync automatically on reconnection (offline-first business data).
  dbInstance = initializeFirestore(getAppInstance(), {
    localCache: persistentLocalCache({
      tabManager: persistentMultipleTabManager(),
      cacheSizeBytes: CACHE_SIZE_UNLIMITED,
    }),
  });
  return dbInstance;
}

/**
 * Call a HOM server endpoint (Vercel API routes backed by firebase-admin).
 * Carries the current Firebase ID token as a Bearer token; rejects with a
 * plain Error carrying the server message.
 */
export async function apiCall(method: string, path: string, data?: object): Promise<any> {
  const auth = getAuthInstance();
  const token = await auth.currentUser?.getIdToken().catch(() => undefined);
  const res = await fetch(path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: data !== undefined ? JSON.stringify(data) : undefined,
  });
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    const message =
      (body && typeof body.error === 'object' && (body.error as any)?.message) ||
      (body && typeof (body as any).message === 'string' && (body as any).message) ||
      'Something went wrong.';
    throw new Error(message);
  }
  return body ?? {};
}

/** Google sign-in via popup. Returns the signed-in Firebase user. */
export async function firebaseGoogleSignIn(): Promise<User> {
  const cred = await signInWithPopup(getAuthInstance(), new GoogleAuthProvider());
  return cred.user;
}
