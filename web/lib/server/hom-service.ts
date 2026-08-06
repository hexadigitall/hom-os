import { randomBytes } from 'crypto';
import { ApiError } from './api';
import { adminAuth, adminDb } from './firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

/**
 * HOM — server-authoritative identity, roles and invites.
 *
 * Clients NEVER write user_roles, hotels or invites directly. Every identity
 * and privilege change flows through these operations, which validate the
 * request against Firestore (Admin SDK) and fail closed. This is what makes
 * the locked firestore.rules safe: the only writers are these functions.
 *
 * Mirrors functions/index.js (the Cloud Functions variant). When the project
 * moves to Blaze, the callables can be re-hosted from that same logic.
 */

const ADMIN_ROLES = ['super_admin', 'hotel_manager'];
const VALID_DEPARTMENTS = [
  'management', 'reception', 'concierge', 'reservations', 'housekeeping',
  'laundry', 'engineering', 'restaurants', 'kitchen', 'banqueting',
  'procurement', 'accounts', 'humanResources', 'security', 'healthSafety',
];
const VALID_STATUS = ['pending', 'active', 'suspended'];
const VALID_LANGUAGES = ['en', 'fr', 'es', 'ha', 'yo', 'ig'];
const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

const isEmail = (v: unknown): boolean =>
  typeof v === 'string' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v);

const cleanStrings = (list: unknown, allowed?: readonly string[]): string[] => {
  if (!Array.isArray(list)) return [];
  return Array.from(
    new Set(
      list.filter(
        (x): x is string => typeof x === 'string' && (allowed ? allowed.includes(x) : true),
      ),
    ),
  );
};

const serverTimestamp = () => FieldValue.serverTimestamp();

/** Fetch the caller's role doc, throwing unless they are an ACTIVE admin. */
async function requireAdmin(uid: string): Promise<Record<string, any>> {
  const snap = await adminDb().collection('user_roles').doc(uid).get();
  if (!snap.exists) throw new ApiError('Account not provisioned.', 403);
  const role = snap.data()!;
  if (role.status !== 'active') throw new ApiError('Account is not active.', 403);
  if (!role.roleIds || !role.roleIds.some((r: string) => ADMIN_ROLES.includes(r))) {
    throw new ApiError('Admin access required.', 403);
  }
  return role;
}

/** Fetch the caller's role doc; any ACTIVE provisioned user passes. */
async function requireSelf(uid: string): Promise<Record<string, any>> {
  const snap = await adminDb().collection('user_roles').doc(uid).get();
  if (!snap.exists) throw new ApiError('Account not provisioned.', 403);
  const role = snap.data()!;
  if (role.status !== 'active') throw new ApiError('Account is not active.', 403);
  return role;
}

function generateInviteCode(): string {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = randomBytes(5).toString('hex').toUpperCase();
  return ts + rand;
}

async function findInviteForUser(uid: string): Promise<Record<string, any> | null> {
  const snap = await adminDb().collection('user_roles').doc(uid).get();
  return snap.exists ? snap.data()! : null;
}

function roleDocData({
  userId, roleIds, userName, hotelId, hotelName, email, departments,
  customPermissions, isHead, status,
}: {
  userId: string;
  roleIds: string[];
  userName: string;
  hotelId: string;
  hotelName: string;
  email: string;
  departments: string[];
  customPermissions: string[];
  isHead: boolean;
  status: string;
}): Record<string, any> {
  return {
    userId,
    roleIds,
    userName,
    hotelId,
    hotelName: hotelName || '',
    email,
    assignedDepartments: departments,
    customPermissions,
    isHeadOfDepartment: isHead
      ? Object.fromEntries(departments.map((d) => [d, true]))
      : {},
    status,
    updatedAt: serverTimestamp(),
  };
}

