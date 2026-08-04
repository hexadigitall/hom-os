import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { createInvite, listInvites } from '@/lib/server/hom-service';

export async function GET(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    return json(await listInvites(token.uid));
  });
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const data = await req.json().catch(() => ({}));
    return json(await createInvite(token.uid, data));
  });
}
