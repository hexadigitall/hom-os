import Link from 'next/link'

const FEATURES = [
  { title: 'Fuel Tracking', desc: '5 fuel types with theft detection, cost breakdown, generator fault alerts.', href: '/features/fuel-tracking' },
  { title: 'WhatsApp Integration', desc: 'Real wa.me payslips, booking confirmations, PO notifications. No fake snackbars.', href: '/features/whatsapp' },
  { title: 'Bank Reconciliation', desc: 'CSV parser for Nigerian banks, auto-matching engine, split payments.', href: '/features/reconciliation' },
  { title: 'Operations Dashboards', desc: 'RevPAR, ADR, Occupancy, Night Audit, Housekeeping Loss with 30-day charts.' },
  { title: 'Compliance Automation', desc: 'SCUML, Tax, NAPTIP, LGA Health & Safety with deadline countdowns.' },
  { title: 'Expenditure Control', desc: '9 categories, approval flow, role-based access for departments.' },
]

const STATS = [
  { value: '19', label: 'Departments & modules' },
  { value: '5', label: 'Fuel types tracked' },
  { value: '6', label: 'Platforms: Android, Windows, Linux, macOS, Web' },
  { value: '100%', label: 'Offline-first — works without internet' },
]

const STEPS = [
  { icon: '📲', title: 'Install on any device', desc: 'APK on Android, MSIX on Windows, DEB on Linux, or just open the web app. Your data stays on the property.' },
  { icon: '👤', title: 'Set up roles & staff', desc: 'First boot registers the owner, then invite your team with role-based access. Departments scope what each person can see and do.' },
  { icon: '🏨', title: 'Run the whole property', desc: 'Bookings, diesel, expenditure, compliance, payroll, vendors and reconciliation — every department on one OS.' },
]

const DEPARTMENTS = [
  'Reception & Front Desk', 'Accounts', 'Engineering', 'Housekeeping',
  'Food & Beverage', 'Security', 'Back Office', 'Compliance',
]

const WHY = [
  { title: 'Diesel theft detection', desc: 'Tracks generator usage against fuel bought across five fuel types and flags when diesel goes missing.' },
  { title: 'Built for Nigerian compliance', desc: 'SCUML, NAPTIP, tax and LGA health & safety automation with deadline countdowns built in.' },
  { title: 'In-place, automatic updates', desc: 'Every release bumps the version automatically — updates install over your current app without uninstalling.' },
  { title: 'Naira-native billing', desc: 'Pricing in naira, Paystack-powered subscriptions, and bank reconciliation tuned for Nigerian statements.' },
]

const FAQ = [
  { q: 'Does HOM work without internet?', a: 'Yes. HOM is offline-first — all property data lives on the device and syncs when a connection is available.' },
  { q: 'Which devices does it run on?', a: 'Android phones and tablets, Windows, Linux, macOS, and the web. One account, the whole property.' },
  { q: 'How do updates work?', a: 'HOM checks for a new version on launch and prompts you. Installing a newer build upgrades in place — your data is never touched.' },
]

export default function HomePage() {
  return (
    <div>
      {/* HERO */}
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

      {/* STATS */}
      <section className="border-t border-white/5">
        <div className="max-w-6xl mx-auto px-6 py-12 grid grid-cols-2 md:grid-cols-4 gap-8">
          {STATS.map((s) => (
            <div key={s.label}>
              <p className="text-3xl md:text-4xl font-black text-hom-primary">{s.value}</p>
              <p className="text-xs text-white/40 mt-1 leading-snug">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* FEATURES */}
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
        <div className="text-center mt-10">
          <Link href="/features" className="inline-flex items-center gap-2 text-hom-primary font-semibold text-sm hover:underline">
            See every module →
          </Link>
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section className="max-w-6xl mx-auto px-6 py-16 border-t border-white/5">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black tracking-tight mb-3">Running in three steps</h2>
          <p className="text-white/50 max-w-2xl mx-auto">No consultants, no server rooms, no credit card to start.</p>
        </div>
        <div className="grid md:grid-cols-3 gap-6">
          {STEPS.map((s, i) => (
            <div key={s.title} className="rounded-2xl bg-hom-panel border border-white/5 p-6">
              <div className="text-3xl mb-4">{s.icon}</div>
              <p className="text-[11px] font-black text-hom-primary mb-2">STEP {i + 1}</p>
              <h3 className="font-bold mb-2">{s.title}</h3>
              <p className="text-sm text-white/50 leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* DEPARTMENTS */}
      <section className="max-w-6xl mx-auto px-6 py-16 border-t border-white/5">
        <div className="grid lg:grid-cols-2 gap-10 items-center">
          <div>
            <h2 className="text-3xl md:text-4xl font-black tracking-tight mb-4">Every department. One OS.</h2>
            <p className="text-white/50 mb-6 leading-relaxed">
              HOM isn't a booking app or a spreadsheet — it's the shared operating system for the entire property. Each department gets its own view, and zero-trust, role-based access keeps everyone in their lane.
            </p>
            <ul className="grid grid-cols-2 gap-2">
              {DEPARTMENTS.map((d) => (
                <li key={d} className="flex items-center gap-2 text-sm text-white/60">
                  <span className="text-hom-primary">✓</span> {d}
                </li>
              ))}
            </ul>
          </div>
          <div className="grid sm:grid-cols-2 gap-4">
            {WHY.map((w) => (
              <div key={w.title} className="rounded-2xl bg-hom-panel border border-white/5 p-5">
                <h3 className="font-bold text-sm mb-1 text-hom-primary">{w.title}</h3>
                <p className="text-xs text-white/50 leading-relaxed">{w.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="max-w-3xl mx-auto px-6 py-16 border-t border-white/5">
        <h2 className="text-3xl font-black tracking-tight text-center mb-10">Common questions</h2>
        <div className="space-y-4">
          {FAQ.map((f) => (
            <div key={f.q} className="rounded-2xl bg-hom-panel border border-white/5 p-6">
              <h3 className="font-bold mb-2">{f.q}</h3>
              <p className="text-sm text-white/50 leading-relaxed">{f.a}</p>
            </div>
          ))}
        </div>
        <p className="text-center mt-8 text-sm text-white/40">
          Something else? <Link href="/contact" className="text-hom-primary font-semibold hover:underline">Ask the team</Link>
        </p>
      </section>

      {/* CTA */}
      <section className="max-w-6xl mx-auto px-6 py-16 border-t border-white/5 text-center">
        <h2 className="text-3xl md:text-4xl font-black tracking-tight mb-4">From ₦15,000/month</h2>
        <p className="text-white/50 mb-8 max-w-xl mx-auto">Start with the basics, grow with the hotel. No credit card required to try.</p>
        <div className="flex flex-wrap justify-center gap-3">
          <Link href="/pricing" className="inline-block px-8 py-3 rounded-xl bg-hom-primary text-black font-bold">See Pricing</Link>
          <Link href="/download" className="inline-block px-8 py-3 rounded-xl bg-white/5 border border-white/10 hover:border-hom-primary/40 transition-colors">Download HOM</Link>
        </div>
      </section>
    </div>
  )
}
