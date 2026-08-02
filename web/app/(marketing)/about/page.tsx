import Link from 'next/link'

export default function AboutPage() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-16">
      <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
        ABOUT
      </div>
      <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-6">Built by Hexadigitall, for Nigerian hotels</h1>
      <div className="space-y-6 text-white/60 text-lg leading-relaxed">
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
          code is open source and the roadmap is public on GitHub.
        </p>
      </div>
      <div className="mt-10 rounded-2xl bg-hom-panel border border-white/5 p-6 flex items-center gap-4">
        <div className="w-12 h-12 rounded-xl bg-hom-primary flex items-center justify-center font-black text-black text-xl">H</div>
        <div>
          <p className="font-bold">HOM Hospitality — hom.com.ng</p>
          <p className="text-xs text-white/40">Open source on <Link href="https://github.com/hexadigitall/hom-os" className="text-hom-primary">github.com/hexadigitall/hom-os</Link></p>
        </div>
      </div>
    </div>
  )
}
