'use client';

import { initializeApp, getApps, getApp } from 'firebase/app';
import type { FirebaseApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import type { Auth, User } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import type { Firestore } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';

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
  return getFirestore(getAppInstance());
}

/** Call a HOM Cloud Function; rejects with a plain Error carrying the server message. */
export async function callFunction(name: string, data?: object): Promise<any> {
  const fn = httpsCallable(getFunctions(getAppInstance()), name);
  try {
    const res = await fn(data);
    return res.data;
  } catch (err: any) {
    const message =
      (typeof err?.details === 'object' && err?.details?.message) ||
      err?.message ||
      'Something went wrong.';
    throw new Error(message);
  }
}

/** Google sign-in via popup. Returns the signed-in Firebase user. */
export async function firebaseGoogleSignIn(): Promise<User> {
  const cred = await signInWithPopup(getAuthInstance(), new GoogleAuthProvider());
  return cred.user;
}
