import Link from 'next/link'

const BULLETS = [
  { title: 'Real wa.me Payslips', desc: 'Every pay slip opens on WhatsApp with one tap — no fake snackbars claiming to be WhatsApp.' },
  { title: 'Booking Confirmations', desc: 'Guests get their confirmation and receipt automatically, in chat, the moment they book.' },
  { title: 'Purchase Order Notifications', desc: 'Vendors receive POs instantly and can confirm on their phone.' },
  { title: 'WhatsApp Cloud API', desc: 'Production-grade integration built on the official WhatsApp Business Cloud API.' },
  { title: 'Group & Department Chats', desc: 'Shift handovers, housekeeping requests and incident reports where staff already talk.' },
  { title: 'No Fake UI', desc: 'If it says WhatsApp, it opens WhatsApp. Every message is real and delivered.' },
]

export default function WhatsAppPage() {
  return (
    <div className="max-w-6xl mx-auto px-6 py-16">
      <nav className="text-xs text-white/30 mb-8">
        <Link href="/features" className="hover:text-hom-primary">Features</Link> <span className="mx-2">/</span> WhatsApp
      </nav>
      <div className="max-w-3xl mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
          💬 WHATSAPP INTEGRATION
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">The whole hotel runs where Nigeria already chats</h1>
        <p className="text-white/50 text-lg leading-relaxed">
          HOM pushes payslips, booking confirmations and purchase orders straight into WhatsApp. No extra app to install, no fake snackbars pretending to be WhatsApp — real messages, delivered.
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
