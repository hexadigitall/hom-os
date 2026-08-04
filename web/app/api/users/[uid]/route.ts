import { NextRequest, NextResponse } from 'next/server';
import { json, requireAuth, run } from '@/lib/server/api';
import { deleteUserRole, updateUserRole } from '@/lib/server/hom-service';

export async function PATCH(
  req: NextRequest,
  { params }: { params: { uid: string } },
): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    const data = await req.json().catch(() => ({}));
    return json(await updateUserRole(token.uid, { ...data, targetUid: params.uid }));
  });
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: { uid: string } },
): Promise<NextResponse> {
  return run(async () => {
    const token = await requireAuth(req);
    return json(await deleteUserRole(token.uid, { targetUid: params.uid }));
  });
}
