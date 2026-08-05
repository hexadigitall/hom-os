import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { redeemInvite } from '@/lib/server/hom-service';

export async function POST(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const data = await req.json().catch(() => ({}));
    const name =
      typeof data?.name === 'string' && data.name.trim()
        ? data.name.trim()
        : token.name ?? '';
    return json(await redeemInvite(token.uid, token.email ?? '', { ...data, name }));
  });
}
