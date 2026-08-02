"use client"
import { useEffect } from 'react'
import Link from 'next/link'

export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const prev = document.body.style.backgroundColor
    document.body.style.backgroundColor = '#080C0A'
    return () => { document.body.style.backgroundColor = prev }
  }, [])

  return (
    <div className="min-h-screen bg-hom-night text-white flex flex-col">
      <header className="sticky top-0 z-50 bg-hom-night/80 backdrop-blur border-b border-white/5">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-hom-primary flex items-center justify-center font-black text-black">H</div>
            <span className="font-black tracking-tight">HOM</span>
            <span className="text-white/40 text-xs tracking-widest hidden sm:inline">HOSPITALITY</span>
          </Link>
          <nav className="hidden md:flex items-center gap-6 text-sm text-white/60">
            <Link href="/features" className="hover:text-white">Features</Link>
            <Link href="/pricing" className="hover:text-white">Pricing</Link>
            <Link href="/download" className="hover:text-white">Download</Link>
            <Link href="/about" className="hover:text-white">About</Link>
            <Link href="/contact" className="hover:text-white">Contact</Link>
            <Link href="https://github.com/hexadigitall/hom-os" className="hover:text-white">GitHub</Link>
          </nav>
          <Link href="/download" className="px-4 py-2 rounded-full bg-hom-primary text-black font-bold text-sm">Get HOM</Link>
        </div>
      </header>

      <main className="flex-1">{children}</main>

      <footer className="border-t border-white/5">
        <div className="max-w-6xl mx-auto px-6 py-12 grid grid-cols-2 md:grid-cols-4 gap-8 text-sm">
          <div className="col-span-2 md:col-span-1">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-lg bg-hom-primary flex items-center justify-center font-black text-black text-sm">H</div>
              <span className="font-black">HOM</span>
              <span className="text-white/40 text-xs tracking-widest">HOSPITALITY</span>
            </div>
            <p className="text-white/40 text-xs leading-relaxed">The Hotel Operating System Powering Nigeria. Offline-first hospitality operations management.</p>
          </div>
          <div>
            <p className="font-semibold text-white/80 mb-3 text-xs">Product</p>
            <ul className="space-y-2 text-white/40 text-xs">
              <li><Link href="/features" className="hover:text-hom-primary">Features</Link></li>
              <li><Link href="/features/fuel-tracking" className="hover:text-hom-primary">Fuel Tracking</Link></li>
              <li><Link href="/features/whatsapp" className="hover:text-hom-primary">WhatsApp</Link></li>
              <li><Link href="/features/reconciliation" className="hover:text-hom-primary">Reconciliation</Link></li>
              <li><Link href="/pricing" className="hover:text-hom-primary">Pricing</Link></li>
            </ul>
          </div>
          <div>
            <p className="font-semibold text-white/80 mb-3 text-xs">Download</p>
            <ul className="space-y-2 text-white/40 text-xs">
              <li><Link href="/download" className="hover:text-hom-primary">Download HOM</Link></li>
              <li><Link href="https://app.hom.com.ng" className="hover:text-hom-primary">Web App</Link></li>
              <li><Link href="https://github.com/hexadigitall/hom-os/releases" className="hover:text-hom-primary">GitHub Releases</Link></li>
            </ul>
          </div>
          <div>
            <p className="font-semibold text-white/80 mb-3 text-xs">Company</p>
            <ul className="space-y-2 text-white/40 text-xs">
              <li><Link href="/about" className="hover:text-hom-primary">About</Link></li>
              <li><Link href="/contact" className="hover:text-hom-primary">Contact</Link></li>
              <li><Link href="https://hexadigitall.com" className="hover:text-hom-primary">hexadigitall.com</Link></li>
              <li><Link href="https://github.com/hexadigitall" className="hover:text-hom-primary">github.com/hexadigitall</Link></li>
            </ul>
          </div>
        </div>
        <div className="border-t border-white/5 py-6 text-center text-xs text-white/30">© {new Date().getFullYear()} HOM Hospitality — hom.com.ng • Built by Hexadigitall</div>
      </footer>
    </div>
  )
}
