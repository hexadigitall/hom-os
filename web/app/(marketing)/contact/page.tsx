"use client"
import { useState } from 'react'

export default function ContactPage() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [hotel, setHotel] = useState('')
  const [message, setMessage] = useState('')

  const buildMailto = () => {
    const subject = encodeURIComponent(`HOM enquiry from ${name || 'a hotel'}`)
    const body = encodeURIComponent(
      `Name: ${name}\nEmail: ${email}\nHotel: ${hotel}\n\n${message}`
    )
    return `mailto:hello@hexadigitall.com?subject=${subject}&body=${body}`
  }

  const whatsappHref = () =>
    `https://wa.me/2348000000000?text=${encodeURIComponent(`Hi, I'm interested in HOM. ${name ? `My name is ${name}.` : ''} ${hotel ? `Hotel: ${hotel}.` : ''}`)}`

  return (
    <div className="max-w-3xl mx-auto px-6 py-16">
      <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-hom-primary/10 border border-hom-primary/20 text-hom-primary text-xs mb-6">
        CONTACT
      </div>
      <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Talk to the team</h1>
      <p className="text-white/50 mb-10">
        Questions about HOM, pricing or a demo? Reach us on WhatsApp or send an email — we reply fast.
      </p>

      <div className="grid md:grid-cols-5 gap-6">
        <form
          className="md:col-span-3 space-y-4 bg-hom-panel border border-white/5 rounded-3xl p-6"
          action={buildMailto()}
          method="get"
        >
          <input
            required
            type="text"
            placeholder="Your name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-hom-night border border-white/10 text-white placeholder-white/30 outline-none focus:border-hom-primary"
          />
          <input
            required
            type="email"
            placeholder="Email address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-hom-night border border-white/10 text-white placeholder-white/30 outline-none focus:border-hom-primary"
          />
          <input
            type="text"
            placeholder="Hotel / property name"
            value={hotel}
            onChange={(e) => setHotel(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-hom-night border border-white/10 text-white placeholder-white/30 outline-none focus:border-hom-primary"
          />
          <textarea
            rows={4}
            placeholder="How can we help?"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-hom-night border border-white/10 text-white placeholder-white/30 outline-none focus:border-hom-primary"
          />
          <button type="submit" className="w-full py-3 rounded-xl bg-hom-primary text-black font-bold hover:bg-hom-primary/90 transition-colors">
            Send Email
          </button>
        </form>

        <div className="md:col-span-2 space-y-4">
          <a href={whatsappHref()} target="_blank" rel="noreferrer" className="block rounded-3xl bg-hom-panel border border-white/5 p-6 hover:border-hom-primary/40 transition-colors">
            <p className="text-2xl mb-2">💬</p>
            <p className="font-bold">WhatsApp us</p>
            <p className="text-xs text-white/40 mt-1">Fastest for hoteliers. Chat with the HOM team directly.</p>
          </a>
          <a href="mailto:hello@hexadigitall.com" className="block rounded-3xl bg-hom-panel border border-white/5 p-6 hover:border-hom-primary/40 transition-colors">
            <p className="text-2xl mb-2">✉️</p>
            <p className="font-bold">hello@hexadigitall.com</p>
            <p className="text-xs text-white/40 mt-1">For sales, support and partnerships.</p>
          </a>
          <div className="rounded-3xl bg-hom-panel border border-white/5 p-6">
            <p className="text-2xl mb-2">📍</p>
            <p className="font-bold">Made in Nigeria</p>
            <p className="text-xs text-white/40 mt-1">Built by Hexadigitall — hexadigitall.com</p>
          </div>
        </div>
      </div>
    </div>
  )
}
