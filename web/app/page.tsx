import Image from "next/image";
export default function Home() {
  return (
    <main className="min-h-screen">
      <header className="border-b sticky top-0 bg-white/80 backdrop-blur z-50">
        <div className="max-w-6xl mx-auto flex items-center justify-between p-4">
          <div className="flex items-center gap-3">
            <img src="/logo.png" alt="hom.com.ng" className="h-10 w-10 object-contain" />
            <span className="font-bold text-xl text-[#0E9F6E]">hom.com.ng</span>
          </div>
          <a href="/dashboard" className="bg-[#0E9F6E] text-white px-5 py-2 rounded-full">Dashboard</a>
        </div>
      </header>
      <section className="max-w-6xl mx-auto px-6 py-24 text-center">
        <img src="/logo.png" alt="Corinthian" className="mx-auto h-32 w-32 mb-6" />
        <h1 className="text-5xl font-black">The Hotel OS Powering Nigeria</h1>
        <p className="mt-4 text-xl text-zinc-600">Corinthian Edition — Stability + Growth — Built by Hexadigitall</p>
        <div className="mt-8 flex justify-center gap-4">
          <a href="/dashboard" className="bg-[#0E9F6E] text-white px-8 py-3 rounded-full">Launch Dashboard</a>
          <a href="https://hexadigitall.com" className="border px-8 py-3 rounded-full">hexadigitall.com</a>
        </div>
        <div className="mt-16 grid md:grid-cols-3 gap-6 text-left">
          {[
            ["Bookings + Front Desk", "VAT 7.5% auto, overbooking prevention"],
            ["Diesel + Inventory", "L tracking, NEPA vs Gen, theft alerts"],
            ["HR + Payroll + WhatsApp", "PAYE 7% + Pension 8%, payslip via WhatsApp"]
          ].map(([t,d])=>(
            <div key={t} className="border rounded-2xl p-6">
              <h3 className="font-bold">{t}</h3><p className="text-zinc-600 mt-2">{d}</p>
            </div>
          ))}
        </div>
      </section>
      <footer className="border-t py-8 text-center text-sm text-zinc-500">
        Built by Hexadigitall — <a href="https://hexadigitall.com" className="underline">hexadigitall.com</a> / <a href="https://github.com/hexadigitall" className="underline">github.com/hexadigitall</a> — Paystack Test: pk_test_7547...
      </footer>
    </main>
  )
}
