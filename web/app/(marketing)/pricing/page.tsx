import Link from 'next/link'

const PLANS = [
  {
    name: 'Starter',
    price: '₦15,000',
    per: '/month',
    desc: 'For small hotels getting off paper.',
    features: [
      'Up to 10 rooms',
      'Bookings & room management',
      'Diesel tracking (5 fuel types)',
      'Expenditure & 9 categories',
      'Basic operations dashboards',
    ],
    cta: 'Start with Starter',
    featured: false,
  },
  {
    name: 'Growth',
    price: '₦35,000',
    per: '/month',
    desc: 'For hotels running every department on HOM.',
    features: [
      'Up to 30 rooms',
      'Everything in Starter',
      'Bank reconciliation (CSV parser)',
      'WhatsApp integration & wa.me payslips',
      'Payroll — PAYE 7%, pension 8%',
      'Paystack billing & Booking.com sync',
      'Compliance automation (SCUML, Tax, NAPTIP)',
    ],
    cta: 'Go Growth',
    featured: true,
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    per: '',
    desc: 'For groups and properties over 30 rooms.',
    features: [
      'Unlimited rooms & properties',
      'Everything in Growth',
      'Custom onboarding & data migration',
      'Multi-property rollups',
      'Dedicated support & training',
      'On-premise deployment option',
    ],
    cta: 'Talk to Sales',
    featured: false,
  },
]

const COMPARE: { feature: string; starter: string | boolean; growth: string | boolean; enterprise: string | boolean }[] = [
  { feature: 'Rooms', starter: 'Up to 10', growth: 'Up to 30', enterprise: 'Unlimited' },
  { feature: 'Bookings & rooms', starter: true, growth: true, enterprise: true },
  { feature: 'Diesel tracking (5 fuel types)', starter: true, growth: true, enterprise: true },
  { feature: 'Expenditure & approvals', starter: true, growth: true, enterprise: true },
  { feature: 'Operations dashboards', starter: 'Basic', growth: 'Full', enterprise: 'Full' },
  { feature: 'Bank reconciliation', starter: false, growth: true, enterprise: true },
  { feature: 'WhatsApp integration', starter: false, growth: true, enterprise: true },
  { feature: 'Payroll (PAYE 7% / pension 8%)', starter: false, growth: true, enterprise: true },
  { feature: 'Compliance automation (SCUML, NAPTIP, Tax)', starter: false, growth: true, enterprise: true },
  { feature: 'Paystack billing & Booking.com sync', starter: false, growth: true, enterprise: true },
  { feature: 'Multi-property rollups', starter: false, growth: false, enterprise: true },
  { feature: 'On-premise deployment', starter: false, growth: false, enterprise: true },
]

const FAQ = [
  { q: 'Do I need a credit card to start?', a: 'No. Start on Starter, run your hotel, and upgrade to Growth when you need reconciliation, payroll and compliance.' },
  { q: 'What happens if I switch plans?', a: 'Your data stays exactly where it is. Plan changes take effect immediately on your next billing cycle.' },
  { q: 'Is there a free trial?', a: 'Starter has no upfront cost — you only pay the monthly fee once you decide to keep HOM. The web app is free to explore at any time.' },
  { q: 'How do updates work?', a: 'HOM checks for new versions on launch and prompts you. Updates install over your current app in place — your data is never touched.' },
  { q: 'Do I pay per staff member?', a: 'No. Pricing is per property, not per user. Add your whole team with role-based access at no extra cost.' },
  { q: 'Can I self-host?', a: 'Enterprise plans can deploy HOM on-premise for properties that need data to stay fully inside the building.' },
]

function Cell({ v }: { v: string | boolean }) {
  if (v === true) return <span className="text-hom-primary font-bold">✓</span>
  if (v === false) return <span className="text-white/20">—</span>
  return <span className="text-white/70 text-sm">{v}</span>
}

