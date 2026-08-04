import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { listUsers } from '@/lib/server/hom-service';

export async function GET(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    return json(await listUsers(token.uid));
  });
}