/** Atomically consume an invite and provision a role doc for [uid]. */
async function consumeInvite(
  code: string,
  uid: string,
  profile?: { name?: string; email?: string },
): Promise<Record<string, any>> {
  const db = adminDb();
  const inviteRef = db.collection('invites').doc(code);
  return db.runTransaction(async (t) => {
    const snap = await t.get(inviteRef);
    if (!snap.exists) throw new ApiError('Invalid invite code.', 404);
    const inv = snap.data()!;
    if (inv.usedByUserId) throw new ApiError('This invite code has already been used.', 409);
    if (inv.expiresAt && new Date(inv.expiresAt).getTime() < Date.now()) {
      throw new ApiError('This invite code has expired.', 400);
    }
    const departments = cleanStrings(inv.departments, VALID_DEPARTMENTS);
    const name = profile?.name?.trim() || inv.userNameHint || 'Staff';
    const email = profile?.email?.trim() || inv.emailHint || '';
    t.set(db.collection('user_roles').doc(uid), roleDocData({
      userId: uid,
      roleIds: [inv.roleId],
      userName: name,
      hotelId: inv.hotelId,
      hotelName: inv.hotelName || '',
      email,
      departments,
      customPermissions: [],
      isHead: inv.isHead === true,
      status: 'active',
    }));
    t.update(inviteRef, { usedByUserId: uid, usedAt: new Date().toISOString() });
    return inv;
  });
}

// ──────────────────── onboarding (sign-up) ────────────────────

/**
 * Owner bootstrap. Creates the Firebase Auth account, the hotel document and
 * the super_admin role document atomically. Unauthenticated by design.
 */
export async function signupOwner(input: Record<string, any>): Promise<{ hotelId: string }> {
  const { name, email, phone, password, hotelName } = input || {};
  if (!name || !email || !password || !hotelName) {
    throw new ApiError('Name, email, password and hotel name are required.');
  }
  if (!isEmail(email)) throw new ApiError('Invalid email address.');
  if (String(password).length < 6) {
    throw new ApiError('Password must be at least 6 characters.');
  }

  const existing = await adminAuth().getUserByEmail(email).catch(() => null);
  if (existing) throw new ApiError('An account with this email already exists.', 409);

  const db = adminDb();
  const hotelId = db.collection('hotels').doc().id;
  const user = await adminAuth().createUser({ email, password, displayName: name });

  await db.collection('hotels').doc(hotelId).set({
    name: hotelName,
    ownerUid: user.uid,
    createdAt: serverTimestamp(),
  });
  await db.collection('user_roles').doc(user.uid).set(roleDocData({
    userId: user.uid,
    roleIds: ['super_admin'],
    userName: name,
    hotelId,
    hotelName,
    email,
    departments: [],
    customPermissions: [],
    isHead: false,
    status: 'active',
  }));

  return { hotelId };
}

/**
 * Owner bootstrap for already-authenticated accounts (Google sign-up).
 * Creates the hotel document and the super_admin role document for the
 * signed-in user. Idempotent: if the account is already provisioned, it just
 * returns the existing hotel.
 */
export async function provisionOwner(
  uid: string,
  email: string,
  input: Record<string, any>,
): Promise<{ hotelId: string }> {
  const { name, phone, hotelName } = input || {};
  if (!name || !hotelName) {
    throw new ApiError('Your name and hotel name are required.');
  }

  const existing = await findInviteForUser(uid);
  if (existing) return { hotelId: existing.hotelId };

  const db = adminDb();
  const hotelId = db.collection('hotels').doc().id;
  await db.collection('hotels').doc(hotelId).set({
    name: hotelName,
    ownerUid: uid,
    createdAt: serverTimestamp(),
  });
  await db.collection('user_roles').doc(uid).set(roleDocData({
    userId: uid,
    roleIds: ['super_admin'],
    userName: name,
    hotelId,
    hotelName,
    email,
    departments: [],
    customPermissions: [],
    isHead: false,
    status: 'active',
  }));

  return { hotelId };
}

