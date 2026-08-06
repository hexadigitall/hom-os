import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { updateSelfProfile } from '@/lib/server/hom-service';

/**
 * Self-service profile endpoint. Any signed-in user may update their own
 * display name, phone, avatar URL and app preferences. Static route wins
 * over the dynamic `/api/users/[uid]` admin route.
 */
export async function PATCH(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const data = await req.json().catch(() => ({}));
    return json(await updateSelfProfile(token.uid, data));
  });
}
