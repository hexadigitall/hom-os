import Link from 'next/link'

const BULLETS = [
  { title: 'CSV Parser for Nigerian Banks', desc: 'Export your statement from your bank portal, drop it in, HOM reads it. No bank APIs needed.' },
  { title: 'Auto-Matching Engine', desc: 'Every transaction is matched against bookings, expenses and customer payments automatically.' },
  { title: 'Split Payments', desc: 'Partial payments, transfers and cash come together into one clean ledger entry.' },
  { title: 'Discrepancy Flags', desc: 'Expected vs actual. Anything that does not match surfaces for review — no silent gaps.' },
  { title: 'Paystack Reconciliation', desc: 'Online payments pulled in and reconciled against the same ledger.' },
  { title: 'Clean Audit Trail', desc: 'SCUML-ready, tax-ready, bank-ready. Your accountant will love it.' },
]

export default function ReconciliationPage() {
  return (
    <div className="max-w-6xl mx-auto px-6 py-16">
      <nav className="text-xs text-white/30 mb-8">
        <Link href="/features" className="hover:text-hom-primary">Features</Link> <span className="mx-2">/</span> Reconciliation
      </nav>
      <div className="max-w-3xl mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
          🏦 BANK RECONCILIATION
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Your bank statement, matched to the penny</h1>
        <p className="text-white/50 text-lg leading-relaxed">
          No Nigerian bank API headaches. Export the CSV, HOM does the matching. Reconciliations that took your accounts team a full day now take minutes.
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
