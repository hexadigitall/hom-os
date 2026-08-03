import Link from 'next/link'

const VALUES = [
  { title: 'Offline-first, always', desc: "Nigerian hotels shouldn't stop working when the internet does. HOM runs fully on-device and syncs when it can." },
  { title: 'Built for the operator', desc: 'Named after the Hospitality Operations Manager — the person on the ground who needs the truth, not more paperwork.' },
  { title: 'Data stays on the property', desc: "Your hotel's data lives on your devices. No cloud lock-in; enterprise deployments can even run fully on-premise." },
  { title: 'Honest software', desc: "No fake progress bars, no hidden fees, no tricks. If a feature isn't done, we say so." },
]

const ROADMAP = [
  { title: 'On the road now', items: ['Faster web app via code-splitting', 'Multi-property rollups for groups', 'Booking.com channel manager deep-sync'] },
  { title: 'Coming next', items: ['POS / F&B terminal for kitchens', 'Housekeeping mobile app', 'Vendor tender scoring'] },
  { title: 'On the horizon', items: ['AI-assisted night audit', 'Loyalty & guest CRM', 'Offline mesh sync between devices'] },
]

export default function AboutPage() {
  return (
    <div className="max-w-4xl mx-auto px-6 py-16">
      <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
        ABOUT
      </div>
      <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-6">Built by Hexadigitall, for Nigerian hotels</h1>

      <div className="space-y-6 text-white/60 text-lg leading-relaxed mb-12">
        <p>
          HOM is short for Hospitality Operations Manager — the hotel operating system powering Nigeria. It was born from a simple observation: Nigerian hotels run on
          paper log books, generator diesel that disappears, and accountants chasing bank statements.
        </p>
        <p>
          So we built one offline-first OS that runs the whole property — bookings, diesel tracking across five fuel types, expenditure control, compliance automation,
          payroll with PAYE and pension, vendors, WhatsApp integration and bank reconciliation. It works without internet, in a language your staff already use.
        </p>
        <p>
          HOM is built by <Link href="https://hexadigitall.com" className="text-hom-primary font-semibold">Hexadigitall</Link> — a Nigerian software studio building production software for the businesses that power the country. The
          roadmap is public on GitHub and every release ships with signed builds and checksums.
        </p>
      </div>

      <section className="border-t border-white/5 pt-12 mb-12">
        <h2 className="text-2xl font-black tracking-tight mb-6">What we believe</h2>
        <div className="grid sm:grid-cols-2 gap-4">
          {VALUES.map((v) => (
            <div key={v.title} className="rounded-2xl bg-hom-panel border border-white/5 p-6">
              <h3 className="font-bold mb-2 text-hom-primary">{v.title}</h3>
              <p className="text-sm text-white/50 leading-relaxed">{v.desc}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="border-t border-white/5 pt-12 mb-12">
        <h2 className="text-2xl font-black tracking-tight mb-6">The roadmap</h2>
        <div className="grid md:grid-cols-3 gap-4">
          {ROADMAP.map((r) => (
            <div key={r.title} className="rounded-2xl bg-hom-panel border border-white/5 p-6">
              <h3 className="font-bold text-sm mb-4">{r.title}</h3>
              <ul className="space-y-2">
                {r.items.map((i) => (
                  <li key={i} className="flex gap-2 text-sm text-white/60">
                    <span className="text-hom-primary">›</span> {i}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>

      <section className="rounded-3xl bg-hom-panel border border-white/5 p-8 flex flex-col md:flex-row md:items-center gap-6">
        <div className="w-14 h-14 rounded-xl bg-hom-primary flex items-center justify-center font-black text-black text-2xl">H</div>
        <div className="flex-1">
          <p className="font-bold">HOM Hospitality — hom.com.ng</p>
          <p className="text-xs text-white/40 mt-1">
            Development on <Link href="https://github.com/hexadigitall/hom-os" className="text-hom-primary">github.com/hexadigitall/hom-os</Link> • Released under a proprietary license
          </p>
        </div>
        <Link href="/contact" className="px-5 py-2.5 rounded-xl bg-hom-primary text-black font-bold text-sm whitespace-nowrap">Talk to the team</Link>
      </section>
    </div>
  )
}
