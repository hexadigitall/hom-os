import { NextRequest, NextResponse } from 'next/server';
import { ApiError, json, requireAuth, run } from '@/lib/server/api';
import { adminDb } from '@/lib/server/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const ADMIN_ROLES = ['super_admin', 'hotel_manager'];

/**
 * Hotel-scoped channel config (Paystack, Booking.com).
 *
 *   GET  → public, non-secret config for the caller's hotel. The Paystack
 *          PUBLIC key is safe to ship to the browser (it is public by design);
 *          Booking.com credentials are stored here too until the channel
 *          manager gets real server-side sync.
 *   POST → management-only (super_admin / hotel_manager). Writes to
 *          `hotels/{hotelId}/settings/channels`.
 */
export async function GET(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const role = await callerRole(token.uid);
    const hotelId: string = role.hotelId;
    const snap = await adminDb()
      .doc(`hotels/${hotelId}/settings/channels`)
      .get();
    const data = snap.exists ? snap.data()! : {};
    return json({
      paystack: {
        publicKey: data.paystack?.publicKey ?? '',
        businessName: data.paystack?.businessName ?? '',
      },
      bookingCom: {
        accountId: data.bookingCom?.accountId ?? '',
        email: data.bookingCom?.email ?? '',
        propertyId: data.bookingCom?.propertyId ?? '',
        syncExternal: data.bookingCom?.syncExternal === true,
      },
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
    const pay = body.paystack ?? {};
    const bc = body.bookingCom ?? {};

    await adminDb()
      .doc(`hotels/${hotelId}/settings/channels`)
      .set({
        paystack: {
          publicKey: clean(pay.publicKey),
          businessName: clean(pay.businessName),
        },
        bookingCom: {
          accountId: clean(bc.accountId),
          email: clean(bc.email),
          propertyId: clean(bc.propertyId),
          syncExternal: bc.syncExternal === true,
        },
        updatedAt: FieldValue.serverTimestamp(),
      });

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
