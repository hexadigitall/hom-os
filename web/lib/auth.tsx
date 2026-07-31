'use client';

import { createContext, useCallback, useContext, useEffect, useState, ReactNode } from 'react';
import { load, save } from './storage';
import {
  HotelUser, InviteCode, Session, Department, hashPassword, verifyPassword,
  findRoleById, emptySession,
} from './rbac';

const USERS_KEY = 'hom_web_users';
const INVITES_KEY = 'hom_web_invites';
const SESSION_KEY = 'hom_web_session';

interface AuthContextValue {
  session: Session;
  users: HotelUser[];
  invites: InviteCode[];
  ownerRegistered: boolean;
  login: (email: string, password: string) => boolean;
  logout: () => void;
  registerOwner: (d: { name: string; email: string; phone: string; password: string; hotelName: string }) => void;
  registerStaff: (d: { inviteCode: string; name: string; email: string; phone: string; password: string }) => boolean;
  generateInvite: (d: { roleId: string; departments: Department[]; isHead: boolean }) => string;
  updateUser: (user: HotelUser) => void;
  deleteUser: (userId: string) => void;
  deleteInvite: (code: string) => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const loadUsers = (): HotelUser[] => load<HotelUser[]>(USERS_KEY, []);
const loadInvites = (): InviteCode[] => load<InviteCode[]>(INVITES_KEY, []);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session>(emptySession);
  const [users, setUsers] = useState<HotelUser[]>([]);
  const [invites, setInvites] = useState<InviteCode[]>([]);

  // Hydrate from localStorage on mount.
  useEffect(() => {
    setUsers(loadUsers());
    setInvites(loadInvites());
    const stored = load<Session | null>(SESSION_KEY, null);
    if (stored && stored.userId) {
      const user = loadUsers().find(u => u.userId === stored.userId);
      if (user) {
        setSession({ ...stored, status: user.status });
      } else {
        save(SESSION_KEY, null);
        setSession(emptySession());
      }
    }
  }, []);

