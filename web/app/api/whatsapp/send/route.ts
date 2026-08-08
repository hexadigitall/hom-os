import { NextRequest, NextResponse } from 'next/server';
import { ApiError, json, requireAuth, run } from '@/lib/server/api';
import { adminDb } from '@/lib/server/firebase-admin';
import { PREBUILT_ROLES, type Permission } from '@/lib/rbac';

const GRAPH_BASE = 'https://graph.facebook.com/v20.0';

/**
 * Centralized WhatsApp Cloud API sender.
 *
 * The WABA token NEVER ships client-side. It lives in the top-level
 * `whatsapp_credentials/{hotelId}` doc (denied to every client by
 * firestore.rules) and is read here via the Admin SDK. The caller's own
 * hotelId comes from their server-authoritative `user_roles/{uid}` doc, so a
 * client can never send through another hotel's number.
 *
 * Returns `{ ok: false, mocked: true }` when the hotel has not configured
 * WABA yet — the caller then falls back to the wa.me deep link.
 */
export async function POST(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const uid = token.uid;
    const { to, message } = await req.json().catch(() => ({}));
    if (!to || !message) throw new ApiError('Recipient and message are required.');

    const roleSnap = await adminDb().collection('user_roles').doc(uid).get();
    if (!roleSnap.exists) throw new ApiError('Account not provisioned.', 403);
    const role = roleSnap.data()!;
    if (role.status !== 'active') throw new ApiError('Account is not active.', 403);
    const hotelId: string = role.hotelId;
    if (!hotelId) throw new ApiError('No hotel session.', 403);

    // Server-authoritative permission gate (mirrors client `hasPermission`).
    const canSend =
      Array.isArray(role.customPermissions) &&
      role.customPermissions.includes('sendAutomatedWhatsApp');
    const viaRoles = Array.isArray(role.roleIds)
      ? role.roleIds.some((rid: string) =>
          PREBUILT_ROLES.find((r) => r.id === rid)?.permissions.includes(
            'sendAutomatedWhatsApp' as Permission,
          ),
        )
      : false;
    if (!canSend && !viaRoles) {
      throw new ApiError('Permission required: sendAutomatedWhatsApp.', 403);
    }

    const [settingsSnap, credsSnap] = await Promise.all([
      adminDb().doc(`hotels/${hotelId}/settings/whatsapp`).get(),
      adminDb().doc(`whatsapp_credentials/${hotelId}`).get(),
    ]);
    const phoneId = settingsSnap.exists
      ? settingsSnap.data()!.phoneId
      : undefined;
    const waToken = credsSnap.exists ? credsSnap.data()!.token : undefined;

    if (!phoneId || !waToken) {
      return json({ ok: false, mocked: true, reason: 'WABA not configured.' });
    }

    const res = await fetch(`${GRAPH_BASE}/${phoneId}/messages`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${waToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to,
        type: 'text',
        text: { body: message },
      }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const err =
        (data as any)?.error?.message || `WhatsApp API error ${res.status}`;
      throw new ApiError(String(err), 502);
    }
    return json({ ok: true, waId: (data as any)?.messages?.[0]?.id ?? null });
  });
}
