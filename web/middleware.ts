import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const host = request.headers.get('host') || ''
  const url = request.nextUrl.clone()

  // app.hom.com.ng -> serve Flutter Web from public/flutter-web
  if (host.includes('app.hom.com.ng')) {
    if (url.pathname === '/' || url.pathname === '') {
      url.pathname = '/flutter-web/index.html'
    } else if (!url.pathname.startsWith('/flutter-web')) {
      url.pathname = `/flutter-web${url.pathname}`
    }
    const res = NextResponse.rewrite(url)
    // Hashed / SDK-versioned Flutter assets are safe to cache immutably.
    if (url.pathname.includes('/canvaskit/')) {
      res.headers.set('Cache-Control', 'public, max-age=31536000, immutable')
    } else {
      // index.html, main.dart.js, service worker, assets etc. change every
      // release but keep the same URL -> revalidate so updates are never stale.
      res.headers.set('Cache-Control', 'public, max-age=0, must-revalidate')
    }
    return res
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
