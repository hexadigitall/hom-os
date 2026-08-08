'use client';

import { createContext, useCallback, useContext, useEffect, useRef, useState, ReactNode } from 'react';
import { doc, getDoc, onSnapshot } from 'firebase/firestore';
import { onAuthStateChanged, signInWithEmailAndPassword, User } from 'firebase/auth';
import {
  Session, HotelUser, InviteCode, Department, AccountStatus,
  emptySession, DEFAULT_PREFERENCES, findRoleById, isDepartment, UserPreferences,
} from './rbac';
import {
  getAuthInstance, getFirestoreInstance, apiCall, firebaseGoogleSignIn,
} from './firebase';

const SESSION_CACHE = 'hom_web_session';

interface AuthContextValue {
  session: Session;
  users: HotelUser[];
  invites: InviteCode[];
  authReady: boolean;
  firebaseUid: string;
  login: (email: string, password: string) => Promise<string | null>;
  logout: () => Promise<void>;
  registerOwner: (d: { name: string; email: string; phone: string; password: string; hotelName: string }) => Promise<string | null>;
  registerStaff: (d: { inviteCode: string; name: string; email: string; phone: string; password: string }) => Promise<string | null>;
  signInWithGoogle: () => Promise<'provisioned' | 'unprovisioned'>;
  provisionOwner: (d: { name: string; hotelName: string; phone?: string }) => Promise<string | null>;
  redeemInvite: (inviteCode: string) => Promise<string | null>;
  generateInvite: (d: { roleId: string; departments: Department[]; isHead: boolean }) => Promise<string>;
  updateUser: (targetUid: string, patch: { roleIds?: string[]; userName?: string; assignedDepartments?: Department[]; customPermissions?: string[]; isHeadOfDepartment?: Record<string, boolean>; status?: AccountStatus }) => Promise<string | null>;
  updateSelf: (patch: { userName?: string; phone?: string; photoUrl?: string; preferences?: Partial<UserPreferences> }) => Promise<string | null>;
  deleteUser: (targetUid: string) => Promise<string | null>;
  deleteInvite: (code: string) => Promise<string | null>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const sessionFromRole = (data: any, user: User): Session => {
  const prefs = data?.preferences && typeof data.preferences === 'object' ? data.preferences : {};
  return {
    userId: data?.userId || user.uid,
    userName: data?.userName || user.displayName || '',
    email: data?.email || user.email || '',
    roleIds: Array.isArray(data?.roleIds)
      ? data.roleIds.filter((r: unknown): r is string => typeof r === 'string')
      : [],
    assignedDepartments: Array.isArray(data?.assignedDepartments)
      ? data.assignedDepartments.filter(isDepartment)
      : [],
    customPermissions: Array.isArray(data?.customPermissions)
      ? data.customPermissions.filter((p: unknown): p is string => typeof p === 'string')
      : [],
    isHeadOfDepartment: data?.isHeadOfDepartment && typeof data.isHeadOfDepartment === 'object'
      ? data.isHeadOfDepartment
      : {},
    status: ['pending', 'active', 'suspended'].includes(data?.status) ? data.status : 'pending',
    hotelId: data?.hotelId || undefined,
    hotelName: typeof data?.hotelName === 'string' && data.hotelName
      ? data.hotelName
      : undefined,
    phone: typeof data?.phone === 'string' ? data.phone : '',
    photoUrl: typeof data?.photoUrl === 'string' && data.photoUrl
      ? data.photoUrl
      : (user.photoURL || undefined),
    preferences: {
      notificationsEnabled: typeof prefs.notificationsEnabled === 'boolean'
        ? prefs.notificationsEnabled
        : DEFAULT_PREFERENCES.notificationsEnabled,
      compactMode: typeof prefs.compactMode === 'boolean'
        ? prefs.compactMode
        : DEFAULT_PREFERENCES.compactMode,
      language: typeof prefs.language === 'string'
        ? prefs.language
        : DEFAULT_PREFERENCES.language,
    },
  };
};

const errMsg = (err: any): string => err?.message || 'Something went wrong.';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session>(() => emptySession());
  const [users, setUsers] = useState<HotelUser[]>([]);
  const [invites, setInvites] = useState<InviteCode[]>([]);
  const [authReady, setAuthReady] = useState(false);
  const [firebaseUid, setFirebaseUid] = useState('');
  const roleUnsub = useRef<(() => void) | null>(null);

