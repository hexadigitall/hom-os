import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { provisionOwner } from '@/lib/server/hom-service';

export async function POST(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const data = await req.json().catch(() => ({}));
    return json(await provisionOwner(token.uid, token.email ?? '', data));
  });
}
