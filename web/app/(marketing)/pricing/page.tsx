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
      <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
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
      <p className="text-center text-xs text-white/30 mt-10 max-w-xl mx-auto">
        All prices exclude VAT and are billed monthly in naira. Want to trial first? Start on Starter and upgrade in one click.
      </p>
    </div>
  )
}
