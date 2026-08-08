import { NextRequest, NextResponse } from 'next/server';
import { ApiError, json, requireAuth, run } from '@/lib/server/api';
import { adminDb } from '@/lib/server/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const ADMIN_ROLES = ['super_admin', 'hotel_manager'];
const AUTO_SEND_KEYS = [
  'bookingConfirm', 'guestWelcome', 'checkoutReminder', 'payslip', 'purchaseOrder',
] as const;

/**
 * Per-hotel WABA settings.
 *
 *   GET  → public, non-secret config for the caller's hotel (phoneId, wabaId,
 *          displayName, verified, templateApprovals, autoSend toggles). The
 *          access TOKEN is NEVER returned.
 *   POST → management-only (super_admin / hotel_manager). Writes the public
 *          config to `hotels/{hotelId}/settings/whatsapp` and the secret token
 *          to the top-level `whatsapp_credentials/{hotelId}` doc, which
 *          firestore.rules denies to every client. `{ token: '' }` clears the
 *          stored credential.
 */
export async function GET(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const role = await callerRole(token.uid);
    const hotelId: string = role.hotelId;
    const snap = await adminDb()
      .doc(`hotels/${hotelId}/settings/whatsapp`)
      .get();
    const data = snap.exists ? snap.data()! : {};
    return json({
      phoneId: data.phoneId ?? '',
      wabaId: data.wabaId ?? '',
      displayName: data.displayName ?? '',
      verified: data.verified === true,
      templateApprovals: Array.isArray(data.templateApprovals)
        ? data.templateApprovals
        : [],
      autoSend: defaultAutoSend(data.autoSend),
    });
  });
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const role = await callerRole(token.uid);
    if (!ADMIN_ROLES.some((r) => role.roleIds?.includes(r))) {
      throw new ApiError('Admin access required.', 403);
    }
    const hotelId: string = role.hotelId;
    const body = await req.json().catch(() => ({}));

    const phoneId = clean(body.phoneId);
    const wabaId = clean(body.wabaId);
    const displayName = clean(body.displayName);
    const verified = body.verified === true;
    const templateApprovals = Array.isArray(body.templateApprovals)
      ? body.templateApprovals.filter((x: unknown) => typeof x === 'string')
      : [];
    const autoSend = defaultAutoSend(body.autoSend);

    const publicConfig = {
      phoneId,
      wabaId,
      displayName,
      verified,
      templateApprovals,
      autoSend,
      updatedAt: FieldValue.serverTimestamp(),
    };

    const db = adminDb();
    await db.doc(`hotels/${hotelId}/settings/whatsapp`).set(publicConfig);

    const tokenRaw = typeof body.token === 'string' ? body.token.trim() : '';
    if (tokenRaw) {
      await db.doc(`whatsapp_credentials/${hotelId}`).set({
        token: tokenRaw,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (body.token === '') {
      await db.doc(`whatsapp_credentials/${hotelId}`).delete().catch(() => {});
    }

    return json({ ok: true });
  });
}

async function callerRole(uid: string): Promise<Record<string, any>> {
  const snap = await adminDb().collection('user_roles').doc(uid).get();
  if (!snap.exists) throw new ApiError('Account not provisioned.', 403);
  const role = snap.data()!;
  if (role.status !== 'active') throw new ApiError('Account is not active.', 403);
  if (!role.hotelId) throw new ApiError('No hotel session.', 403);
  return role;
}

function clean(v: unknown): string {
  return typeof v === 'string' ? v.trim().slice(0, 200) : '';
}

function defaultAutoSend(raw: unknown): Record<string, boolean> {
  const out: Record<string, boolean> = {
    bookingConfirm: true,
    guestWelcome: false,
    checkoutReminder: true,
    payslip: false,
    purchaseOrder: false,
  };
  if (raw && typeof raw === 'object') {
    for (const k of AUTO_SEND_KEYS) {
      if (typeof (raw as Record<string, unknown>)[k] === 'boolean') {
        out[k] = (raw as Record<string, boolean>)[k];
      }
    }
  }
  return out;
}
