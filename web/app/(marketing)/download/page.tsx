"use client"
import { useEffect, useState } from 'react'

type Asset = { name: string; browser_download_url: string; size: number }
type Release = { tag_name: string; published_at: string; assets: Asset[] }

type Card = {
  key: string
  title: string
  desc: string
  icon: string
  os: string[]
  match: (assets: Asset[]) => Asset | undefined
  fallback?: string
  qr?: string
  badge?: string
}

const CARDS: Card[] = [
  {
    key: 'apk',
    title: 'Android APK',
    desc: 'Single-file installer for phones and tablets. The easiest way to get HOM.',
    icon: '🤖',
    os: ['android'],
    match: (a) => a.find((x) => x.name === 'HOM-APK.apk' || /^HOM-APK/i.test(x.name)),
    badge: 'Recommended',
  },
  {
    key: 'aab',
    title: 'Android AAB',
    desc: 'App bundle for Play Store publishing. Use with bundletool.',
    icon: '📦',
    os: ['android'],
    match: (a) => a.find((x) => x.name === 'HOM-AAB.aab' || /^HOM-AAB/i.test(x.name)),
  },
  {
    key: 'split',
    title: 'Split APKs',
    desc: 'Split package set for sideloading and large-device installs.',
    icon: '🧩',
    os: ['android'],
    match: (a) => a.find((x) => x.name === 'HOM-Split-APKs.zip' || /^HOM-Split/i.test(x.name)),
  },
  {
    key: 'windows',
    title: 'Windows',
    desc: 'Portable EXE — extract and run. No installer needed.',
    icon: '🪟',
    os: ['windows'],
    match: (a) => a.find((x) => /^HOM-Windows/i.test(x.name) && /\.exe$/i.test(x.name)) || a.find((x) => /^HOM-Windows/i.test(x.name)),
    badge: 'Recommended',
  },
  {
    key: 'msix',
    title: 'Windows MSIX',
    desc: 'Signed MSIX bundle with certificate for Store-style deployment.',
    icon: '🧾',
    os: ['windows'],
    match: (a) => a.find((x) => x.name === 'HOM-Msix-Cert.zip' || /^HOM-Msix/i.test(x.name)),
  },
  {
    key: 'linux',
    title: 'Linux',
    desc: 'Portable Linux build. Runs on most distros.',
    icon: '🐧',
    os: ['linux'],
    match: (a) => a.find((x) => /^HOM-Linux/i.test(x.name) && !/deb/i.test(x.name)),
    badge: 'Recommended',
  },
  {
    key: 'deb',
    title: 'Linux DEB',
    desc: 'Debian/Ubuntu package for apt-based systems.',
    icon: '🐧',
    os: ['linux'],
    match: (a) => a.find((x) => x.name === 'HOM-Deb.deb' || /\.deb$/i.test(x.name)),
  },
  {
    key: 'macos',
    title: 'macOS',
    desc: 'Mac build for Apple silicon and Intel.',
    icon: '🍎',
    os: ['macos'],
    match: (a) => a.find((x) => /^HOM-macOS/i.test(x.name)),
    badge: 'Recommended',
  },
  {
    key: 'web',
    title: 'Web App',
    desc: 'Run HOM in the browser — app.hom.com.ng. Works on any device.',
    icon: '🌐',
    os: ['web', 'ios'],
    match: () => undefined,
    qr: 'https://app.hom.com.ng',
    badge: 'No install',
  },
  {
    key: 'ios',
    title: 'iOS',
    desc: 'Coming soon. Meanwhile, use the Web App on iPhone and iPad.',
    icon: '📱',
    os: ['ios'],
    match: () => undefined,
    badge: 'Coming soon',
  },
]

const WEB_URL = 'https://app.hom.com.ng'

function detectOS(): string {
  if (typeof navigator === 'undefined') return 'web'
  const ua = navigator.userAgent
  if (/android/i.test(ua)) return 'android'
  if (/iPad|iPhone|iPod/.test(ua)) return 'ios'
  if (/Macintosh|Mac OS X/.test(ua)) return 'macos'
  if (/Windows/i.test(ua)) return 'windows'
  if (/Linux/i.test(ua)) return 'linux'
  return 'web'
}

function formatBytes(n: number): string {
  if (!n) return ''
  const mb = n / 1024 / 1024
  if (mb > 1024) return `${(mb / 1024).toFixed(1)} GB`
  if (mb > 1) return `${Math.round(mb)} MB`
  return `${Math.round(n / 1024)} KB`
}

