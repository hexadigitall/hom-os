import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { deleteInvite } from '@/lib/server/hom-service';

export async function DELETE(
  req: NextRequest,
  { params }: { params: { code: string } },
): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    return json(await deleteInvite(token.uid, { code: params.code }));
  });
}