  const applySession = useCallback((s: Session) => {
    setSession(s);
    try { localStorage.setItem(SESSION_CACHE, JSON.stringify(s)); } catch { /* ignore */ }
  }, []);

  const refreshUsers = useCallback(async () => {
    try {
      const res = await apiCall('GET', '/api/users');
      const list: HotelUser[] = (res.users || []).map((u: any) => ({
        userId: u.uid,
        name: u.userName || '',
        email: u.email || '',
        phone: '',
        passwordHash: '',
        roleId: (u.roleIds && u.roleIds[0]) || '',
        roleIds: Array.isArray(u.roleIds) ? u.roleIds : [],
        assignedDepartments: Array.isArray(u.assignedDepartments) ? u.assignedDepartments.filter(isDepartment) : [],
        customPermissions: Array.isArray(u.customPermissions) ? u.customPermissions : [],
        isHeadOfDepartment: u.isHeadOfDepartment || {},
        status: ['pending', 'active', 'suspended'].includes(u.status) ? u.status : 'pending',
        hotelId: u.hotelId || '',
        hotelName: u.hotelName || '',
        createdAt: u.createdAt || '',
      }));
      setUsers(list);
    } catch { /* admin may be offline — keep last known list */ }
  }, []);

  const refreshInvites = useCallback(async () => {
    try {
      const res = await apiCall('GET', '/api/invites');
      setInvites(res.invites || []);
    } catch { /* keep last known list */ }
  }, []);

  // Firebase auth + real-time role document listener.
  useEffect(() => {
    const auth = getAuthInstance();
    const unsubAuth = onAuthStateChanged(auth, (user) => {
      if (!user) {
        roleUnsub.current?.();
        roleUnsub.current = null;
        setFirebaseUid('');
        setUsers([]);
        setInvites([]);
        applySession(emptySession());
        setAuthReady(true);
        return;
      }
      setFirebaseUid(user.uid);
      // Hydrate from cache immediately so the shell renders, then correct from Firestore.
      try {
        const cached = localStorage.getItem(SESSION_CACHE);
        if (cached) {
          const parsed = JSON.parse(cached);
          if (parsed && parsed.userId) setSession(parsed);
        }
      } catch { /* ignore */ }
      setAuthReady(true);

      const db = getFirestoreInstance();
      roleUnsub.current?.();
      roleUnsub.current = onSnapshot(
        doc(db, 'user_roles', user.uid),
        (snap) => {
          if (snap.exists()) {
            const s = sessionFromRole(snap.data(), user);
            applySession(s);
            if (s.roleIds.includes('super_admin') || s.roleIds.includes('hotel_manager')) {
              refreshUsers();
              refreshInvites();
            }
          } else {
            // Signed in but not yet provisioned (awaiting an invite code).
            applySession(emptySession());
          }
        },
        () => { /* offline / permission — keep cached session */ },
      );
    });
    return () => { unsubAuth(); roleUnsub.current?.(); };
  }, [applySession, refreshUsers, refreshInvites]);

  const login = useCallback(async (email: string, password: string): Promise<string | null> => {
    try {
      await signInWithEmailAndPassword(getAuthInstance(), email.trim(), password);
      return null;
    } catch (err: any) {
      const code = err?.code || '';
      if (['auth/user-not-found', 'auth/wrong-password', 'auth/invalid-credential', 'auth/invalid-login-credentials'].includes(code)) {
        return 'Invalid email or password.';
      }
      return errMsg(err);
    }
  }, []);