/**
 * Staff sign-up from an invite code (email/password). The invite is consumed
 * and the account is provisioned in one transaction.
 */
export async function signupStaff(input: Record<string, any>): Promise<{ hotelId: string }> {
  const { inviteCode, name, email, phone, password } = input || {};
  if (!inviteCode || !name || !email || !password) {
    throw new ApiError('Invite code, name, email and password are required.');
  }
  if (!isEmail(email)) throw new ApiError('Invalid email address.');
  if (String(password).length < 6) {
    throw new ApiError('Password must be at least 6 characters.');
  }
  const code = String(inviteCode).trim().toUpperCase();

  const existing = await adminAuth().getUserByEmail(email).catch(() => null);
  if (existing) throw new ApiError('An account with this email already exists.', 409);

  const user = await adminAuth().createUser({ email, password, displayName: name });

  let invite: Record<string, any>;
  try {
    // Note: a throw inside the transaction aborts the whole thing, so if the
    // invite is bad we must clean up the auth user we just created.
    invite = await consumeInvite(code, user.uid);
  } catch (err) {
    await adminAuth().deleteUser(user.uid).catch(() => {});
    throw err;
  }
  await adminDb().collection('user_roles').doc(user.uid).update({
    userName: name,
    email,
    isHeadOfDepartment: invite.isHead === true
      ? Object.fromEntries(cleanStrings(invite.departments, VALID_DEPARTMENTS).map((d) => [d, true]))
      : {},
  });

  return { hotelId: invite.hotelId };
}

/**
 * Link an already-authenticated account (e.g. Google) to an invite code.
 * Used when a staff member signs up with Google: their Firebase UID already
 * exists, so we only consume the invite and provision the role document.
 */
export async function redeemInvite(
  uid: string,
  email: string,
  input: Record<string, any>,
): Promise<{ hotelId: string }> {
  const { inviteCode } = input || {};
  if (!inviteCode) throw new ApiError('Invite code is required.');

  const existing = await findInviteForUser(uid);
  if (existing) {
    // Already provisioned — idempotent, but back-fill the display name/email
    // when the verified caller identity is richer than what the invite recorded.
    const name = typeof input?.name === 'string' && input.name.trim()
      ? input.name.trim()
      : existing.userName;
    const em = email || existing.email || '';
    const patch: Record<string, any> = {};
    if (name && name !== existing.userName) patch.userName = name;
    if (em && em !== existing.email) patch.email = em;
    if (Object.keys(patch).length > 0) {
      await adminDb().collection('user_roles').doc(uid).update(patch);
    }
    return { hotelId: existing.hotelId };
  }

  const code = String(inviteCode).trim().toUpperCase();
  const invite = await consumeInvite(code, uid, {
    name: typeof input?.name === 'string' ? input.name : undefined,
    email: email || undefined,
  });

  return { hotelId: invite.hotelId };
}

// ──────────────────── invite management ────────────────────

/** Owner/manager creates a single-use invite for their hotel. */
export async function createInvite(
  uid: string,
  input: Record<string, any>,
): Promise<{ code: string; invite: Record<string, any> }> {
  const adminRole = await requireAdmin(uid);
  const { roleId, roleName, departments, isHead } = input || {};
  if (!roleId) throw new ApiError('A role is required.');
  if (roleId === 'super_admin' || roleId === 'auditor') {
    throw new ApiError('This role cannot be granted by invitation.');
  }
  const depts = cleanStrings(departments, VALID_DEPARTMENTS);

  const code = generateInviteCode();
  const now = new Date();
  const invite: Record<string, any> = {
    code,
    roleId,
    roleName: typeof roleName === 'string' && roleName ? roleName : roleId,
    departments: depts,
    isHead: isHead === true,
    hotelId: adminRole.hotelId,
    hotelName: adminRole.hotelName || '',
    createdAt: now.toISOString(),
    expiresAt: new Date(now.getTime() + INVITE_TTL_MS).toISOString(),
  };
  await adminDb().collection('invites').doc(code).set(invite);
  return { code, invite };
}