export default function PricingPage() {
  return (
    <div className="max-w-6xl mx-auto px-6 py-16">
      <div className="text-center mb-14">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
          PRICING
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Pricing that pays for itself in one night of diesel</h1>
        <p className="text-white/50 max-w-2xl mx-auto">
          Simple monthly pricing in naira. No credit card to start. Cancel anytime.
        </p>
      </div>

      <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto mb-16">
        {PLANS.map((p) => (
          <div key={p.name} className={`rounded-3xl p-8 flex flex-col ${p.featured ? 'bg-hom-primary text-black shadow-2xl scale-105' : 'bg-hom-panel border border-white/5'}`}>
            <h2 className="text-lg font-bold mb-1">{p.name}</h2>
            <p className={`text-xs mb-6 ${p.featured ? 'text-black/60' : 'text-white/40'}`}>{p.desc}</p>
            <div className="mb-6">
              <span className="text-4xl font-black">{p.price}</span>
              {p.per && <span className={`text-sm ${p.featured ? 'text-black/60' : 'text-white/40'}`}> {p.per}</span>}
            </div>
            <ul className="space-y-2 mb-8 flex-1 text-sm">
              {p.features.map((f) => (
                <li key={f} className="flex gap-2">
                  <span className={p.featured ? 'text-black/70' : 'text-hom-primary'}>✓</span>
                  <span className={p.featured ? 'text-black/80' : 'text-white/70'}>{f}</span>
                </li>
              ))}
            </ul>
            <Link
              href="/contact"
              className={`text-center py-3 rounded-xl font-bold transition-colors ${p.featured ? 'bg-black text-hom-primary hover:bg-black/80' : 'bg-hom-primary text-black hover:bg-hom-primary/90'}`}
            >
              {p.cta}
            </Link>
          </div>
        ))}
      </div>

      <section className="border-t border-white/5 pt-16 mb-16">
        <h2 className="text-3xl font-black tracking-tight text-center mb-4">Compare plans</h2>
        <p className="text-white/50 text-center max-w-xl mx-auto mb-10">Everything below is included at each level. No hidden fees, no per-seat charges.</p>
        <div className="overflow-x-auto rounded-3xl border border-white/5">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="bg-hom-panel border-b border-white/5">
                <th className="px-5 py-4 font-bold">Feature</th>
                <th className="px-5 py-4 font-bold">Starter</th>
                <th className="px-5 py-4 font-bold text-hom-primary">Growth</th>
                <th className="px-5 py-4 font-bold">Enterprise</th>
              </tr>
            </thead>
            <tbody>
              {COMPARE.map((row) => (
                <tr key={row.feature} className="border-b border-white/5 last:border-0">
                  <td className="px-5 py-3 text-white/70">{row.feature}</td>
                  <td className="px-5 py-3"><Cell v={row.starter} /></td>
                  <td className="px-5 py-3"><Cell v={row.growth} /></td>
                  <td className="px-5 py-3"><Cell v={row.enterprise} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="border-t border-white/5 pt-16">
        <h2 className="text-3xl font-black tracking-tight text-center mb-10">Pricing questions</h2>
        <div className="grid md:grid-cols-2 gap-4 max-w-4xl mx-auto">
          {FAQ.map((f) => (
            <div key={f.q} className="rounded-2xl bg-hom-panel border border-white/5 p-6">
              <h3 className="font-bold mb-2 text-sm">{f.q}</h3>
              <p className="text-sm text-white/50 leading-relaxed">{f.a}</p>
            </div>
          ))}
        </div>
        <p className="text-center mt-8 text-sm text-white/40">
          Need something custom? <Link href="/contact" className="text-hom-primary font-semibold hover:underline">Talk to sales</Link>
        </p>
      </section>

      <p className="text-center text-xs text-white/30 mt-10 max-w-xl mx-auto">
        All prices exclude VAT and are billed monthly in naira. Want to trial first? Start on Starter and upgrade in one click.
      </p>
    </div>
  )
}
