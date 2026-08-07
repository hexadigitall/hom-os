import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

const TTL_MS = 10 * 60 * 1000
let cache: { data: unknown; at: number } | null = null

export async function GET() {
  if (cache && Date.now() - cache.at < TTL_MS) {
    return NextResponse.json(cache.data)
  }
  try {
    const res = await fetch('https://api.github.com/repos/hexadigitall/hom-os/releases/latest', {
      headers: {
        Accept: 'application/vnd.github.v3+json',
        'User-Agent': 'hom.com.ng',
      },
      cache: 'no-store',
    })
    if (!res.ok) {
      return NextResponse.json({ error: 'No releases yet' }, { status: 404 })
    }
    const data = await res.json()
    cache = { data, at: Date.now() }
    return NextResponse.json(data)
  } catch (e) {
    return NextResponse.json({ error: 'Failed to fetch' }, { status: 500 })
  }
}
