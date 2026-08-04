import { NextResponse } from 'next/server';
import type { DecodedIdToken } from 'firebase-admin/auth';
import { adminAuth } from './firebase-admin';

/** Error with an HTTP status; surfaces a clean `{ error: { message } }` body. */
export class ApiError extends Error {
  status: number;
  constructor(message: string, status = 400) {
    super(message);
    this.status = status;
  }
}

/** Verify the `Authorization: Bearer <idToken>` and return the decoded token. */
export async function requireAuth(req: Request): Promise<DecodedIdToken> {
  const header = req.headers.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice('Bearer '.length) : '';
  if (!token) throw new ApiError('Sign in required.', 401);
  try {
    return await adminAuth().verifyIdToken(token);
  } catch {
    throw new ApiError('Invalid or expired session.', 401);
  }
}

export function json(body: unknown, status = 200): NextResponse {
  return NextResponse.json(body, { status });
}

/** Wrap a route handler: ApiError → status body, anything else → 500. */
export async function run(handler: () => Promise<NextResponse>): Promise<NextResponse> {
  try {
    return await handler();
  } catch (err) {
    if (err instanceof ApiError) {
      return NextResponse.json({ error: { message: err.message } }, { status: err.status });
    }
    console.error(err);
    return NextResponse.json({ error: { message: 'Server error.' } }, { status: 500 });
  }
}