  // Cross-tab real-time sync: an admin edit in another tab updates this one.
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === USERS_KEY) setUsers(loadUsers());
      if (e.key === INVITES_KEY) setInvites(loadInvites());
      if (e.key === SESSION_KEY) {
        const stored = load<Session | null>(SESSION_KEY, null);
        setSession(stored && stored.userId ? stored : emptySession());
      }
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  const persistSession = useCallback((s: Session) => {
    setSession(s);
    save(SESSION_KEY, s);
  }, []);

  const login = useCallback((email: string, password: string): boolean => {
    const user = loadUsers().find(u => u.email.toLowerCase() === email.trim().toLowerCase());
    if (!user || !verifyPassword(password, user.passwordHash)) return false;
    const s: Session = {
      userId: user.userId,
      userName: user.name,
      email: user.email,
      roleIds: user.roleIds,
      assignedDepartments: user.assignedDepartments,
      customPermissions: user.customPermissions,
      isHeadOfDepartment: user.isHeadOfDepartment,
      status: user.status,
      hotelId: user.hotelId,
    };
    persistSession(s);
    return true;
  }, [persistSession]);

  const logout = useCallback(() => {
    save(SESSION_KEY, null);
    setSession(emptySession());
  }, []);

  const registerOwner = useCallback((d: { name: string; email: string; phone: string; password: string; hotelName: string }) => {
    const list = loadUsers();
    const user: HotelUser = {
      userId: `usr_${Date.now().toString(36)}`,
      name: d.name,
      email: d.email.trim(),
      phone: d.phone,
      passwordHash: hashPassword(d.password),
      roleId: 'super_admin',
      roleIds: ['super_admin'],
      assignedDepartments: [],
      customPermissions: [],
      isHeadOfDepartment: {},
      status: 'active',
      hotelId: `hotel_${Date.now().toString(36)}`,
      hotelName: d.hotelName,
      createdAt: new Date().toISOString(),
    };
    const next = [...list, user];
    setUsers(next);
    save(USERS_KEY, next);
    persistSession({
      userId: user.userId,
      userName: user.name,
      email: user.email,
      roleIds: user.roleIds,
      assignedDepartments: user.assignedDepartments,
      customPermissions: user.customPermissions,
      isHeadOfDepartment: user.isHeadOfDepartment,
      status: user.status,
      hotelId: user.hotelId,
    });
  }, [persistSession]);

  const registerStaff = useCallback((d: { inviteCode: string; name: string; email: string; phone: string; password: string }): boolean => {
    const inv = loadInvites().find(i => i.code === d.inviteCode.trim().toUpperCase() && !i.usedByUserId);
    if (!inv) return false;
    const list = loadUsers();
    const user: HotelUser = {
      userId: `usr_${Date.now().toString(36)}`,
      name: d.name,
      email: d.email.trim(),
      phone: d.phone,
      passwordHash: hashPassword(d.password),
      roleId: inv.roleId,
      roleIds: [inv.roleId],
      assignedDepartments: inv.departments,
      customPermissions: [],
      isHeadOfDepartment: inv.isHead ? Object.fromEntries(inv.departments.map(dpt => [dpt, true])) : {},
      status: 'active',
      hotelId: inv.hotelId,
      hotelName: inv.hotelName,
      createdAt: new Date().toISOString(),
    };
    const nextUsers = [...list, user];
    setUsers(nextUsers);
    save(USERS_KEY, nextUsers);
    const nextInvites = loadInvites().map(i =>
      i.code === inv.code ? { ...i, usedByUserId: user.userId, usedAt: new Date().toISOString() } : i);
    setInvites(nextInvites);
    save(INVITES_KEY, nextInvites);
    persistSession({
      userId: user.userId,
      userName: user.name,
      email: user.email,
      roleIds: user.roleIds,
      assignedDepartments: user.assignedDepartments,
      customPermissions: user.customPermissions,
      isHeadOfDepartment: user.isHeadOfDepartment,
      status: user.status,
      hotelId: user.hotelId,
    });
    return true;
  }, [persistSession]);

  const generateInvite = useCallback((d: { roleId: string; departments: Department[]; isHead: boolean }): string => {
    const owner = loadUsers().find(u => u.roleId === 'super_admin');
    const role = findRoleById(d.roleId);
    const list = loadInvites();
    const ts = Date.now().toString(36).toUpperCase();
    const seq = (1000 + list.length).toString(36).toUpperCase();
    const code = `${ts}${seq}`;
    const invite: InviteCode = {
      code,
      roleId: d.roleId,
      roleName: role?.name || d.roleId,
      departments: d.departments,
      isHead: d.isHead,
      hotelId: owner?.hotelId || 'hotel_001',
      hotelName: owner?.hotelName || 'My Hotel',
      createdAt: new Date().toISOString(),
    };
    const next = [...list, invite];
    setInvites(next);
    save(INVITES_KEY, next);
    return code;
  }, []);

  const updateUser = useCallback((user: HotelUser) => {
    const next = loadUsers().map(u => (u.userId === user.userId ? user : u));
    setUsers(next);
    save(USERS_KEY, next);
    // If the updated account is the signed-in one, refresh the live session
    // so promotion/transfer/suspension apply immediately (mirrors Firestore sync).
    const stored = load<Session | null>(SESSION_KEY, null);
    if (stored && stored.userId === user.userId) {
      persistSession({
        ...stored,
        roleIds: user.roleIds,
        assignedDepartments: user.assignedDepartments,
        customPermissions: user.customPermissions,
        isHeadOfDepartment: user.isHeadOfDepartment,
        status: user.status,
      });
    }
  }, [persistSession]);

  const deleteUser = useCallback((userId: string) => {
    const next = loadUsers().filter(u => u.userId !== userId);
    setUsers(next);
    save(USERS_KEY, next);
    const stored = load<Session | null>(SESSION_KEY, null);
    if (stored && stored.userId === userId) {
      save(SESSION_KEY, null);
      setSession(emptySession());
    }
  }, []);

  const deleteInvite = useCallback((code: string) => {
    const next = loadInvites().filter(i => i.code !== code);
    setInvites(next);
    save(INVITES_KEY, next);
  }, []);

  const ownerRegistered = users.some(u => u.roleId === 'super_admin');

  return (
    <AuthContext.Provider value={{
      session,
      users,
      invites,
      ownerRegistered,
      login,
      logout,
      registerOwner,
      registerStaff,
      generateInvite,
      updateUser,
      deleteUser,
      deleteInvite,
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
