import { NextRequest, NextResponse } from 'next/server';
import { json, run } from '@/lib/server/api';
import { signupOwner } from '@/lib/server/hom-service';

export async function POST(req: NextRequest): Promise<NextResponse> {
  return run(async () => {
    const data = await req.json().catch(() => ({}));
    return json(await signupOwner(data));
  });
}
