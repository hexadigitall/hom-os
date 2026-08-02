import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const host = request.headers.get('host') || ''
  const url = request.nextUrl.clone()

  // app.hom.com.ng -> serve Flutter Web from public/flutter-web
  if (host.includes('app.hom.com.ng')) {
    if (url.pathname === '/' || url.pathname === '') {
      url.pathname = '/flutter-web/index.html'
      return NextResponse.rewrite(url)
    }
    if (!url.pathname.startsWith('/flutter-web')) {
      url.pathname = `/flutter-web${url.pathname}`
      return NextResponse.rewrite(url)
    }
  }

  // www.hom.com.ng -> redirect to apex
  if (host === 'www.hom.com.ng') {
    url.host = 'hom.com.ng'
    url.protocol = 'https'
    return NextResponse.redirect(url, 301)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