/** Owner/manager lists their hotel's invites. */
export async function listInvites(
  uid: string,
): Promise<{ invites: Array<Record<string, any>> }> {
  const adminRole = await requireAdmin(uid);
  const snap = await adminDb().collection('invites')
    .where('hotelId', '==', adminRole.hotelId)
    .orderBy('createdAt', 'desc')
    .get();
  return {
    invites: snap.docs.map((d) => ({ code: d.id, ...d.data() })),
  };
}

/** Owner/manager revokes an invite before it is used. */
export async function deleteInvite(uid: string, input: Record<string, any>): Promise<{ ok: boolean }> {
  const adminRole = await requireAdmin(uid);
  const { code } = input || {};
  if (!code) throw new ApiError('Invite code is required.');
  const snap = await adminDb().collection('invites').doc(String(code).trim().toUpperCase()).get();
  if (!snap.exists) return { ok: true };
  if (snap.data()!.hotelId !== adminRole.hotelId) {
    throw new ApiError('This invite does not belong to your hotel.', 403);
  }
  await snap.ref.delete();
  return { ok: true };
}

// ──────────────────── user (role) management ────────────────────

/** Owner/manager lists their hotel's users (role documents). */
export async function listUsers(uid: string): Promise<{ users: Array<Record<string, any>> }> {
  const adminRole = await requireAdmin(uid);
  const snap = await adminDb().collection('user_roles')
    .where('hotelId', '==', adminRole.hotelId)
    .get();
  return {
    users: snap.docs.map((d) => ({ uid: d.id, ...d.data() })),
  };
}

/** Owner/manager updates a staff member's assignments or status. */
export async function updateUserRole(
  uid: string,
  input: Record<string, any>,
): Promise<{ ok: boolean }> {
  const adminRole = await requireAdmin(uid);
  const {
    targetUid, roleIds, userName, assignedDepartments, customPermissions,
    isHeadOfDepartment, status,
  } = input || {};
  if (!targetUid) throw new ApiError('Target user is required.');

  const target = await adminDb().collection('user_roles').doc(targetUid).get();
  if (!target.exists) throw new ApiError('User not found.', 404);
  const targetData = target.data()!;
  if (targetData.hotelId !== adminRole.hotelId) {
    throw new ApiError('This user does not belong to your hotel.', 403);
  }

  const nextRoleIds = cleanStrings(roleIds, undefined);
  const isOwner = targetData.roleIds && targetData.roleIds.includes('super_admin');

  // Only a super_admin can change a super_admin, and only a super_admin can
  // grant the super_admin role.
  if (isOwner && !adminRole.roleIds.includes('super_admin')) {
    throw new ApiError('Only the owner can change an owner account.', 403);
  }
  if (nextRoleIds.includes('super_admin') && !adminRole.roleIds.includes('super_admin')) {
    throw new ApiError('Only the owner can grant owner access.', 403);
  }

  const updates: Record<string, any> = {
    updatedAt: serverTimestamp(),
  };
  if (roleIds !== undefined) updates.roleIds = nextRoleIds.length ? nextRoleIds : targetData.roleIds;
  if (userName !== undefined) updates.userName = String(userName);
  if (assignedDepartments !== undefined) updates.assignedDepartments = cleanStrings(assignedDepartments, VALID_DEPARTMENTS);
  if (customPermissions !== undefined) updates.customPermissions = cleanStrings(customPermissions, undefined);
  if (isHeadOfDepartment !== undefined) {
    updates.isHeadOfDepartment =
      isHeadOfDepartment && typeof isHeadOfDepartment === 'object'
        ? Object.fromEntries(
            Object.entries(isHeadOfDepartment)
              .map(([k, v]): [string, boolean] => [k, v === true])
              .filter(([k]) => VALID_DEPARTMENTS.includes(k)),
          )
        : {};
  }
  if (status !== undefined) {
    if (!VALID_STATUS.includes(status)) throw new ApiError('Invalid status.');
    updates.status = status;
  }

  await adminDb().collection('user_roles').doc(targetUid).update(updates);
  return { ok: true };
}

