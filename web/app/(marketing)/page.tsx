import Link from 'next/link'

const FEATURES = [
  { title: 'Fuel Tracking', desc: '5 fuel types with theft detection, cost breakdown, generator fault alerts.', href: '/features/fuel-tracking' },
  { title: 'WhatsApp Integration', desc: 'Real wa.me payslips, booking confirmations, PO notifications. No fake snackbars.', href: '/features/whatsapp' },
  { title: 'Bank Reconciliation', desc: 'CSV parser for Nigerian banks, auto-matching engine, split payments.', href: '/features/reconciliation' },
  { title: 'Operations Dashboards', desc: 'RevPAR, ADR, Occupancy, Night Audit, Housekeeping Loss with 30-day charts.' },
  { title: 'Compliance Automation', desc: 'SCUML, Tax, NAPTIP, LGA Health & Safety with deadline countdowns.' },
  { title: 'Expenditure Control', desc: '9 categories, approval flow, role-based access for departments.' },
]

export default function HomePage() {
  return (
    <div>
      <section className="max-w-6xl mx-auto px-6 py-20 md:py-28">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <div className="inline-flex gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
              Built by Hexadigitall • Live at hom.com.ng
            </div>
            <h1 className="text-5xl md:text-6xl font-black tracking-tight leading-[1.05] mb-6">
              The Hotel Operating System <span className="text-hom-primary">Powering Nigeria</span>
            </h1>
            <p className="text-lg text-white/60 mb-8 leading-relaxed">
              One app for bookings, diesel tracking (5 fuel types), expenditure management, compliance automation, staff payroll, vendors, WhatsApp integration and bank reconciliation. Built offline-first for Nigerian hotels.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link href="/download" className="px-6 py-3 rounded-xl bg-hom-primary text-black font-bold">Download HOM</Link>
              <Link href="https://app.hom.com.ng" className="px-6 py-3 rounded-xl bg-white/5 border border-white/10 hover:border-hom-primary/40 transition-colors">Open Web App</Link>
            </div>
            <div className="flex flex-wrap items-center gap-x-6 gap-y-2 mt-8 text-xs text-white/30">
              <span>✓ Android • Windows • Linux • macOS • Web</span>
              <span>✓ Offline-first</span>
              <span>✓ WhatsApp Integration</span>
            </div>
          </div>
          <div className="rounded-3xl bg-hom-panel border border-white/5 p-2 shadow-2xl">
            <div className="rounded-2xl bg-black overflow-hidden">
              <video
                src="/brand/HOM_FINAL_Ad1_Overview_with_Captions.mp4"
                controls autoPlay muted loop playsInline
                poster="/brand/logo-emerald-bg.png"
                className="w-full aspect-[16/10] object-cover"
              />
            </div>
          </div>
        </div>
      </section>

      <section className="max-w-6xl mx-auto px-6 py-16 border-t border-white/5">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black tracking-tight mb-3">Everything your hotel runs on</h2>
          <p className="text-white/50 max-w-2xl mx-auto">From reception to the engine room — one offline-first OS for the whole property.</p>
        </div>
        <div className="grid md:grid-cols-3 gap-6">
          {FEATURES.map((f) => (
            <Link key={f.title} href={f.href || '/features'} className="rounded-2xl bg-hom-panel border border-white/5 p-6 hover:border-hom-primary/40 transition-all group">
              <h3 className="font-bold mb-2 group-hover:text-hom-primary">{f.title}</h3>
              <p className="text-sm text-white/50">{f.desc}</p>
            </Link>
          ))}
        </div>
      </section>

      <section className="max-w-6xl mx-auto px-6 py-16 border-t border-white/5 text-center">
        <h2 className="text-3xl md:text-4xl font-black tracking-tight mb-4">From ₦15,000/month</h2>
        <p className="text-white/50 mb-8 max-w-xl mx-auto">Start with the basics, grow with the hotel. No credit card required to try.</p>
        <Link href="/pricing" className="inline-block px-8 py-3 rounded-xl bg-hom-primary text-black font-bold">See Pricing</Link>
      </section>
    </div>
  )
}
