import { NextResponse } from 'next/server'

export async function GET() {
  try {
    const res = await fetch('https://api.github.com/repos/hexadigitall/hom-os/releases/latest', {
      headers: {
        Accept: 'application/vnd.github.v3+json',
        'User-Agent': 'hom.com.ng',
      },
      next: { revalidate: 3600 },
    })
    if (!res.ok) {
      return NextResponse.json({ error: 'No releases yet' }, { status: 404 })
    }
    const data = await res.json()
    return NextResponse.json(data)
  } catch (e) {
    return NextResponse.json({ error: 'Failed to fetch' }, { status: 500 })
  }
}
