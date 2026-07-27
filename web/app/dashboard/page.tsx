'use client';
import { useState, useEffect, useCallback } from 'react';
import Script from 'next/script';
import {
  BedDouble, CalendarCheck, Fuel, Package, Users, CreditCard,
  MessageCircle, Globe, Store, Plus, Trash2, Edit3, CheckCircle,
  XCircle, LogOut, AlertTriangle, Send, Search, ChevronDown, Eye, X
} from 'lucide-react';
import { sendWhatsApp, bookingConfirmationTemplate, payslipTemplate } from '@/lib/whatsapp';
import { fetchBookingComBookings, checkOverbooking, ExternalBooking } from '@/lib/bookingcom';

type Room = { id: string; number: string; type: string; status: 'available' | 'occupied' | 'maintenance'; price: number };
type Booking = { id: string; guest: string; phone: string; room: string; checkin: string; checkout: string; status: 'confirmed' | 'checked-in' | 'checked-out' | 'cancelled'; amount: number };
type Diesel = { id: string; date: string; liters: number; cost: number; supplier: string; genHours: number; note: string };
type InventoryItem = { id: string; name: string; qty: number; low: number; cost: number };
type Staff = { id: string; name: string; role: string; salary: number };
type Vendor = { id: string; name: string; contact: string; category: string };
type PurchaseOrder = { id: string; vendorId: string; items: string; amount: number; date: string; status: 'pending' | 'approved' | 'delivered' };

const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
const today = () => new Date().toISOString().slice(0, 10);

const defaultRooms: Room[] = [
  { id: 'r1', number: '101', type: 'Deluxe', status: 'available', price: 25000 },
  { id: 'r2', number: '102', type: 'Deluxe', status: 'occupied', price: 25000 },
  { id: 'r3', number: '103', type: 'Standard', status: 'available', price: 15000 },
  { id: 'r4', number: '201', type: 'Executive', status: 'maintenance', price: 40000 },
  { id: 'r5', number: '202', type: 'Executive', status: 'available', price: 40000 },
];

const defaultBookings: Booking[] = [
  { id: 'b1', guest: 'John Doe', phone: '08031234567', room: '102', checkin: '2026-07-27', checkout: '2026-07-29', status: 'checked-in', amount: 50000 },
];

const defaultDiesel: Diesel[] = [
  { id: 'd1', date: '2026-07-26', liters: 200, cost: 240000, supplier: 'MRS PH', genHours: 12, note: 'No theft detected' },
];

const defaultInventory: InventoryItem[] = [
  { id: 'i1', name: 'Tissue Roll', qty: 50, low: 10, cost: 500 },
  { id: 'i2', name: 'Bottled Water', qty: 8, low: 20, cost: 200 },
  { id: 'i3', name: 'Towel Set', qty: 30, low: 10, cost: 2500 },
  { id: 'i4', name: 'Toiletry Kit', qty: 15, low: 5, cost: 1200 },
];

const defaultStaff: Staff[] = [
  { id: 's1', name: 'Amina Yusuf', role: 'Front Desk', salary: 120000 },
  { id: 's2', name: 'Chidi Okonkwo', role: 'Cleaner', salary: 70000 },
  { id: 's3', name: 'Blessing Eze', role: 'Manager', salary: 200000 },
];

const defaultVendors: Vendor[] = [
  { id: 'v1', name: 'MRS Petroleum', contact: '0801-234-5678', category: 'Fuel' },
  { id: 'v2', name: 'CleanPro Supplies', contact: '0809-876-5432', category: 'Cleaning' },
];

const defaultPOs: PurchaseOrder[] = [
  { id: 'po1', vendorId: 'v1', items: 'Diesel 500L', amount: 600000, date: '2026-07-25', status: 'delivered' },
];

function load<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;
  try { const s = localStorage.getItem(key); return s ? JSON.parse(s) : fallback; } catch { return fallback; }
}

