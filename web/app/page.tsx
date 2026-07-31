export default function Home(){
  return (
    <main className="min-h-screen bg-hom-background">
      <header className="sticky top-0 z-50 bg-white/90 backdrop-blur border-b">
        <div className="max-w-7xl mx-auto p-4 flex justify-between items-center">
          <div className="flex items-center gap-3 min-w-0">
            <div className="h-11 w-11 rounded-[14px] bg-white border-2 border-hom-primary p-1.5 shadow-sm flex items-center justify-center shrink-0">
              <img src="/logo.png" alt="HOM" className="h-full w-full object-contain" />
            </div>
            <div className="min-w-0">
              <div className="font-black tracking-tight text-xl leading-none">HOM</div>
              <div className="text-[10px] font-bold text-hom-primary tracking-widest uppercase truncate">Hospitality Operations Manager</div>
            </div>
          </div>
          <a href="/dashboard" className="bg-hom-ink text-white px-5 sm:px-6 py-2.5 rounded-full font-bold text-sm shrink-0">Open OS</a>
        </div>
      </header>
      <section className="max-w-7xl mx-auto px-5 sm:px-6 py-14 md:py-24 grid md:grid-cols-2 gap-10 md:gap-12 items-center">
        <div>
          <div className="inline-flex items-center gap-2 bg-white border border-hom-primary/20 px-3 py-1 rounded-full text-xs font-bold text-hom-primary">THE HOTEL OS</div>
          <h1 className="mt-6 text-4xl sm:text-5xl md:text-7xl font-black tracking-tighter leading-[0.9] sm:leading-[0.85]">HOM.<br/>The Hotel OS.</h1>
          <p className="mt-6 text-base sm:text-lg text-zinc-600 max-w-xl">HOM — Hospitality Operations Manager. One OS for bookings, diesel theft detection, inventory, HR/Payroll PAYE 7% Pension 8%, Paystack, WhatsApp Cloud API and Booking.com sync.</p>
          <div className="mt-8 flex flex-col sm:flex-row gap-3">
            <a href="/dashboard" className="bg-hom-primary text-white px-8 py-3.5 rounded-full font-black text-center">Launch Dashboard</a>
            <a href="https://hexadigitall.com" className="border px-8 py-3.5 rounded-full font-bold text-center">By Hexadigitall</a>
          </div>
        </div>
        <div className="bg-hom-ink rounded-[2rem] sm:rounded-[2.5rem] p-3 shadow-2xl max-w-md w-full mx-auto">
          <div className="bg-white rounded-[1.5rem] sm:rounded-[2rem] p-6">
            <div className="flex items-center gap-3">
              <div className="h-14 w-14 rounded-[16px] border-2 border-hom-primary p-2"><img src="/logo.png" className="h-full w-full" /></div>
              <div><div className="font-black">HOM</div><div className="text-[11px] text-zinc-500">Hospitality Operations Manager</div></div>
            </div>
            <div className="mt-6 grid grid-cols-2 gap-3 text-xs">
              <div className="bg-hom-background rounded-2xl p-4"><div className="text-2xl font-black">127</div>Bookings</div>
              <div className="bg-hom-primary text-white rounded-2xl p-4"><div className="text-2xl font-black">840L</div>Diesel</div>
            </div>
          </div>
        </div>
      </section>
      <footer className="border-t py-10 text-center text-xs text-zinc-500">HOM — Hospitality Operations Manager • hom.com.ng • Built by Hexadigitall</footer>
    </main>
  )
}
