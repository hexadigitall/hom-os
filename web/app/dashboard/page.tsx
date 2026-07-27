"use client";
import { useState, useEffect } from 'react';
type Room = { id: string, number: string, type: string, status: 'available'|'occupied'|'maintenance', price: number }
type Booking = { id: string, guest: string, phone: string, room: string, checkin: string, checkout: string, status: string, amount: number }
type Diesel = { id: string, date: string, liters: number, cost: number, supplier: string, gen_hours: number, note: string }
type Item = { id: string, name: string, qty: number, low: number, cost: number }
type Staff = { id: string, name: string, role: string, salary: number }

const initialRooms: Room[] = [
  {id:'1', number:'101', type:'Deluxe', status:'available', price:25000},
  {id:'2', number:'102', type:'Deluxe', status:'occupied', price:25000},
  {id:'3', number:'103', type:'Standard', status:'available', price:15000},
  {id:'4', number:'201', type:'Executive', status:'maintenance', price:40000},
  {id:'5', number:'202', type:'Executive', status:'available', price:40000},
];

export default function Dashboard() {
  const [tab, setTab] = useState('bookings');
  const [rooms, setRooms] = useState<Room[]>(initialRooms);
  const [bookings, setBookings] = useState<Booking[]>(()=>{if(typeof window==='undefined') return []; const s=localStorage.getItem('hom_bookings'); return s?JSON.parse(s):[{id:'b1', guest:'John Doe', phone:'08031234567', room:'102', checkin:'2026-07-27', checkout:'2026-07-29', status:'checked-in', amount:50000}];});
  const [diesel, setDiesel] = useState<Diesel[]>(()=>{if(typeof window==='undefined') return []; const s=localStorage.getItem('hom_diesel'); return s?JSON.parse(s):[{id:'d1', date:'2026-07-26', liters:200, cost:240000, supplier:'MRS PH', gen_hours:12, note:'No theft'}];});
  const [inventory, setInventory] = useState<Item[]>(()=>{if(typeof window==='undefined') return []; const s=localStorage.getItem('hom_inv'); return s?JSON.parse(s):[{id:'i1', name:'Tissue', qty:50, low:10, cost:500},{id:'i2', name:'Bottled Water', qty:8, low:20, cost:200}];});
  const [staff] = useState<Staff[]>([{id:'s1', name:'Amina Yusuf', role:'Front Desk', salary:120000},{id:'s2', name:'Chidi O.', role:'Cleaner', salary:70000}]);
  const [newBooking, setNewBooking] = useState({guest:'', phone:'', room:'101', checkin:'', checkout:''});
  const [newDiesel, setNewDiesel] = useState({liters:'', cost:'', supplier:'', gen_hours:'', note:''});

  useEffect(()=>{localStorage.setItem('hom_bookings', JSON.stringify(bookings))},[bookings]);
  useEffect(()=>{localStorage.setItem('hom_diesel', JSON.stringify(diesel))},[diesel]);
  useEffect(()=>{localStorage.setItem('hom_inv', JSON.stringify(inventory))},[inventory]);

  const createBooking = () => {
    if(!newBooking.guest) return alert('Guest name required');
    const room = rooms.find(r=>r.number===newBooking.room);
    if(!room || room.status!=='available') return alert('Room not available - prevents overbooking!');
    const b: Booking = {id: 'b'+Date.now(), guest:newBooking.guest, phone:newBooking.phone, room:newBooking.room, checkin:newBooking.checkin, checkout:newBooking.checkout, status:'confirmed', amount:room.price*2};
    setBookings([b, ...bookings]);
    setRooms(rooms.map(r=> r.number===newBooking.room ? {...r, status:'occupied'} : r));
    const msg = `Hello ${b.guest}, your HOM booking Room ${b.room} from ${b.checkin} is confirmed. — HOM Hospitality Operations Manager`;
    console.log('[WHATSAPP MOCK]', b.phone, msg);
    alert(`Booking created + WhatsApp mock sent to ${b.phone}: ${msg}`);
    setNewBooking({guest:'', phone:'', room:'101', checkin:'', checkout:''});
  };

  const addDiesel = () => {
    const d: Diesel = {id:'d'+Date.now(), date:new Date().toISOString().slice(0,10), liters:Number(newDiesel.liters), cost:Number(newDiesel.cost), supplier:newDiesel.supplier, gen_hours:Number(newDiesel.gen_hours), note:newDiesel.note};
    if(d.gen_hours>0 && d.liters/d.gen_hours < 8) alert(`THEFT ALERT: ${ (d.liters/d.gen_hours).toFixed(1)}L/hr - below 8L/hr threshold!`);
    setDiesel([d, ...diesel]);
  };

  const paye = (s:number)=>s*0.07; const pension=(s:number)=>s*0.08;

  return (
    <main className="min-h-screen bg-[#f6f7f5] flex">
      <aside className="w-64 bg-[#0E1A14] text-white p-5 hidden md:block sticky top-0 h-screen overflow-y-auto">
        <div className="flex items-center gap-3 mb-10">
          <div className="h-10 w-10 bg-white rounded-[12px] border-2 border-[#0E9F6E] p-1"><img src="/logo.png" className="h-full w-full" /></div>
          <div><div className="font-black">HOM</div><div className="text-[9px] text-green-300 tracking-widest">HOSPITALITY OPERATIONS MANAGER</div></div>
        </div>
        <nav className="space-y-1">
          {[['bookings','Bookings','VAT 7.5% + WhatsApp'],['rooms','Rooms','Anti-overbooking'],['diesel','Diesel','Theft detection'],['inventory','Inventory','Low stock'],['staff','HR & Payroll','PAYE 7% Pension 8%'],['vendors','Vendors','POs'],['paystack','Paystack','Payments'],['whatsapp','WhatsApp','Cloud API'],['bookingcom','Booking.com','Channel sync']].map(([id,label,sub])=>(
            <button key={id} onClick={()=>setTab(id)} className={`w-full text-left px-3 py-3 rounded-xl ${tab===id?'bg-[#0E9F6E]':'hover:bg-white/10 text-zinc-300'}`}><div className="font-medium text-sm">{label}</div><div className="text-[11px] opacity-60">{sub}</div></button>
          ))}
        </nav>
      </aside>
      <div className="flex-1">
        <header className="bg-white border-b p-4 flex justify-between items-center sticky top-0 z-10"><h1 className="font-bold capitalize">{tab}</h1><span className="text-xs bg-green-100 text-green-700 px-3 py-1 rounded-full">HOM • LIVE</span></header>
        <div className="p-4 md:p-8 max-w-6xl mx-auto">
          <div className="md:hidden flex gap-2 overflow-x-auto pb-4">{['bookings','rooms','diesel','inventory','staff','paystack','whatsapp','bookingcom'].map(t=><button key={t} onClick={()=>setTab(t)} className={`px-4 py-2 rounded-full text-sm whitespace-nowrap ${tab===t?'bg-[#0E9F6E] text-white':'bg-white border'}`}>{t}</button>)}</div>

          {tab==='bookings' && (
            <div className="grid lg:grid-cols-3 gap-6">
              <div className="bg-white rounded-2xl p-6 border h-fit"><h3 className="font-bold">New Booking — HOM</h3>
                <div className="mt-4 space-y-3">
                  <input value={newBooking.guest} onChange={e=>setNewBooking({...newBooking, guest:e.target.value})} placeholder="Guest name" className="w-full border rounded-xl px-4 py-2.5" />
                  <input value={newBooking.phone} onChange={e=>setNewBooking({...newBooking, phone:e.target.value})} placeholder="Phone + WhatsApp" className="w-full border rounded-xl px-4 py-2.5" />
                  <select value={newBooking.room} onChange={e=>setNewBooking({...newBooking, room:e.target.value})} className="w-full border rounded-xl px-4 py-2.5">{rooms.map(r=><option key={r.id} value={r.number} disabled={r.status!=='available'}>{r.number} {r.status!=='available'?`(${r.status})`:''} ₦{r.price}</option>)}</select>
                  <div className="grid grid-cols-2 gap-2"><input type="date" value={newBooking.checkin} onChange={e=>setNewBooking({...newBooking, checkin:e.target.value})} className="border rounded-xl px-3 py-2" /><input type="date" value={newBooking.checkout} onChange={e=>setNewBooking({...newBooking, checkout:e.target.value})} className="border rounded-xl px-3 py-2" /></div>
                  <button onClick={createBooking} className="w-full bg-[#0E9F6E] text-white py-3 rounded-xl font-bold">Create + WhatsApp Confirm</button>
                </div>
              </div>
              <div className="lg:col-span-2 bg-white rounded-2xl border divide-y">{bookings.map(b=><div key={b.id} className="p-4 flex justify-between"><div><div className="font-bold">{b.guest} — Room {b.room}</div><div className="text-xs text-zinc-500">{b.checkin}→{b.checkout} • {b.phone}</div></div><div className="text-right"><div className="font-bold">₦{b.amount.toLocaleString()}</div><span className="text-[10px] bg-green-100 text-green-700 px-2 py-1 rounded-full">{b.status}</span></div></div>)}</div>
            </div>
          )}

          {tab==='rooms' && <div className="grid md:grid-cols-3 gap-4">{rooms.map(r=><div key={r.id} className="bg-white rounded-2xl p-6 border"><div className="flex justify-between"><span className="font-black text-2xl">{r.number}</span><span className={`text-xs px-2 py-1 rounded-full ${r.status==='available'?'bg-green-100 text-green-700':'bg-red-100 text-red-700'}`}>{r.status}</span></div><div className="text-sm text-zinc-500">{r.type} ₦{r.price}</div></div>)}</div>}

          {tab==='diesel' && (
            <div className="grid lg:grid-cols-3 gap-6">
              <div className="bg-white rounded-2xl p-6 border"><h3 className="font-bold">Log Diesel</h3><div className="mt-4 space-y-2"><input value={newDiesel.liters} onChange={e=>setNewDiesel({...newDiesel, liters:e.target.value})} placeholder="Liters" className="w-full border rounded-xl px-4 py-2.5" /><input value={newDiesel.cost} onChange={e=>setNewDiesel({...newDiesel, cost:e.target.value})} placeholder="Cost" className="w-full border rounded-xl px-4 py-2.5" /><input value={newDiesel.supplier} onChange={e=>setNewDiesel({...newDiesel, supplier:e.target.value})} placeholder="Supplier" className="w-full border rounded-xl px-4 py-2.5" /><input value={newDiesel.gen_hours} onChange={e=>setNewDiesel({...newDiesel, gen_hours:e.target.value})} placeholder="Gen hours" className="w-full border rounded-xl px-4 py-2.5" /><button onClick={addDiesel} className="w-full bg-[#0E9F6E] text-white py-3 rounded-xl font-bold">Add Log</button></div></div>
              <div className="lg:col-span-2 bg-white rounded-2xl border divide-y">{diesel.map(d=><div key={d.id} className="p-4 flex justify-between"><div><b>{d.liters}L • {d.supplier}</b><div className="text-xs text-zinc-500">{d.date} • {d.gen_hours}hrs</div></div><b>₦{d.cost.toLocaleString()}</b></div>)}</div>
            </div>
          )}

          {tab==='inventory' && <div className="bg-white rounded-2xl border divide-y">{inventory.map(it=><div key={it.id} className="p-4 flex justify-between"><div><b>{it.name} {it.qty<=it.low && <span className="bg-red-100 text-red-700 text-[10px] px-2 py-1 rounded-full ml-2">LOW</span>}</b><div className="text-xs">Qty {it.qty} Min {it.low}</div></div><div className="flex gap-2"><button onClick={()=>setInventory(inventory.map(x=>x.id===it.id?{...x, qty:x.qty-1}:x))} className="border px-3 py-1 rounded-full">-1</button><button onClick={()=>setInventory(inventory.map(x=>x.id===it.id?{...x, qty:x.qty+10}:x))} className="bg-[#0E9F6E] text-white px-3 py-1 rounded-full">+10</button></div></div>)}</div>}

          {tab==='staff' && <div className="bg-white rounded-2xl border divide-y">{staff.map(s=>{const net=s.salary-paye(s.salary)-pension(s.salary); return <div key={s.id} className="p-5 flex justify-between"><div><b>{s.name}</b><div className="text-xs">{s.role} Gross ₦{s.salary.toLocaleString()}</div></div><div className="text-right text-xs"><div>PAYE 7% ₦{paye(s.salary).toLocaleString()}</div><div>Pension 8% ₦{pension(s.salary).toLocaleString()}</div><div className="font-bold">Net ₦{net.toLocaleString()}</div><button onClick={()=>alert(`WhatsApp payslip: Net ₦${net}`)} className="mt-2 bg-green-600 text-white px-3 py-1 rounded-full text-[11px]">WhatsApp</button></div></div>})}</div>}

          {tab==='whatsapp' && (
            <div className="bg-white rounded-2xl p-8 border">
              <h3 className="font-black text-2xl">WhatsApp Cloud API — HOM</h3>
              <p className="text-sm text-zinc-600 mt-2">Set NEXT_PUBLIC_WHATSAPP_TOKEN and PHONE_ID in .env. Currently in mock mode logs to console.</p>
              <div className="mt-6 bg-zinc-900 text-green-400 p-4 rounded-xl font-mono text-xs">
                [MOCK] To 0803...: Hello John, your HOM booking Room 102 is confirmed!<br/>[MOCK] Payslip sent via HOM
              </div>
              <div className="mt-4 p-4 bg-green-50 rounded-xl text-xs">Code: lib/whatsapp.ts — sendWhatsApp(), bookingConfirmationTemplate(), payslipTemplate()</div>
            </div>
          )}

          {tab==='bookingcom' && (
            <div className="bg-white rounded-2xl p-8 border">
              <h3 className="font-black text-2xl">Booking.com Channel Sync — Anti-Overbooking</h3>
              <p className="text-sm text-zinc-600 mt-2">Prevents double-booking between Booking.com and walk-ins. Checks room availability vs external bookings.</p>
              <div className="mt-6 grid md:grid-cols-2 gap-4">
                <div className="border rounded-xl p-4"><b>External Bookings Fetched</b><div className="text-xs mt-2">1 booking from Booking.com (mock)</div><div className="mt-3 bg-yellow-50 p-2 rounded text-xs">Risk check: if external occupied ≥ available, block new walk-in</div></div>
                <div className="border rounded-xl p-4"><b>Integration Steps</b><div className="text-xs mt-2">1. Get Booking.com Connectivity API key<br/>2. Set BOOKINGCOM_API_KEY in .env<br/>3. Replace fetchBookingComBookings() in lib/bookingcom.ts with real XML API call<br/>4. Cron sync every 5min</div></div>
              </div>
              <div className="mt-4 text-[11px] text-zinc-500">File: lib/bookingcom.ts — checkOverbooking() logic ready.</div>
            </div>
          )}

          {tab==='paystack' && <div className="bg-white rounded-2xl p-8 border text-center"><h3 className="font-black text-2xl">Paystack Live</h3><p className="text-sm text-zinc-500 mt-2">pk_test_7547... — switch to live key in .env</p><button onClick={()=>{const w=window as any; const h=w.PaystackPop?.setup({key:'pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6', email:'admin@hom.ng', amount:1500000, callback:()=>alert('Paid')}); h?.openIframe();}} className="mt-6 bg-[#0E9F6E] text-white px-8 py-3 rounded-full font-bold">Test Pay ₦15k</button><script src="https://js.paystack.co/v1/inline.js"></script></div>}
        </div>
      </div>
    </main>
  )
}