/** Owner/manager removes a staff account (role doc + Firebase Auth user). */
export async function deleteUserRole(uid: string, input: Record<string, any>): Promise<{ ok: boolean }> {
  const adminRole = await requireAdmin(uid);
  const { targetUid } = input || {};
  if (!targetUid) throw new ApiError('Target user is required.');

  const target = await adminDb().collection('user_roles').doc(targetUid).get();
  if (!target.exists) return { ok: true };
  const targetData = target.data()!;
  if (targetData.hotelId !== adminRole.hotelId) {
    throw new ApiError('This user does not belong to your hotel.', 403);
  }
  if (targetData.roleIds && targetData.roleIds.includes('super_admin')) {
    if (!adminRole.roleIds.includes('super_admin')) {
      throw new ApiError('Only the owner can delete an owner account.', 403);
    }
    throw new ApiError('Cannot delete the owner account from here.', 412);
  }

  await adminDb().collection('user_roles').doc(targetUid).delete();
  await adminAuth().deleteUser(targetUid).catch(() => {});
  return { ok: true };
}

// ──────────────────── self-service profile ────────────────────

/**
 * Self-service profile update. ANY active user may edit their own display
 * name, phone, avatar URL and app preferences. Writes land on the same
 * `user_roles/{uid}` doc both apps already listen to in realtime, so a change
 * propagates to every device (mobile + web) instantly.
 */
export async function updateSelfProfile(
  uid: string,
  input: Record<string, any>,
): Promise<{ ok: boolean }> {
  const role = await requireSelf(uid);
  const updates: Record<string, any> = { updatedAt: serverTimestamp() };
  const { userName, phone, photoUrl, preferences } = input || {};

  if (userName !== undefined) {
    const name = String(userName).trim();
    if (!name || name.length > 80) throw new ApiError('Name must be 1–80 characters.');
    if (name !== role.userName) updates.userName = name;
  }
  if (phone !== undefined) {
    if (phone !== null && typeof phone !== 'string') {
      throw new ApiError('Invalid phone.');
    }
    updates.phone = phone ? String(phone).trim().slice(0, 40) : '';
  }
  if (photoUrl !== undefined) {
    if (photoUrl !== null && typeof photoUrl !== 'string') {
      throw new ApiError('Invalid photo URL.');
    }
    updates.photoUrl = photoUrl ? String(photoUrl).trim().slice(0, 2000) : '';
  }
  if (preferences !== undefined) {
    if (typeof preferences !== 'object' || preferences === null || Array.isArray(preferences)) {
      throw new ApiError('Invalid preferences.');
    }
    const pref = preferences as Record<string, any>;
    const patch: Record<string, any> = {};
    if ('notificationsEnabled' in pref) {
      if (typeof pref.notificationsEnabled !== 'boolean') throw new ApiError('Invalid preferences.');
      patch.notificationsEnabled = pref.notificationsEnabled;
    }
    if ('compactMode' in pref) {
      if (typeof pref.compactMode !== 'boolean') throw new ApiError('Invalid preferences.');
      patch.compactMode = pref.compactMode;
    }
    if ('language' in pref) {
      if (typeof pref.language !== 'string' || !VALID_LANGUAGES.includes(pref.language)) {
        throw new ApiError('Invalid language.');
      }
      patch.language = pref.language;
    }
    if (Object.keys(patch).length > 0) updates.preferences = patch;
  }

  if (Object.keys(updates).length <= 1) return { ok: true };

  await adminDb().collection('user_roles').doc(uid).update(updates);
  if (updates.userName) {
    await adminAuth().updateUser(uid, { displayName: updates.userName }).catch(() => {});
  }
  return { ok: true };
}
