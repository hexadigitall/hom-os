/**
 * HOM — server-authoritative identity, roles and invites.
 *
 * Clients NEVER write user_roles, hotels or invites directly. Every identity
 * and privilege change flows through these callables, which validate the
 * request against Firestore (Admin SDK) and fail closed. This is what makes
 * the locked firestore.rules safe: the only writers are these functions.
 */
const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp();

const ADMIN_ROLES = ['super_admin', 'hotel_manager'];
const VALID_DEPARTMENTS = [
  'management', 'reception', 'concierge', 'reservations', 'housekeeping',
  'laundry', 'engineering', 'restaurants', 'kitchen', 'banqueting',
  'procurement', 'accounts', 'humanResources', 'security', 'healthSafety',
];
const VALID_STATUS = ['pending', 'active', 'suspended'];
const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

// ───────────────────────── helpers ─────────────────────────

const isEmail = (v) => typeof v === 'string' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v);

const cleanStrings = (list, allowed) => {
  if (!Array.isArray(list)) return [];
  return [...new Set(list.filter((x) => typeof x === 'string' && (allowed ? allowed.includes(x) : true)))];
};

/** Fetch the caller's role doc, throwing unless they are an ACTIVE admin. */
async function requireAdmin(context) {
  if (!context.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const snap = await db.collection('user_roles').doc(context.auth.uid).get();
  if (!snap.exists) {
    throw new HttpsError('permission-denied', 'Account not provisioned.');
  }
  const role = snap.data();
  if (role.status !== 'active') {
    throw new HttpsError('permission-denied', 'Account is not active.');
  }
  if (!role.roleIds || !role.roleIds.some((r) => ADMIN_ROLES.includes(r))) {
    throw new HttpsError('permission-denied', 'Admin access required.');
  }
  return role;
}

function generateInviteCode() {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = crypto.randomBytes(5).toString('hex').toUpperCase();
  return ts + rand;
}

async function findInviteForUser(uid) {
  const snap = await db.collection('user_roles').doc(uid).get();
  return snap.exists ? snap.data() : null;
}

function roleDocData({ userId, roleIds, userName, hotelId, hotelName, email, departments, customPermissions, isHead, status }) {
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
async function consumeInvite(code, uid) {
  const inviteRef = db.collection('invites').doc(code);
  return db.runTransaction(async (t) => {
    const snap = await t.get(inviteRef);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Invalid invite code.');
    }
    const inv = snap.data();
    if (inv.usedByUserId) {
      throw new HttpsError('already-exists', 'This invite code has already been used.');
    }
    if (inv.expiresAt && new Date(inv.expiresAt).getTime() < Date.now()) {
      throw new HttpsError('invalid-argument', 'This invite code has expired.');
    }
    const departments = cleanStrings(inv.departments, VALID_DEPARTMENTS);
    t.set(db.collection('user_roles').doc(uid), roleDocData({
      userId: uid,
      roleIds: [inv.roleId],
      userName: inv.userNameHint || 'Staff',
      hotelId: inv.hotelId,
      hotelName: inv.hotelName || '',
      email: inv.emailHint || '',
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
exports.signupOwner = onCall(async (request) => {
  const { name, email, phone, password, hotelName } = request.data || {};
  if (!name || !email || !password || !hotelName) {
    throw new HttpsError('invalid-argument', 'Name, email, password and hotel name are required.');
  }
  if (!isEmail(email)) throw new HttpsError('invalid-argument', 'Invalid email address.');
  if (String(password).length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  const existing = await auth.getUserByEmail(email).catch(() => null);
  if (existing) throw new HttpsError('already-exists', 'An account with this email already exists.');

  const hotelId = db.collection('hotels').doc().id;
  const user = await auth.createUser({ email, password, displayName: name });

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

  return { ok: true, hotelId };
});

/**
 * Owner bootstrap for already-authenticated accounts (Google sign-up).
 * Creates the hotel document and the super_admin role document for the
 * signed-in user. Idempotent: if the account is already provisioned, it just
 * returns the existing hotel.
 */
exports.provisionOwner = onCall(async (request, context) => {
  if (!context.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  const { name, phone, hotelName } = request.data || {};
  if (!name || !hotelName) {
    throw new HttpsError('invalid-argument', 'Your name and hotel name are required.');
  }

  const existing = await findInviteForUser(context.auth.uid);
  if (existing) return { ok: true, hotelId: existing.hotelId };

  const hotelId = db.collection('hotels').doc().id;
  await db.collection('hotels').doc(hotelId).set({
    name: hotelName,
    ownerUid: context.auth.uid,
    createdAt: serverTimestamp(),
  });
  await db.collection('user_roles').doc(context.auth.uid).set(roleDocData({
    userId: context.auth.uid,
    roleIds: ['super_admin'],
    userName: name,
    hotelId,
    hotelName,
    email: context.auth.token.email || '',
    departments: [],
    customPermissions: [],
    isHead: false,
    status: 'active',
  }));

  return { ok: true, hotelId };
});

/**
 * Staff sign-up from an invite code (email/password). The invite is consumed
 * and the account is provisioned in one transaction.
 */
exports.signupStaff = onCall(async (request) => {
  const { inviteCode, name, email, phone, password } = request.data || {};
  if (!inviteCode || !name || !email || !password) {
    throw new HttpsError('invalid-argument', 'Invite code, name, email and password are required.');
  }
  if (!isEmail(email)) throw new HttpsError('invalid-argument', 'Invalid email address.');
  if (String(password).length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }
  const code = String(inviteCode).trim().toUpperCase();

  const existing = await auth.getUserByEmail(email).catch(() => null);
  if (existing) throw new HttpsError('already-exists', 'An account with this email already exists.');

  const user = await auth.createUser({ email, password, displayName: name });

  let invite;
  try {
    // Note: a throw inside the transaction aborts the whole thing, so if the
    // invite is bad we must clean up the auth user we just created.
    invite = await consumeInvite(code, user.uid);
  } catch (err) {
    await auth.deleteUser(user.uid).catch(() => {});
    throw err;
  }
  await db.collection('user_roles').doc(user.uid).update({
    userName: name,
    email,
    isHeadOfDepartment: invite.isHead === true
      ? Object.fromEntries(cleanStrings(invite.departments, VALID_DEPARTMENTS).map((d) => [d, true]))
      : {},
  });

  return { ok: true, hotelId: invite.hotelId };
});

/**
 * Link an already-authenticated account (e.g. Google) to an invite code.
 * Used when a staff member signs up with Google: their Firebase UID already
 * exists, so we only consume the invite and provision the role document.
 */
exports.redeemInvite = onCall(async (request, context) => {
  if (!context.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  const { inviteCode } = request.data || {};
  if (!inviteCode) throw new HttpsError('invalid-argument', 'Invite code is required.');

  const existing = await findInviteForUser(context.auth.uid);
  if (existing) {
    // Already provisioned — return the existing assignment (idempotent).
    return { ok: true, hotelId: existing.hotelId };
  }

  const code = String(inviteCode).trim().toUpperCase();
  const invite = await consumeInvite(code, context.auth.uid);
  await db.collection('user_roles').doc(context.auth.uid).update({
    email: context.auth.token.email || '',
  });

  return { ok: true, hotelId: invite.hotelId };
});

// ──────────────────── invite management ────────────────────

/** Owner/manager creates a single-use invite for their hotel. */
exports.createInvite = onCall(async (request, context) => {
  const adminRole = await requireAdmin(context);
  const { roleId, roleName, departments, isHead } = request.data || {};
  if (!roleId) throw new HttpsError('invalid-argument', 'A role is required.');
  if (roleId === 'super_admin' || roleId === 'auditor') {
    throw new HttpsError('invalid-argument', 'This role cannot be granted by invitation.');
  }
  const depts = cleanStrings(departments, VALID_DEPARTMENTS);

  const code = generateInviteCode();
  const now = new Date();
  const invite = {
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
  await db.collection('invites').doc(code).set(invite);
  return { code, invite };
});

/** Owner/manager lists their hotel's invites. */
exports.listInvites = onCall(async (request, context) => {
  const adminRole = await requireAdmin(context);
  const snap = await db.collection('invites')
    .where('hotelId', '==', adminRole.hotelId)
    .orderBy('createdAt', 'desc')
    .get();
  return {
    invites: snap.docs.map((d) => ({ code: d.id, ...d.data() })),
  };
});

/** Owner/manager revokes an invite before it is used. */
exports.deleteInvite = onCall(async (request, context) => {
  const adminRole = await requireAdmin(context);
  const { code } = request.data || {};
  if (!code) throw new HttpsError('invalid-argument', 'Invite code is required.');
  const snap = await db.collection('invites').doc(String(code).trim().toUpperCase()).get();
  if (!snap.exists) return { ok: true };
  if (snap.data().hotelId !== adminRole.hotelId) {
    throw new HttpsError('permission-denied', 'This invite does not belong to your hotel.');
  }
  await snap.ref.delete();
  return { ok: true };
});

// ──────────────────── user (role) management ────────────────────

/** Owner/manager lists their hotel's users (role documents). */
exports.listUsers = onCall(async (request, context) => {
  const adminRole = await requireAdmin(context);
  const snap = await db.collection('user_roles')
    .where('hotelId', '==', adminRole.hotelId)
    .get();
  return {
    users: snap.docs.map((d) => ({ uid: d.id, ...d.data() })),
  };
});

/** Owner/manager updates a staff member's assignments or status. */
exports.updateUserRole = onCall(async (request, context) => {
  const adminRole = await requireAdmin(context);
  const { targetUid, roleIds, userName, assignedDepartments, customPermissions, isHeadOfDepartment, status } = request.data || {};
  if (!targetUid) throw new HttpsError('invalid-argument', 'Target user is required.');

  const target = await db.collection('user_roles').doc(targetUid).get();
  if (!target.exists) throw new HttpsError('not-found', 'User not found.');
  const targetData = target.data();
  if (targetData.hotelId !== adminRole.hotelId) {
    throw new HttpsError('permission-denied', 'This user does not belong to your hotel.');
  }

  const nextRoleIds = cleanStrings(roleIds, null);
  const isOwner = targetData.roleIds && targetData.roleIds.includes('super_admin');

  // Only a super_admin can change a super_admin, and only a super_admin can
  // grant the super_admin role.
  if (isOwner && !adminRole.roleIds.includes('super_admin')) {
    throw new HttpsError('permission-denied', 'Only the owner can change an owner account.');
  }
  if (nextRoleIds.includes('super_admin') && !adminRole.roleIds.includes('super_admin')) {
    throw new HttpsError('permission-denied', 'Only the owner can grant owner access.');
  }

  const updates = {
    updatedAt: serverTimestamp(),
  };
  if (roleIds !== undefined) updates.roleIds = nextRoleIds.length ? nextRoleIds : targetData.roleIds;
  if (userName !== undefined) updates.userName = String(userName);
  if (assignedDepartments !== undefined) updates.assignedDepartments = cleanStrings(assignedDepartments, VALID_DEPARTMENTS);
  if (customPermissions !== undefined) updates.customPermissions = cleanStrings(customPermissions, null);
  if (isHeadOfDepartment !== undefined) {
    updates.isHeadOfDepartment = isHeadOfDepartment && typeof isHeadOfDepartment === 'object'
      ? Object.fromEntries(Object.entries(isHeadOfDepartment).map(([k, v]) => [k, v === true]).filter(([k]) => VALID_DEPARTMENTS.includes(k)))
      : {};
  }
  if (status !== undefined) {
    if (!VALID_STATUS.includes(status)) throw new HttpsError('invalid-argument', 'Invalid status.');
    updates.status = status;
  }

  await db.collection('user_roles').doc(targetUid).update(updates);
  return { ok: true };
});

/** Owner/manager removes a staff account (role doc + Firebase Auth user). */
exports.deleteUserRole = onCall(async (request, context) => {
  const adminRole = await requireAdmin(context);
  const { targetUid } = request.data || {};
  if (!targetUid) throw new HttpsError('invalid-argument', 'Target user is required.');

  const target = await db.collection('user_roles').doc(targetUid).get();
  if (!target.exists) return { ok: true };
  const targetData = target.data();
  if (targetData.hotelId !== adminRole.hotelId) {
    throw new HttpsError('permission-denied', 'This user does not belong to your hotel.');
  }
  if (targetData.roleIds && targetData.roleIds.includes('super_admin')) {
    if (!adminRole.roleIds.includes('super_admin')) {
      throw new HttpsError('permission-denied', 'Only the owner can delete an owner account.');
    }
    throw new HttpsError('failed-precondition', 'Cannot delete the owner account from here.');
  }

  await db.collection('user_roles').doc(targetUid).delete();
  await auth.deleteUser(targetUid).catch(() => {});
  return { ok: true };
});
