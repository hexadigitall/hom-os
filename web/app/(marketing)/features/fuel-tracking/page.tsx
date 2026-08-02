import Link from 'next/link'

const BULLETS = [
  { title: '5 Fuel Types', desc: 'Generator, vehicles, cooking gas, fuel pump stock and transfers — each tracked separately.' },
  { title: 'Theft Detection', desc: 'Every fill logged against tank readings. Variances flag mismatches the moment they happen.' },
  { title: 'Generator Fault Alerts', desc: 'Engine run-hour anomalies surface before a breakdown costs the whole night.' },
  { title: 'Cost Breakdowns', desc: 'Per-litre pricing, per-usage cost and daily totals across every engine and vehicle.' },
  { title: 'Manual Logging', desc: 'No internet? Every fill is entered into the 5,000L log the moment it happens.' },
  { title: 'Approval Flow', desc: 'Fills require manager sign-off, keeping a clean, auditable trail end to end.' },
]

export default function FuelTrackingPage() {
  return (
    <div className="max-w-6xl mx-auto px-6 py-16">
      <nav className="text-xs text-white/30 mb-8">
        <Link href="/features" className="hover:text-hom-primary">Features</Link> <span className="mx-2">/</span> Fuel Tracking
      </nav>
      <div className="max-w-3xl mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
          ⛽ FUEL TRACKING
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Diesel theft is expensive. HOM catches it.</h1>
        <p className="text-white/50 text-lg leading-relaxed">
          Hotels burn thousands of naira on diesel every night. With HOM, every single litre is accounted for — from the bowser to the generator — with the same precision as the 5,000L log book, minus the paper.
        </p>
      </div>
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {BULLETS.map((b) => (
          <div key={b.title} className="rounded-2xl bg-hom-panel border border-white/5 p-6">
            <h3 className="font-bold mb-2 text-hom-primary">{b.title}</h3>
            <p className="text-sm text-white/50">{b.desc}</p>
          </div>
        ))}
      </div>
      <div className="mt-12 flex flex-wrap gap-3">
        <Link href="/download" className="px-6 py-3 rounded-xl bg-hom-primary text-black font-bold">Get HOM</Link>
        <Link href="/contact" className="px-6 py-3 rounded-xl bg-white/5 border border-white/10 hover:border-hom-primary/40 transition-colors">Talk to Sales</Link>
      </div>
    </div>
  )
}