  const logout = useCallback(async () => {
    await getAuthInstance().signOut().catch(() => {});
    try { localStorage.removeItem(SESSION_CACHE); } catch { /* ignore */ }
    applySession(emptySession());
  }, [applySession]);

  const registerOwner = useCallback(async (d: { name: string; email: string; phone: string; password: string; hotelName: string }): Promise<string | null> => {
    try {
      await apiCall('POST', '/api/auth/signup-owner', {
        name: d.name, email: d.email.trim(), phone: d.phone, password: d.password, hotelName: d.hotelName,
      });
      await signInWithEmailAndPassword(getAuthInstance(), d.email.trim(), d.password);
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, []);

  const registerStaff = useCallback(async (d: { inviteCode: string; name: string; email: string; phone: string; password: string }): Promise<string | null> => {
    try {
      await apiCall('POST', '/api/auth/signup-staff', {
        inviteCode: d.inviteCode.trim().toUpperCase(),
        name: d.name, email: d.email.trim(), phone: d.phone, password: d.password,
      });
      await signInWithEmailAndPassword(getAuthInstance(), d.email.trim(), d.password);
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, []);

  const signInWithGoogle = useCallback(async (): Promise<'provisioned' | 'unprovisioned'> => {
    const user = await firebaseGoogleSignIn();
    const snap = await getDoc(doc(getFirestoreInstance(), 'user_roles', user.uid));
    return snap.exists() ? 'provisioned' : 'unprovisioned';
  }, []);

  const provisionOwner = useCallback(async (d: { name: string; hotelName: string; phone?: string }): Promise<string | null> => {
    try {
      await apiCall('POST', '/api/auth/provision-owner', { name: d.name, hotelName: d.hotelName, phone: d.phone || '' });
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, []);

  const redeemInvite = useCallback(async (inviteCode: string): Promise<string | null> => {
    try {
      await apiCall('POST', '/api/auth/redeem-invite', { inviteCode: inviteCode.trim().toUpperCase() });
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, []);

  const generateInvite = useCallback(async (d: { roleId: string; departments: Department[]; isHead: boolean }): Promise<string> => {
    const res = await apiCall('POST', '/api/invites', {
      roleId: d.roleId,
      roleName: findRoleById(d.roleId)?.name || d.roleId,
      departments: d.departments,
      isHead: d.isHead,
    });
    refreshInvites();
    return res.code as string;
  }, [refreshInvites]);

  const updateUser = useCallback(async (targetUid: string, patch: { roleIds?: string[]; userName?: string; assignedDepartments?: Department[]; customPermissions?: string[]; isHeadOfDepartment?: Record<string, boolean>; status?: AccountStatus }): Promise<string | null> => {
    try {
      await apiCall('PATCH', `/api/users/${encodeURIComponent(targetUid)}`, patch);
      refreshUsers();
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, [refreshUsers]);

  const deleteUser = useCallback(async (targetUid: string): Promise<string | null> => {
    try {
      await apiCall('DELETE', `/api/users/${encodeURIComponent(targetUid)}`);
      refreshUsers();
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, [refreshUsers]);

  const updateSelf = useCallback(async (patch: { userName?: string; phone?: string; photoUrl?: string; preferences?: Partial<UserPreferences> }): Promise<string | null> => {
    try {
      await apiCall('PATCH', '/api/users/me', patch);
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, []);

  const deleteInvite = useCallback(async (code: string): Promise<string | null> => {
    try {
      await apiCall('DELETE', `/api/invites/${encodeURIComponent(code)}`);
      refreshInvites();
      return null;
    } catch (err: any) {
      return errMsg(err);
    }
  }, [refreshInvites]);

  return (
    <AuthContext.Provider value={{
      session, users, invites, authReady, firebaseUid,
      login, logout, registerOwner, registerStaff, signInWithGoogle,
      provisionOwner, redeemInvite, generateInvite, updateUser, updateSelf, deleteUser, deleteInvite,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
