'use client';
import { useState } from 'react';
export default function Dashboard() {
  const [paystackKey] = useState(process.env.NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY || 'pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6');
  const pay = () => {
    // @ts-ignore
    const handler = window.PaystackPop?.setup({ key: paystackKey, email: 'admin@hom.ng', amount: 1500000, onClose: ()=>{}, callback: ()=>alert('Payment success') });
    handler?.openIframe();
  };
  return (
    <main className="min-h-screen bg-zinc-50">
      <header className="bg-white border-b p-4 flex justify-between">
        <div className="flex items-center gap-2"><img src="/logo.png" className="h-8 w-8" /><b>hom.com.ng / Dashboard</b></div>
        <span className="text-xs bg-green-100 text-green-700 px-3 py-1 rounded-full">Corinthian • Live</span>
      </header>
      <div className="max-w-6xl mx-auto p-6 grid md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl p-6 border"><h3 className="font-bold">Bookings</h3><p className="text-3xl mt-2">127</p><p className="text-zinc-500 text-sm">This week</p></div>
        <div className="bg-white rounded-2xl p-6 border"><h3 className="font-bold">Diesel (L)</h3><p className="text-3xl mt-2">840L</p><p className="text-zinc-500 text-sm">₦500k theft prevented</p></div>
        <div className="bg-white rounded-2xl p-6 border"><h3 className="font-bold">Paystack</h3><button onClick={pay} className="mt-3 bg-[#0E9F6E] text-white px-4 py-2 rounded-full w-full">Pay ₦15k Sub</button><p className="text-[10px] mt-2 text-zinc-500">{paystackKey.slice(0,16)}...</p></div>
      </div>
      <script src="https://js.paystack.co/v1/inline.js"></script>
    </main>
  )
}
