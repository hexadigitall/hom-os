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

const MODULES = [
  'Overview & Night Audit', 'Bookings', 'Rooms', 'Fuel (5 types)',
  'Inventory', 'Staff & Payroll', 'Vendors & Purchase Orders',
  'Expenditure & Approvals', 'Reports & Analytics', 'Compliance',
  'Subscriptions & Billing', 'WhatsApp Messaging', 'Operations',
  'Bank Reconciliation', 'F&B / POS', 'Engineering',
  'Housekeeping', 'Back Office', 'Security & Audit',
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

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-16">
        {FEATURES.map((f) => (
          <Link key={f.title} href={f.href || '/features'} className="rounded-2xl bg-hom-panel border border-white/5 p-6 hover:border-hom-primary/40 transition-all group">
            <div className="text-3xl mb-4">{f.icon}</div>
            <h3 className="font-bold mb-2 group-hover:text-hom-primary">{f.title}</h3>
            <p className="text-sm text-white/50">{f.desc}</p>
          </Link>
        ))}
      </div>

      <section className="border-t border-white/5 pt-16">
        <h2 className="text-3xl font-black tracking-tight mb-4 text-center">19 modules, one login</h2>
        <p className="text-white/50 max-w-2xl mx-auto text-center mb-10">
          Every module is role-gated. A front-desk agent sees bookings; the manager sees the whole property; accounts sees the money. Suspension revokes access instantly.
        </p>
        <div className="flex flex-wrap justify-center gap-2 max-w-4xl mx-auto">
          {MODULES.map((m) => (
            <span key={m} className="px-4 py-2 rounded-full bg-hom-panel border border-white/5 text-xs text-white/60 hover:border-hom-primary/40 transition-colors">
              {m}
            </span>
          ))}
        </div>
      </section>

      <section className="border-t border-white/5 pt-16 text-center">
        <h2 className="text-2xl md:text-3xl font-black tracking-tight mb-4">Try it in the browser right now</h2>
        <p className="text-white/50 max-w-xl mx-auto mb-8">
          The web app is the fastest way to see HOM. Register your hotel and explore all 19 modules — no install, no payment.
        </p>
        <div className="flex flex-wrap justify-center gap-3">
          <Link href="https://app.hom.com.ng" className="px-6 py-3 rounded-xl bg-hom-primary text-black font-bold">Open HOM-Web</Link>
          <Link href="/download" className="px-6 py-3 rounded-xl bg-white/5 border border-white/10 hover:border-hom-primary/40 transition-colors">Download the app</Link>
        </div>
      </section>
    </div>
  )
}