export default function DownloadPage() {
  const [release, setRelease] = useState<Release | null>(null)
  const [status, setStatus] = useState<'loading' | 'ok' | 'error'>('loading')
  const [os, setOs] = useState('web')

  useEffect(() => {
    setOs(detectOS())
    fetch('/api/latest-release')
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(String(r.status)))))
      .then((d) => { setRelease(d); setStatus('ok') })
      .catch(() => setStatus('error'))
  }, [])

  const releaseUrl = 'https://github.com/hexadigitall/hom-os/releases/latest'
  const releaseLink = release?.tag_name ? `https://github.com/hexadigitall/hom-os/releases/tag/${encodeURIComponent(release.tag_name)}` : releaseUrl

  return (
    <div className="max-w-6xl mx-auto px-6 py-16">
      <div className="text-center mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
          DOWNLOAD
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Get HOM on your device</h1>
        <p className="text-white/50 max-w-2xl mx-auto">
          {status === 'loading' && 'Fetching the latest release from GitHub…'}
          {status === 'ok' && release && (
            <>Latest release <span className="text-hom-primary font-semibold">{release.tag_name}</span> — published {new Date(release.published_at).toLocaleDateString()}</>
          )}
          {status === 'error' && (
            <>No artifacts published yet — check <a className="text-hom-primary underline" href={releaseUrl} target="_blank" rel="noreferrer">GitHub Releases</a>.</>
          )}
        </p>
      </div>

      <div className="flex flex-wrap justify-center gap-2 mb-10 text-xs">
        {(['android', 'windows', 'linux', 'macos', 'web'] as const).map((o) => (
          <button
            key={o}
            onClick={() => setOs(o)}
            className={`px-4 py-1.5 rounded-full border transition-colors ${os === o ? 'bg-hom-primary text-black border-hom-primary font-bold' : 'border-white/10 text-white/40 hover:border-hom-primary/40'}`}
          >
            {o[0].toUpperCase() + o.slice(1)}
          </button>
        ))}
      </div>

      {status === 'loading' && <div className="text-center text-white/30 py-16">Checking for the latest build…</div>}

      {status === 'ok' && (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {CARDS.map((c) => {
            const asset = c.match(release?.assets ?? [])
            const recommended = c.os.includes(os)
            const disabled = !asset && !c.qr
            return (
              <div
                key={c.key}
                className={`rounded-3xl border p-6 flex flex-col transition-all ${recommended ? 'border-hom-primary/50 bg-hom-panel ring-1 ring-hom-primary/30' : 'border-white/5 bg-hom-panel'} ${disabled ? 'opacity-60' : ''}`}
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="text-3xl">{c.icon}</div>
                  {recommended && <span className="text-[10px] font-bold px-2 py-1 rounded-full bg-hom-primary/15 text-hom-primary">{os === 'ios' && c.key === 'web' ? 'Best on iOS' : `For ${c.os[0]}`}</span>}
                  {c.badge && !recommended && <span className="text-[10px] font-bold px-2 py-1 rounded-full bg-white/5 text-white/40">{c.badge}</span>}
                </div>
                <h3 className="font-bold mb-1">{c.title}</h3>
                <p className="text-xs text-white/40 mb-4 flex-1">{c.desc}</p>
                {c.qr && (
                  <img
                    src={`https://api.qrserver.com/v1/create-qr-code/?size=96x96&data=${encodeURIComponent(c.qr)}`}
                    alt={`QR code for ${c.title}`}
                    className="w-24 h-24 rounded-xl bg-white p-2 mb-4 mx-auto"
                  />
                )}
                {asset && (
                  <div className="text-xs text-white/30 mb-3 text-center">{asset.name} • {formatBytes(asset.size)}</div>
                )}
                <a
                  href={c.qr || asset?.browser_download_url || releaseLink}
                  target="_blank"
                  rel="noreferrer"
                  className={`mt-auto text-center py-2.5 rounded-xl font-bold text-sm transition-colors ${disabled ? 'pointer-events-none bg-white/5 text-white/30' : 'bg-hom-primary text-black hover:bg-hom-primary/90'}`}
                >
                  {c.qr ? 'Open Web App' : asset ? 'Download' : c.badge === 'Coming soon' ? 'Coming soon' : 'View Release'}
                </a>
              </div>
            )
          })}
        </div>
      )}

      {status === 'error' && (
        <div className="max-w-md mx-auto rounded-3xl bg-hom-panel border border-white/5 p-8 text-center">
          <div className="text-3xl mb-4">🕓</div>
          <p className="text-white/60 text-sm mb-6">
            No release has been published yet. When it drops, every platform installer will appear here automatically — or install the web app right now.
          </p>
          <div className="flex flex-col gap-3">
            <a href="https://app.hom.com.ng" className="py-3 rounded-xl bg-hom-primary text-black font-bold">Open HOM-Web</a>
            <a href={releaseUrl} target="_blank" rel="noreferrer" className="py-3 rounded-xl bg-white/5 border border-white/10 text-white/70 hover:border-hom-primary/40 transition-colors">
              Check GitHub Releases
            </a>
          </div>
        </div>
      )}

      <p className="text-center text-xs text-white/30 mt-12">
        Web app: <a className="text-hom-primary" href={WEB_URL} target="_blank" rel="noreferrer">{WEB_URL}</a> • Artifacts served from GitHub Releases
      </p>
    </div>
  )
}