export default function Dashboard() {
  const [mounted, setMounted] = useState(false);
  const [tab, setTab] = useState('overview');
  const [paystackKey] = useState(process.env.NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY || '');
  const [search, setSearch] = useState('');

  const [rooms, setRooms] = useState<Room[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [diesel, setDiesel] = useState<Diesel[]>([]);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [staff, setStaff] = useState<Staff[]>([]);
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [pos, setPOs] = useState<PurchaseOrder[]>([]);
  const [externalBookings, setExternalBookings] = useState<ExternalBooking[]>([]);

  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<any>(null);
  const [whatsappLog, setWhatsappLog] = useState<{to: string; msg: string; time: string}[]>([]);

  useEffect(() => {
    setRooms(load('hom_rooms', defaultRooms));
    setBookings(load('hom_bookings', defaultBookings));
    setDiesel(load('hom_diesel', defaultDiesel));
    setInventory(load('hom_inventory', defaultInventory));
    setStaff(load('hom_staff', defaultStaff));
    setVendors(load('hom_vendors', defaultVendors));
    setPOs(load('hom_pos', defaultPOs));
    setMounted(true);
    fetchBookingComBookings().then(setExternalBookings);
  }, []);

  useEffect(() => { if (mounted) localStorage.setItem('hom_rooms', JSON.stringify(rooms)); }, [rooms, mounted]);
  useEffect(() => { if (mounted) localStorage.setItem('hom_bookings', JSON.stringify(bookings)); }, [bookings, mounted]);
  useEffect(() => { if (mounted) localStorage.setItem('hom_diesel', JSON.stringify(diesel)); }, [diesel, mounted]);
  useEffect(() => { if (mounted) localStorage.setItem('hom_inventory', JSON.stringify(inventory)); }, [inventory, mounted]);
  useEffect(() => { if (mounted) localStorage.setItem('hom_staff', JSON.stringify(staff)); }, [staff, mounted]);
  useEffect(() => { if (mounted) localStorage.setItem('hom_vendors', JSON.stringify(vendors)); }, [vendors, mounted]);
  useEffect(() => { if (mounted) localStorage.setItem('hom_pos', JSON.stringify(pos)); }, [pos, mounted]);

  const logWhatsApp = useCallback(async (to: string, msg: string) => {
    const result = await sendWhatsApp(to, msg);
    setWhatsappLog(prev => [{ to, msg, time: new Date().toLocaleTimeString() }, ...prev].slice(0, 50));
    return result;
  }, []);

  const openPaystack = (email: string, amount: number) => {
    const key = paystackKey || 'pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6';
    // @ts-ignore
    const handler = window.PaystackPop?.setup({ key, email, amount, currency: 'NGN', callback: () => alert('Payment successful!'), onClose: () => {} });
    handler?.openIframe();
  };

  if (!mounted) return <div className="min-h-screen flex items-center justify-center"><div className="animate-pulse text-[#0E9F6E] text-xl font-bold">Loading HOM...</div></div>;

  const navItems = [
    { id: 'overview', label: 'Overview', icon: Eye },
    { id: 'bookings', label: 'Bookings', icon: CalendarCheck },
    { id: 'rooms', label: 'Rooms', icon: BedDouble },
    { id: 'diesel', label: 'Diesel', icon: Fuel },
    { id: 'inventory', label: 'Inventory', icon: Package },
    { id: 'staff', label: 'HR & Payroll', icon: Users },
    { id: 'vendors', label: 'Vendors', icon: Store },
    { id: 'paystack', label: 'Paystack', icon: CreditCard },
    { id: 'whatsapp', label: 'WhatsApp', icon: MessageCircle },
    { id: 'bookingcom', label: 'Booking.com', icon: Globe },
  ];

  const paye = (s: number) => Math.round(s * 0.07);
  const pension = (s: number) => Math.round(s * 0.08);

  return (
    <>
      <Script src="https://js.paystack.co/v1/inline.js" strategy="lazyOnload" />
      <main className="min-h-screen bg-[#f6f7f5] flex">
        <aside className="w-64 bg-[#0E1A14] text-white p-4 hidden md:flex flex-col sticky top-0 h-screen overflow-y-auto">
          <div className="flex items-center gap-3 mb-8 pb-4 border-b border-white/10">
            <div className="h-10 w-10 bg-white rounded-[12px] border-2 border-[#0E9F6E] p-1 flex-shrink-0"><img src="/logo.png" className="h-full w-full" alt="HOM" /></div>
            <div><div className="font-black text-sm">HOM</div><div className="text-[8px] text-green-300 tracking-widest leading-tight">HOSPITALITY OPERATIONS MANAGER</div></div>
          </div>
          <nav className="space-y-0.5 flex-1">
            {navItems.map(({ id, label, icon: Icon }) => (
              <button key={id} onClick={() => { setTab(id); setShowForm(false); setEditItem(null); }}
                className={`w-full text-left px-3 py-2.5 rounded-xl flex items-center gap-2.5 transition-colors ${tab === id ? 'bg-[#0E9F6E] text-white' : 'hover:bg-white/10 text-zinc-400'}`}>
                <Icon size={16} /><span className="text-sm">{label}</span>
              </button>
            ))}
          </nav>
          <div className="pt-4 border-t border-white/10 text-[10px] text-zinc-500">HOM v5 — Hexadigitall</div>
        </aside>

        <div className="flex-1 flex flex-col min-h-screen">
          <header className="bg-white border-b p-4 flex justify-between items-center sticky top-0 z-10">
            <div className="flex items-center gap-3">
              <button className="md:hidden p-2" onClick={() => setTab(tab)}>
                <div className="space-y-1"><div className="w-5 h-0.5 bg-zinc-600" /><div className="w-5 h-0.5 bg-zinc-600" /><div className="w-5 h-0.5 bg-zinc-600" /></div>
              </button>
              <h1 className="font-bold capitalize flex items-center gap-2">
                {navItems.find(n => n.id === tab) && (() => { const Icon = navItems.find(n => n.id === tab)!.icon; return <Icon size={20} className="text-[#0E9F6E]" />; })()}
                {tab === 'overview' ? 'Dashboard Overview' : tab}
              </h1>
            </div>
            <div className="flex items-center gap-2">
              <div className="relative">
                <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
                <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..." className="pl-8 pr-3 py-1.5 border rounded-lg text-sm w-48" />
              </div>
              <span className="text-[10px] bg-green-100 text-green-700 px-2.5 py-1 rounded-full font-medium">HOM LIVE</span>
            </div>
          </header>

          <div className="md:hidden flex gap-1.5 overflow-x-auto p-3 pb-2">
            {navItems.map(({ id, label, icon: Icon }) => (
              <button key={id} onClick={() => { setTab(id); setShowForm(false); setEditItem(null); }}
                className={`px-3 py-1.5 rounded-full text-xs whitespace-nowrap flex items-center gap-1 ${tab === id ? 'bg-[#0E9F6E] text-white' : 'bg-white border text-zinc-600'}`}>
                <Icon size={12} />{label}
              </button>
            ))}
          </div>

          <div className="p-4 md:p-6 flex-1">

            {/* ===== OVERVIEW ===== */}
            {tab === 'overview' && (
              <div className="space-y-6">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {[
                    { label: 'Total Rooms', value: rooms.length, sub: `${rooms.filter(r => r.status === 'available').length} available`, color: 'bg-blue-50 text-blue-700' },
                    { label: 'Active Bookings', value: bookings.filter(b => b.status === 'checked-in').length, sub: `${bookings.length} total`, color: 'bg-green-50 text-green-700' },
                    { label: 'Diesel Today', value: diesel.filter(d => d.date === today()).reduce((a, d) => a + d.liters, 0) + 'L', sub: `${diesel.length} logs`, color: 'bg-amber-50 text-amber-700' },
                    { label: 'Low Stock', value: inventory.filter(i => i.qty <= i.low).length, sub: `${inventory.length} items`, color: 'bg-red-50 text-red-700' },
                  ].map((c, i) => (
                    <div key={i} className={`rounded-2xl p-5 border bg-white`}>
                      <div className={`text-xs font-bold ${c.color} px-2 py-0.5 rounded-full inline-block`}>{c.label}</div>
                      <div className="text-3xl font-black mt-2">{c.value}</div>
                      <div className="text-xs text-zinc-500 mt-1">{c.sub}</div>
                    </div>
                  ))}
                </div>
                <div className="grid md:grid-cols-2 gap-4">
                  <div className="bg-white rounded-2xl p-5 border">
                    <h3 className="font-bold text-sm flex items-center gap-2"><CalendarCheck size={16} className="text-[#0E9F6E]" /> Recent Bookings</h3>
                    <div className="mt-3 space-y-2">
                      {bookings.slice(0, 5).map(b => (
                        <div key={b.id} className="flex justify-between items-center text-sm py-2 border-b last:border-0">
                          <div><span className="font-medium">{b.guest}</span> <span className="text-zinc-400">Room {b.room}</span></div>
                          <span className={`text-[10px] px-2 py-0.5 rounded-full ${b.status === 'checked-in' ? 'bg-green-100 text-green-700' : b.status === 'cancelled' ? 'bg-red-100 text-red-700' : 'bg-zinc-100 text-zinc-600'}`}>{b.status}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                  <div className="bg-white rounded-2xl p-5 border">
                    <h3 className="font-bold text-sm flex items-center gap-2"><Fuel size={16} className="text-amber-500" /> Diesel Alerts</h3>
                    <div className="mt-3 space-y-2">
                      {diesel.filter(d => d.genHours > 0 && d.liters / d.genHours < 8).length > 0
                        ? diesel.filter(d => d.genHours > 0 && d.liters / d.genHours < 8).map(d => (
                          <div key={d.id} className="flex items-center gap-2 text-sm p-2 bg-red-50 rounded-lg">
                            <AlertTriangle size={14} className="text-red-500" />
                            <span>Theft risk: {(d.liters / d.genHours).toFixed(1)} L/hr on {d.date}</span>
                          </div>
                        ))
                        : <div className="text-sm text-green-600 p-2 bg-green-50 rounded-lg flex items-center gap-2"><CheckCircle size={14} /> No theft alerts</div>
                      }
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ===== BOOKINGS CRUD ===== */}
            {tab === 'bookings' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="font-bold">Bookings ({bookings.length})</h2>
                  <button onClick={() => { setShowForm(true); setEditItem(null); }} className="bg-[#0E9F6E] text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> New Booking</button>
                </div>
                {showForm && (
                  <BookingForm
                    rooms={rooms}
                    initial={editItem}
                    onSave={(b) => {
                      if (editItem) { setBookings(bookings.map(x => x.id === b.id ? b : x)); }
                      else { setBookings([b, ...bookings]); setRooms(rooms.map(r => r.number === b.room ? { ...r, status: 'occupied' as const } : r)); }
                      const msg = bookingConfirmationTemplate(b.guest, b.room, b.checkin);
                      logWhatsApp(b.phone, msg);
                      setShowForm(false); setEditItem(null);
                    }}
                    onCancel={() => { setShowForm(false); setEditItem(null); }}
                  />
                )}
                <div className="bg-white rounded-2xl border overflow-hidden">
                  <div className="divide-y">
                    {bookings.filter(b => b.guest.toLowerCase().includes(search.toLowerCase()) || b.room.includes(search)).map(b => (
                      <div key={b.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                        <div className="flex-1">
                          <div className="font-bold">{b.guest} <span className="text-zinc-400 font-normal">Room {b.room}</span></div>
                          <div className="text-xs text-zinc-500 mt-0.5">{b.checkin} → {b.checkout} • {b.phone} • ₦{b.amount.toLocaleString()}</div>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className={`text-[10px] px-2 py-0.5 rounded-full ${b.status === 'checked-in' ? 'bg-green-100 text-green-700' : b.status === 'confirmed' ? 'bg-blue-100 text-blue-700' : b.status === 'cancelled' ? 'bg-red-100 text-red-700' : 'bg-zinc-100 text-zinc-600'}`}>{b.status}</span>
                          {b.status !== 'checked-out' && b.status !== 'cancelled' && (
                            <>
                              <button onClick={() => { setEditItem(b); setShowForm(true); }} className="p-1.5 hover:bg-zinc-100 rounded-lg" title="Edit"><Edit3 size={14} className="text-zinc-500" /></button>
                              <button onClick={() => { setBookings(bookings.map(x => x.id === b.id ? { ...x, status: 'checked-out' as const } : x)); setRooms(rooms.map(r => r.number === b.room ? { ...r, status: 'available' as const } : r)); }} className="p-1.5 hover:bg-green-50 rounded-lg text-green-600" title="Check Out"><LogOut size={14} /></button>
                              <button onClick={() => { setBookings(bookings.map(x => x.id === b.id ? { ...x, status: 'cancelled' as const } : x)); setRooms(rooms.map(r => r.number === b.room ? { ...r, status: 'available' as const } : r)); }} className="p-1.5 hover:bg-red-50 rounded-lg text-red-500" title="Cancel"><XCircle size={14} /></button>
                            </>
                          )}
                          <button onClick={() => setBookings(bookings.filter(x => x.id !== b.id))} className="p-1.5 hover:bg-red-50 rounded-lg" title="Delete"><Trash2 size={14} className="text-red-400" /></button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ===== ROOMS CRUD ===== */}
            {tab === 'rooms' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="font-bold">Rooms ({rooms.length})</h2>
                  <button onClick={() => { setShowForm(true); setEditItem(null); }} className="bg-[#0E9F6E] text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> Add Room</button>
                </div>
                {showForm && (
                  <RoomForm initial={editItem} onSave={(r) => {
                    if (editItem) setRooms(rooms.map(x => x.id === r.id ? r : x));
                    else setRooms([r, ...rooms]);
                    setShowForm(false); setEditItem(null);
                  }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
                )}
                <div className="grid md:grid-cols-3 gap-3">
                  {rooms.map(r => (
                    <div key={r.id} className="bg-white rounded-2xl p-5 border">
                      <div className="flex justify-between items-start">
                        <div>
                          <div className="font-black text-2xl">{r.number}</div>
                          <div className="text-sm text-zinc-500">{r.type} — ₦{r.price.toLocaleString()}/night</div>
                        </div>
                        <span className={`text-[10px] px-2 py-1 rounded-full font-medium ${r.status === 'available' ? 'bg-green-100 text-green-700' : r.status === 'occupied' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>{r.status}</span>
                      </div>
                      <div className="mt-4 flex gap-2">
                        {(['available', 'occupied', 'maintenance'] as const).map(s => (
                          <button key={s} onClick={() => setRooms(rooms.map(x => x.id === r.id ? { ...x, status: s } : x))}
                            className={`text-[10px] px-2 py-1 rounded-full border ${r.status === s ? 'bg-[#0E9F6E] text-white border-[#0E9F6E]' : 'hover:bg-zinc-50'}`}>{s}</button>
                        ))}
                      </div>
                      <div className="mt-3 flex gap-1.5">
                        <button onClick={() => { setEditItem(r); setShowForm(true); }} className="p-1.5 hover:bg-zinc-100 rounded-lg"><Edit3 size={14} className="text-zinc-500" /></button>
                        <button onClick={() => setRooms(rooms.filter(x => x.id !== r.id))} className="p-1.5 hover:bg-red-50 rounded-lg"><Trash2 size={14} className="text-red-400" /></button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ===== DIESEL CRUD ===== */}
            {tab === 'diesel' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="font-bold">Diesel Logs ({diesel.length})</h2>
                  <button onClick={() => { setShowForm(true); setEditItem(null); }} className="bg-[#0E9F6E] text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> Log Diesel</button>
                </div>
                {showForm && (
                  <DieselForm initial={editItem} onSave={(d) => {
                    if (d.genHours > 0 && d.liters / d.genHours < 8) alert(`THEFT ALERT: ${(d.liters / d.genHours).toFixed(1)} L/hr — below 8L/hr threshold!`);
                    if (editItem) setDiesel(diesel.map(x => x.id === d.id ? d : x));
                    else setDiesel([d, ...diesel]);
                    setShowForm(false); setEditItem(null);
                  }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
                )}
                <div className="bg-white rounded-2xl border overflow-hidden">
                  <div className="divide-y">
                    {diesel.map(d => {
                      const rate = d.genHours > 0 ? d.liters / d.genHours : 0;
                      const theft = d.genHours > 0 && rate < 8;
                      return (
                        <div key={d.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${theft ? 'bg-red-50' : ''}`}>
                          <div className="flex-1">
                            <div className="font-bold flex items-center gap-2">{d.liters}L — {d.supplier} {theft && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> THEFT RISK {rate.toFixed(1)}L/hr</span>}</div>
                            <div className="text-xs text-zinc-500 mt-0.5">{d.date} • {d.genHours}hrs • ₦{d.cost.toLocaleString()} {d.note && `• ${d.note}`}</div>
                          </div>
                          <div className="flex gap-1.5">
                            <button onClick={() => { setEditItem(d); setShowForm(true); }} className="p-1.5 hover:bg-zinc-100 rounded-lg"><Edit3 size={14} className="text-zinc-500" /></button>
                            <button onClick={() => setDiesel(diesel.filter(x => x.id !== d.id))} className="p-1.5 hover:bg-red-50 rounded-lg"><Trash2 size={14} className="text-red-400" /></button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}

            {/* ===== INVENTORY CRUD ===== */}
            {tab === 'inventory' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="font-bold">Inventory ({inventory.length} items)</h2>
                  <button onClick={() => { setShowForm(true); setEditItem(null); }} className="bg-[#0E9F6E] text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> Add Item</button>
                </div>
                {showForm && (
                  <InventoryForm initial={editItem} onSave={(item) => {
                    if (editItem) setInventory(inventory.map(x => x.id === item.id ? item : x));
                    else setInventory([item, ...inventory]);
                    setShowForm(false); setEditItem(null);
                  }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
                )}
                <div className="bg-white rounded-2xl border overflow-hidden">
                  <div className="divide-y">
                    {inventory.filter(i => i.name.toLowerCase().includes(search.toLowerCase())).map(it => (
                      <div key={it.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                        <div className="flex-1">
                          <div className="font-bold flex items-center gap-2">{it.name} {it.qty <= it.low && <span className="bg-red-100 text-red-700 text-[10px] px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> LOW STOCK</span>}</div>
                          <div className="text-xs text-zinc-500 mt-0.5">Qty: {it.qty} • Min: {it.low} • Unit cost: ₦{it.cost.toLocaleString()}</div>
                        </div>
                        <div className="flex items-center gap-2">
                          <button onClick={() => setInventory(inventory.map(x => x.id === it.id ? { ...x, qty: Math.max(0, x.qty - 1) } : x))} className="w-8 h-8 rounded-lg border flex items-center justify-center text-sm font-bold hover:bg-zinc-50">-1</button>
                          <span className="w-10 text-center font-bold text-sm">{it.qty}</span>
                          <button onClick={() => setInventory(inventory.map(x => x.id === it.id ? { ...x, qty: x.qty + 10 } : x))} className="w-8 h-8 rounded-lg bg-[#0E9F6E] text-white flex items-center justify-center text-sm font-bold">+10</button>
                          <button onClick={() => { setEditItem(it); setShowForm(true); }} className="p-1.5 hover:bg-zinc-100 rounded-lg ml-2"><Edit3 size={14} className="text-zinc-500" /></button>
                          <button onClick={() => setInventory(inventory.filter(x => x.id !== it.id))} className="p-1.5 hover:bg-red-50 rounded-lg"><Trash2 size={14} className="text-red-400" /></button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ===== STAFF / HR PAYROLL CRUD ===== */}
            {tab === 'staff' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="font-bold">Staff & Payroll ({staff.length})</h2>
                  <button onClick={() => { setShowForm(true); setEditItem(null); }} className="bg-[#0E9F6E] text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> Add Staff</button>
                </div>
                {showForm && (
                  <StaffForm initial={editItem} onSave={(s) => {
                    if (editItem) setStaff(staff.map(x => x.id === s.id ? s : x));
                    else setStaff([s, ...staff]);
                    setShowForm(false); setEditItem(null);
                  }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
                )}
                <div className="bg-white rounded-2xl border overflow-hidden">
                  <div className="divide-y">
                    {staff.map(s => {
                      const p = paye(s.salary), pe = pension(s.salary), net = s.salary - p - pe;
                      return (
                        <div key={s.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                          <div className="flex-1">
                            <div className="font-bold">{s.name}</div>
                            <div className="text-xs text-zinc-500 mt-0.5">{s.role} • Gross ₦{s.salary.toLocaleString()}</div>
                          </div>
                          <div className="flex items-center gap-4 text-xs">
                            <div className="text-right">
                              <div className="text-zinc-500">PAYE 7%: ₦{p.toLocaleString()}</div>
                              <div className="text-zinc-500">Pension 8%: ₦{pe.toLocaleString()}</div>
                              <div className="font-bold text-[#0E9F6E]">Net: ₦{net.toLocaleString()}</div>
                            </div>
                            <div className="flex flex-col gap-1">
                              <button onClick={async () => {
                                const msg = payslipTemplate(s.name, net);
                                await logWhatsApp('phone', msg);
                                alert(`Payslip sent to ${s.name}: ${msg}`);
                              }} className="bg-green-600 text-white px-3 py-1.5 rounded-lg text-[11px] font-bold flex items-center gap-1"><Send size={10} /> Payslip</button>
                            </div>
                            <div className="flex gap-1">
                              <button onClick={() => { setEditItem(s); setShowForm(true); }} className="p-1.5 hover:bg-zinc-100 rounded-lg"><Edit3 size={14} className="text-zinc-500" /></button>
                              <button onClick={() => setStaff(staff.filter(x => x.id !== s.id))} className="p-1.5 hover:bg-red-50 rounded-lg"><Trash2 size={14} className="text-red-400" /></button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}

            {/* ===== VENDORS & PURCHASE ORDERS CRUD ===== */}
            {tab === 'vendors' && (
              <div className="space-y-6">
                <div className="flex justify-between items-center">
                  <h2 className="font-bold">Vendors & Purchase Orders</h2>
                  <div className="flex gap-2">
                    <button onClick={() => { setShowForm(true); setEditItem({ _type: 'vendor' }); }} className="bg-[#0E9F6E] text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> Add Vendor</button>
                    <button onClick={() => { setShowForm(true); setEditItem({ _type: 'po' }); }} className="bg-amber-500 text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5"><Plus size={14} /> New PO</button>
                  </div>
                </div>
                {showForm && editItem?._type === 'vendor' && (
                  <VendorForm initial={editItem.id ? editItem : null} onSave={(v) => {
                    if (editItem.id) setVendors(vendors.map(x => x.id === v.id ? v : x));
                    else setVendors([v, ...vendors]);
                    setShowForm(false); setEditItem(null);
                  }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
                )}
                {showForm && editItem?._type === 'po' && (
                  <POForm vendors={vendors} initial={editItem.id ? editItem : null} onSave={(po) => {
                    if (editItem.id) setPOs(pos.map(x => x.id === po.id ? po : x));
                    else setPOs([po, ...pos]);
                    setShowForm(false); setEditItem(null);
                  }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
                )}
                <div className="grid md:grid-cols-2 gap-4">
                  <div className="bg-white rounded-2xl border p-5">
                    <h3 className="font-bold text-sm flex items-center gap-2"><Store size={16} className="text-[#0E9F6E]" /> Vendors ({vendors.length})</h3>
                    <div className="mt-3 divide-y">
                      {vendors.map(v => (
                        <div key={v.id} className="py-3 flex justify-between items-center">
                          <div><div className="font-medium text-sm">{v.name}</div><div className="text-xs text-zinc-500">{v.contact} • {v.category}</div></div>
                          <div className="flex gap-1">
                            <button onClick={() => { setEditItem({ ...v, _type: 'vendor' }); setShowForm(true); }} className="p-1 hover:bg-zinc-100 rounded"><Edit3 size={12} /></button>
                            <button onClick={() => { setVendors(vendors.filter(x => x.id !== v.id)); setPOs(pos.filter(x => x.vendorId !== v.id)); }} className="p-1 hover:bg-red-50 rounded"><Trash2 size={12} className="text-red-400" /></button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                  <div className="bg-white rounded-2xl border p-5">
                    <h3 className="font-bold text-sm flex items-center gap-2"><Package size={16} className="text-amber-500" /> Purchase Orders ({pos.length})</h3>
                    <div className="mt-3 divide-y">
                      {pos.map(p => (
                        <div key={p.id} className="py-3 flex justify-between items-center">
                          <div><div className="font-medium text-sm">{p.items}</div><div className="text-xs text-zinc-500">{vendors.find(v => v.id === p.vendorId)?.name || 'Unknown'} • ₦{p.amount.toLocaleString()} • {p.date}</div></div>
                          <div className="flex items-center gap-2">
                            <select value={p.status} onChange={e => setPOs(pos.map(x => x.id === p.id ? { ...x, status: e.target.value as any } : x))} className="text-[10px] border rounded-lg px-2 py-1">
                              <option value="pending">Pending</option><option value="approved">Approved</option><option value="delivered">Delivered</option>
                            </select>
                            <button onClick={() => setPOs(pos.filter(x => x.id !== p.id))} className="p-1 hover:bg-red-50 rounded"><Trash2 size={12} className="text-red-400" /></button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ===== PAYSTACK ===== */}
            {tab === 'paystack' && (
              <div className="bg-white rounded-2xl p-8 border max-w-lg mx-auto text-center">
                <CreditCard size={48} className="mx-auto text-[#0E9F6E] mb-4" />
                <h3 className="font-black text-2xl">Paystack Payments</h3>
                <p className="text-sm text-zinc-500 mt-2">Process payments via Paystack inline checkout.</p>
                <div className="mt-6 space-y-3">
                  <button onClick={() => openPaystack('guest@hom.ng', 1500000)} className="w-full bg-[#0E9F6E] text-white py-3 rounded-xl font-bold">Pay ₦15,000 — Guest Payment</button>
                  <button onClick={() => openPaystack('vendor@hom.ng', 500000)} className="w-full bg-amber-500 text-white py-3 rounded-xl font-bold">Pay ₦5,000 — Vendor Payment</button>
                </div>
                <p className="text-[10px] text-zinc-400 mt-4">Key: {(paystackKey || 'pk_test_7547...').slice(0, 20)}...</p>
              </div>
            )}

            {/* ===== WHATSAPP ===== */}
            {tab === 'whatsapp' && (
              <div className="space-y-4">
                <div className="bg-white rounded-2xl p-6 border">
                  <h3 className="font-black text-xl flex items-center gap-2"><MessageCircle size={20} className="text-green-600" /> WhatsApp Cloud API</h3>
                  <p className="text-sm text-zinc-600 mt-2">Set <code>NEXT_PUBLIC_WHATSAPP_TOKEN</code> and <code>NEXT_PUBLIC_WHATSAPP_PHONE_ID</code> in .env to enable live messaging.</p>
                  <div className="mt-4 grid md:grid-cols-3 gap-3">
                    <div className="bg-green-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{whatsappLog.length}</div><div className="text-xs text-green-700">Messages Sent</div></div>
                    <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{whatsappLog.filter(m => m.msg.includes('booking')).length}</div><div className="text-xs text-zinc-500">Booking Confirms</div></div>
                    <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{whatsappLog.filter(m => m.msg.includes('Payslip') || m.msg.includes('Net')).length}</div><div className="text-xs text-zinc-500">Payslips</div></div>
                  </div>
                </div>
                {whatsappLog.length > 0 && (
                  <div className="bg-white rounded-2xl border overflow-hidden">
                    <div className="p-4 border-b font-bold text-sm">Message Log</div>
                    <div className="divide-y max-h-80 overflow-y-auto">
                      {whatsappLog.map((m, i) => (
                        <div key={i} className="p-3 text-sm">
                          <div className="flex justify-between"><span className="font-medium">{m.to}</span><span className="text-[10px] text-zinc-400">{m.time}</span></div>
                          <div className="text-xs text-zinc-600 mt-0.5">{m.msg}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* ===== BOOKING.COM ===== */}
            {tab === 'bookingcom' && (
              <div className="space-y-4">
                <div className="bg-white rounded-2xl p-6 border">
                  <h3 className="font-black text-xl flex items-center gap-2"><Globe size={20} className="text-blue-600" /> Booking.com Channel Manager</h3>
                  <p className="text-sm text-zinc-600 mt-2">Sync external bookings and prevent overbooking between Booking.com and walk-ins.</p>
                </div>
                <div className="grid md:grid-cols-2 gap-4">
                  <div className="bg-white rounded-2xl border p-5">
                    <h4 className="font-bold text-sm">External Bookings ({externalBookings.length})</h4>
                    <div className="mt-3 divide-y">
                      {externalBookings.map(b => (
                        <div key={b.id} className="py-3 text-sm">
                          <div className="font-medium">{b.guest}</div>
                          <div className="text-xs text-zinc-500">{b.roomType} • {b.checkin} → {b.checkout}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                  <div className="bg-white rounded-2xl border p-5">
                    <h4 className="font-bold text-sm flex items-center gap-2"><AlertTriangle size={14} /> Overbooking Check</h4>
                    <div className="mt-3">
                      {(() => {
                        const result = checkOverbooking(rooms, externalBookings, today());
                        return (
                          <div className="space-y-2 text-sm">
                            <div>Available rooms: <span className="font-bold">{result.available}</span></div>
                            <div>Externally occupied: <span className="font-bold">{result.occupied}</span></div>
                            <div className={`p-3 rounded-xl font-medium ${result.risk ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'}`}>
                              {result.risk ? 'HIGH RISK — Overbooking detected!' : 'SAFE — Can accept new bookings'}
                            </div>
                          </div>
                        );
                      })()}
                    </div>
                  </div>
                </div>
              </div>
            )}

          </div>
        </div>
      </main>
    </>
  );
}

/* ===== FORM COMPONENTS ===== */

function BookingForm({ rooms, initial, onSave, onCancel }: { rooms: Room[]; initial: any; onSave: (b: Booking) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial && initial.id ? { guest: initial.guest, phone: initial.phone, room: initial.room, checkin: initial.checkin, checkout: initial.checkout } : { guest: '', phone: '', room: rooms.find(r => r.status === 'available')?.number || '', checkin: '', checkout: '' });
  const available = initial?.id ? rooms.filter(r => r.status === 'available' || r.number === initial.room) : rooms.filter(r => r.status === 'available');
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Booking' : 'New Booking'}</h3>
      <div className="grid md:grid-cols-2 gap-3">
        <input value={f.guest} onChange={e => setF({ ...f, guest: e.target.value })} placeholder="Guest name" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input value={f.phone} onChange={e => setF({ ...f, phone: e.target.value })} placeholder="Phone +234..." className="border rounded-xl px-4 py-2.5 text-sm" />
        <select value={f.room} onChange={e => setF({ ...f, room: e.target.value })} className="border rounded-xl px-4 py-2.5 text-sm">{available.map(r => <option key={r.id} value={r.number}>{r.number} — {r.type} ₦{r.price.toLocaleString()}</option>)}</select>
        <div className="flex gap-2">
          <input type="date" value={f.checkin} onChange={e => setF({ ...f, checkin: e.target.value })} className="border rounded-xl px-3 py-2 text-sm flex-1" />
          <input type="date" value={f.checkout} onChange={e => setF({ ...f, checkout: e.target.value })} className="border rounded-xl px-3 py-2 text-sm flex-1" />
        </div>
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.guest) return alert('Guest name required'); const room = rooms.find(r => r.number === f.room); if (!room) return; onSave({ id: initial?.id || uid(), ...f, status: initial?.status || 'confirmed', amount: room.price * Math.max(1, Math.ceil((new Date(f.checkout).getTime() - new Date(f.checkin).getTime()) / 86400000)) }); }} className="bg-[#0E9F6E] text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Create Booking'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}

function RoomForm({ initial, onSave, onCancel }: { initial: any; onSave: (r: Room) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial?.id ? { number: initial.number, type: initial.type, price: String(initial.price) } : { number: '', type: 'Deluxe', price: '' });
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Room' : 'Add Room'}</h3>
      <div className="grid md:grid-cols-3 gap-3">
        <input value={f.number} onChange={e => setF({ ...f, number: e.target.value })} placeholder="Room number" className="border rounded-xl px-4 py-2.5 text-sm" />
        <select value={f.type} onChange={e => setF({ ...f, type: e.target.value })} className="border rounded-xl px-4 py-2.5 text-sm"><option>Standard</option><option>Deluxe</option><option>Executive</option><option>Suite</option></select>
        <input type="number" value={f.price} onChange={e => setF({ ...f, price: e.target.value })} placeholder="Price per night" className="border rounded-xl px-4 py-2.5 text-sm" />
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.number || !f.price) return alert('All fields required'); onSave({ id: initial?.id || uid(), number: f.number, type: f.type, status: initial?.status || 'available', price: Number(f.price) }); }} className="bg-[#0E9F6E] text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Add Room'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}

function DieselForm({ initial, onSave, onCancel }: { initial: any; onSave: (d: Diesel) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial?.id ? { liters: String(initial.liters), cost: String(initial.cost), supplier: initial.supplier, genHours: String(initial.genHours), note: initial.note } : { liters: '', cost: '', supplier: '', genHours: '', note: '' });
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Diesel Log' : 'Log Diesel'}</h3>
      <div className="grid md:grid-cols-3 gap-3">
        <input type="number" value={f.liters} onChange={e => setF({ ...f, liters: e.target.value })} placeholder="Liters" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.cost} onChange={e => setF({ ...f, cost: e.target.value })} placeholder="Cost (₦)" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input value={f.supplier} onChange={e => setF({ ...f, supplier: e.target.value })} placeholder="Supplier" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.genHours} onChange={e => setF({ ...f, genHours: e.target.value })} placeholder="Generator hours" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input value={f.note} onChange={e => setF({ ...f, note: e.target.value })} placeholder="Note" className="border rounded-xl px-4 py-2.5 text-sm" />
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.liters || !f.cost || !f.supplier) return alert('Liters, cost, and supplier required'); onSave({ id: initial?.id || uid(), date: initial?.date || today(), liters: Number(f.liters), cost: Number(f.cost), supplier: f.supplier, genHours: Number(f.genHours), note: f.note }); }} className="bg-[#0E9F6E] text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Add Log'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}

function InventoryForm({ initial, onSave, onCancel }: { initial: any; onSave: (item: InventoryItem) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial?.id ? { name: initial.name, qty: String(initial.qty), low: String(initial.low), cost: String(initial.cost) } : { name: '', qty: '', low: '', cost: '' });
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Item' : 'Add Item'}</h3>
      <div className="grid md:grid-cols-4 gap-3">
        <input value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Item name" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.qty} onChange={e => setF({ ...f, qty: e.target.value })} placeholder="Quantity" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.low} onChange={e => setF({ ...f, low: e.target.value })} placeholder="Low stock threshold" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.cost} onChange={e => setF({ ...f, cost: e.target.value })} placeholder="Unit cost (₦)" className="border rounded-xl px-4 py-2.5 text-sm" />
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.name || !f.qty) return alert('Name and quantity required'); onSave({ id: initial?.id || uid(), name: f.name, qty: Number(f.qty), low: Number(f.low) || 5, cost: Number(f.cost) || 0 }); }} className="bg-[#0E9F6E] text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Add Item'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}

function StaffForm({ initial, onSave, onCancel }: { initial: any; onSave: (s: Staff) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial?.id ? { name: initial.name, role: initial.role, salary: String(initial.salary) } : { name: '', role: '', salary: '' });
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Staff' : 'Add Staff'}</h3>
      <div className="grid md:grid-cols-3 gap-3">
        <input value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Full name" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input value={f.role} onChange={e => setF({ ...f, role: e.target.value })} placeholder="Role (e.g. Front Desk)" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.salary} onChange={e => setF({ ...f, salary: e.target.value })} placeholder="Monthly salary (₦)" className="border rounded-xl px-4 py-2.5 text-sm" />
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.name || !f.role || !f.salary) return alert('All fields required'); onSave({ id: initial?.id || uid(), name: f.name, role: f.role, salary: Number(f.salary) }); }} className="bg-[#0E9F6E] text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Add Staff'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}

function VendorForm({ initial, onSave, onCancel }: { initial: any; onSave: (v: Vendor) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial?.id ? { name: initial.name, contact: initial.contact, category: initial.category } : { name: '', contact: '', category: '' });
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Vendor' : 'Add Vendor'}</h3>
      <div className="grid md:grid-cols-3 gap-3">
        <input value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Vendor name" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="Contact" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input value={f.category} onChange={e => setF({ ...f, category: e.target.value })} placeholder="Category (Fuel, Cleaning...)" className="border rounded-xl px-4 py-2.5 text-sm" />
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.name) return alert('Vendor name required'); onSave({ id: initial?.id || uid(), name: f.name, contact: f.contact, category: f.category }); }} className="bg-[#0E9F6E] text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Add Vendor'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}

function POForm({ vendors, initial, onSave, onCancel }: { vendors: Vendor[]; initial: any; onSave: (po: PurchaseOrder) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial?.id ? { vendorId: initial.vendorId, items: initial.items, amount: String(initial.amount) } : { vendorId: vendors[0]?.id || '', items: '', amount: '' });
  return (
    <div className="bg-white rounded-2xl p-6 border">
      <h3 className="font-bold mb-4">{initial?.id ? 'Edit Purchase Order' : 'New Purchase Order'}</h3>
      <div className="grid md:grid-cols-3 gap-3">
        <select value={f.vendorId} onChange={e => setF({ ...f, vendorId: e.target.value })} className="border rounded-xl px-4 py-2.5 text-sm">{vendors.map(v => <option key={v.id} value={v.id}>{v.name}</option>)}</select>
        <input value={f.items} onChange={e => setF({ ...f, items: e.target.value })} placeholder="Items description" className="border rounded-xl px-4 py-2.5 text-sm" />
        <input type="number" value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount (₦)" className="border rounded-xl px-4 py-2.5 text-sm" />
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={() => { if (!f.items || !f.amount) return alert('Items and amount required'); onSave({ id: initial?.id || uid(), vendorId: f.vendorId, items: f.items, amount: Number(f.amount), date: today(), status: 'pending' }); }} className="bg-amber-500 text-white px-6 py-2.5 rounded-xl text-sm font-bold">{initial?.id ? 'Update' : 'Create PO'}</button>
        <button onClick={onCancel} className="px-4 py-2.5 rounded-xl text-sm border">Cancel</button>
      </div>
    </div>
  );
}
