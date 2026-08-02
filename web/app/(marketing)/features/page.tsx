import Link from 'next/link'

const FEATURES = [
  { title: 'Fuel Tracking & Diesel Theft Detection', href: '/features/fuel-tracking', icon: '⛽', desc: 'Track 5 fuel types, detect theft, cost breakdowns, generator fault alerts.' },
  { title: 'WhatsApp Integration', href: '/features/whatsapp', icon: '💬', desc: 'Real wa.me payslips, booking confirmations, PO notifications via WhatsApp Cloud API.' },
  { title: 'Bank Reconciliation', href: '/features/reconciliation', icon: '🏦', desc: 'CSV parser for Nigerian banks, auto-matching engine, split payments.' },
  { title: 'Bookings & Room Management', icon: '🛎️', desc: 'Check-ins, occupancy and room status across the whole property.' },
  { title: 'Expenditure Control', icon: '🧾', desc: '9 categories, approval flow, role-based access for departments.' },
  { title: 'Compliance Automation', icon: '⚖️', desc: 'SCUML, Tax, NAPTIP, LGA Health & Safety with deadline countdowns.' },
  { title: 'Operations Dashboards', icon: '📊', desc: 'RevPAR, ADR, Occupancy, Night Audit with 30-day charts.' },
  { title: 'Payroll & HR', icon: '👥', desc: 'PAYE 7% pension 8%, digital payslips, staff scheduling.' },
  { title: 'Channels', icon: '🌐', desc: 'Paystack billing, Booking.com sync, WhatsApp Cloud API.' },
]

export default function FeaturesPage() {
  return (
    <div className="max-w-6xl mx-auto px-6 py-16">
      <div className="text-center mb-14">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
          FEATURES
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">One OS. Every department.</h1>
        <p className="text-white/50 max-w-2xl mx-auto">
          HOM runs the whole hotel — reception, front office, engineering, housekeeping, F&amp;B, security and accounts — with role-based access and zero trust.
        </p>
      </div>
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {FEATURES.map((f) => (
          <Link key={f.title} href={f.href || '/features'} className="rounded-2xl bg-hom-panel border border-white/5 p-6 hover:border-hom-primary/40 transition-all group">
            <div className="text-3xl mb-4">{f.icon}</div>
            <h3 className="font-bold mb-2 group-hover:text-hom-primary">{f.title}</h3>
            <p className="text-sm text-white/50">{f.desc}</p>
          </Link>
        ))}
      </div>
    </div>
  )
}
