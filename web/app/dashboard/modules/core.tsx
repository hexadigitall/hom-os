'use client';

import { useState } from 'react';
import {
  CalendarCheck, Fuel, Plus, Trash2, Edit3, LogOut, XCircle, AlertTriangle,
  Send, Package, Store,
} from 'lucide-react';
import {
  Room, Booking, Diesel, InventoryItem, Staff, Vendor, PurchaseOrder,
} from '@/lib/types';
import {
  seedRooms, seedBookings, seedDiesel, seedInventory, seedStaff, seedVendors, seedPOs,
} from '@/lib/seed';

import { useScopedCollection } from '@/lib/scoped';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { hasPermission, PERMISSIONS, tagFor, type Department } from '@/lib/rbac';
import { today, addDays, uid, naira, fmtDate, daysBetween } from '@/lib/format';
import { sendWhatsApp, bookingConfirmationTemplate, payslipTemplate } from '@/lib/whatsapp';
import { appendWhatsAppLog } from '@/lib/whatsapplog';
import {
  Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput,
  NumberInput, DateInput, Select, FormCard, EmptyState, FieldGrid, paye, pension, netPay,
} from '../ui';

export function OverviewModule() {
  const { session } = useAuth();
  const rooms = useSyncedCollection<Room>('rooms', 'hom_rooms', seedRooms, session);
  const bookings = useScopedCollection<Booking>('hom_bookings', seedBookings, session);
  const diesel = useScopedCollection<Diesel>('hom_diesel', seedDiesel, session);
  const inventory = useSyncedCollection<InventoryItem>('inventory', 'hom_inventory', seedInventory, session);

  const t = today();
  const dieselToday = diesel.items.filter(d => d.date === t).reduce((a, d) => a + d.liters, 0);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Total Rooms" value={rooms.items.length} sub={`${rooms.items.filter(r => r.status === 'available').length} available`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Active Bookings" value={bookings.items.filter(b => b.status === 'checked-in').length} sub={`${bookings.items.length} total`} color="bg-green-50 text-green-700" />
        <MetricCard label="Diesel Today" value={`${dieselToday}L`} sub={`${diesel.items.length} logs`} color="bg-amber-50 text-amber-700" />
        <MetricCard label="Low Stock" value={inventory.items.filter(i => i.qty <= i.low).length} sub={`${inventory.items.length} items`} color="bg-red-50 text-red-700" />
      </div>
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="p-5">
          <h3 className="font-bold text-sm flex items-center gap-2"><CalendarCheck size={16} className="text-hom-primary" /> Recent Bookings</h3>
          <div className="mt-3 space-y-2">
            {bookings.items.slice(0, 5).map(b => (
              <div key={b.id} className="flex justify-between items-center text-sm py-2 border-b last:border-0">
                <div className="min-w-0"><span className="font-medium truncate block">{b.guest}</span> <span className="text-zinc-400 text-xs">Room {b.room}</span></div>
                <StatusChip status={b.status} />
              </div>
            ))}
          </div>
        </Card>
        <Card className="p-5">
          <h3 className="font-bold text-sm flex items-center gap-2"><Fuel size={16} className="text-amber-500" /> Diesel Alerts</h3>
          <div className="mt-3 space-y-2">
            {diesel.items.filter(d => d.genHours > 0 && d.liters / d.genHours < 8).length > 0
              ? diesel.items.filter(d => d.genHours > 0 && d.liters / d.genHours < 8).map(d => (
                <div key={d.id} className="flex items-center gap-2 text-sm p-2 bg-red-50 rounded-lg">
                  <AlertTriangle size={14} className="text-red-500" />
                  <span>Theft risk: {(d.liters / d.genHours).toFixed(1)} L/hr on {fmtDate(d.date)}</span>
                </div>
              ))
              : <div className="text-sm text-green-600 p-2 bg-green-50 rounded-lg flex items-center gap-2"><span>✓</span> No theft alerts</div>
            }
          </div>
        </Card>
      </div>
    </div>
  );
}

// ─── Bookings ────────────────────────────────────────────────────────────────

export function BookingsModule() {
  const { session } = useAuth();
  const bookings = useSyncedCollection<Booking>('bookings', 'hom_bookings', seedBookings, session);
  const rooms = useSyncedCollection<Room>('rooms', 'hom_rooms', seedRooms, session);
  const depts = tagFor(session, 'reception');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<Booking | null>(null);
  const [search, setSearch] = useState('');

  return (
    <div className="space-y-4">
      <SectionHeader title={`Bookings (${bookings.items.length})`}>
        <TextInput value={search} onChange={e => setSearch(e.target.value)} placeholder="Search guest/room..." className="!py-1.5 w-full sm:!w-48" />
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Booking</Btn>
      </SectionHeader>
      {showForm && (
        <BookingForm rooms={rooms.items} initial={editItem} depts={depts}
          onSave={(b) => {
            if (editItem) bookings.replace(b.id, b);
            else { bookings.add(b); rooms.update(rooms.items.find(r => r.number === b.room)?.id || '', { status: 'occupied' }); }
            const msg = bookingConfirmationTemplate(b.guest, b.room, b.checkin);
            sendWhatsApp(b.phone, msg); appendWhatsAppLog(b.phone, msg);
            setShowForm(false); setEditItem(null);
          }}
          onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {bookings.items.filter(b => b.guest.toLowerCase().includes(search.toLowerCase()) || b.room.includes(search)).map(b => (
            <div key={b.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold">{b.guest} <span className="text-zinc-400 font-normal">Room {b.room}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(b.checkin)} → {fmtDate(b.checkout)} • {b.phone} • {naira(b.amount)}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={b.status} />
                {b.status !== 'checked-out' && b.status !== 'cancelled' && (
                  <>
                    <IconBtn onClick={() => { setEditItem(b); setShowForm(true); }} title="Edit"><Edit3 size={14} /></IconBtn>
                    <IconBtn tone="green" onClick={() => { bookings.update(b.id, { status: 'checked-out' }); rooms.update(rooms.items.find(r => r.number === b.room)?.id || '', { status: 'available' }); }} title="Check Out"><LogOut size={14} /></IconBtn>
                    <IconBtn tone="red" onClick={() => { bookings.update(b.id, { status: 'cancelled' }); rooms.update(rooms.items.find(r => r.number === b.room)?.id || '', { status: 'available' }); }} title="Cancel"><XCircle size={14} /></IconBtn>
                  </>
                )}
                <IconBtn tone="red" onClick={() => bookings.remove(b.id)} title="Delete"><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {bookings.items.length === 0 && <EmptyState text="No bookings yet" />}
        </div>
      </Card>
    </div>
  );
}

function BookingForm({ rooms, initial, depts, onSave, onCancel }: { rooms: Room[]; initial: Booking | null; depts: Department[]; onSave: (b: Booking) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { guest: initial.guest, phone: initial.phone, room: initial.room, checkin: initial.checkin, checkout: initial.checkout }
    : { guest: '', phone: '', room: rooms.find(r => r.status === 'available')?.number || '', checkin: today(), checkout: addDays(today(), 1) });
  const available = initial ? rooms.filter(r => r.status === 'available' || r.number === initial.room) : rooms.filter(r => r.status === 'available');
  return (
    <FormCard title={initial ? 'Edit Booking' : 'New Booking'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Guest name"><TextInput value={f.guest} onChange={e => setF({ ...f, guest: e.target.value })} placeholder="Guest name" /></Field>
        <Field label="Phone"><TextInput value={f.phone} onChange={e => setF({ ...f, phone: e.target.value })} placeholder="Phone +234..." /></Field>
        <Field label="Room">
          <Select value={f.room} onChange={e => setF({ ...f, room: e.target.value })}>
            {available.map(r => <option key={r.id} value={r.number}>{r.number} — {r.type} {naira(r.price)}</option>)}
          </Select>
        </Field>
        <div className="flex gap-2">
          <Field label="Check-in"><DateInput value={f.checkin} onChange={e => setF({ ...f, checkin: e.target.value })} /></Field>
          <Field label="Check-out"><DateInput value={f.checkout} onChange={e => setF({ ...f, checkout: e.target.value })} /></Field>
        </div>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => {
          if (!f.guest) return alert('Guest name required');
          const room = rooms.find(r => r.number === f.room); if (!room) return;
          onSave({
            id: initial?.id || uid('b'), ...f,
            status: initial?.status || 'confirmed',
            amount: room.price * Math.max(1, daysBetween(f.checkin, f.checkout) || 1),
            departments: initial?.departments || depts,
          });
        }}>{initial ? 'Update' : 'Create Booking'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Rooms ───────────────────────────────────────────────────────────────────

export function RoomsModule() {
  const { session } = useAuth();
  const rooms = useSyncedCollection<Room>('rooms', 'hom_rooms', seedRooms, session);
  const depts = tagFor(session, 'reception');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<Room | null>(null);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Rooms (${rooms.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Room</Btn>
      </SectionHeader>
      {showForm && (
        <RoomForm initial={editItem} depts={depts} onSave={(r) => {
          if (editItem) rooms.replace(r.id, r); else rooms.add(r);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <div className="grid md:grid-cols-3 gap-3">
        {rooms.items.map(r => (
          <Card key={r.id} className="p-5">
            <div className="flex justify-between items-start">
              <div>
                <div className="font-black text-2xl">{r.number}</div>
                <div className="text-sm text-zinc-500">{r.type} — {naira(r.price)}/night</div>
              </div>
              <StatusChip status={r.status} />
            </div>
            <div className="mt-4 flex gap-2 flex-wrap">
              {(['available', 'occupied', 'maintenance'] as const).map(s => (
                <button key={s} onClick={() => rooms.update(r.id, { status: s })}
                  className={`text-[10px] px-2 py-1 rounded-full border ${r.status === s ? 'bg-hom-primary text-white border-hom-primary' : 'hover:bg-zinc-50'}`}>{s}</button>
              ))}
            </div>
            <div className="mt-3 flex gap-1.5">
              <IconBtn onClick={() => { setEditItem(r); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
              <IconBtn tone="red" onClick={() => rooms.remove(r.id)}><Trash2 size={14} /></IconBtn>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

function RoomForm({ initial, depts, onSave, onCancel }: { initial: Room | null; depts: Department[]; onSave: (r: Room) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { number: initial.number, type: initial.type, price: String(initial.price) } : { number: '', type: 'Deluxe', price: '' });
  return (
    <FormCard title={initial ? 'Edit Room' : 'Add Room'} onCancel={onCancel}>
      <div className="grid md:grid-cols-3 gap-3">
        <Field label="Room number"><TextInput value={f.number} onChange={e => setF({ ...f, number: e.target.value })} placeholder="Room number" /></Field>
        <Field label="Type">
          <Select value={f.type} onChange={e => setF({ ...f, type: e.target.value })}>
            <option>Standard</option><option>Deluxe</option><option>Executive</option><option>Suite</option>
          </Select>
        </Field>
        <Field label="Price per night"><NumberInput value={f.price} onChange={e => setF({ ...f, price: e.target.value })} placeholder="Price per night" /></Field>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.number || !f.price) return alert('All fields required'); onSave({ id: initial?.id || uid('r'), number: f.number, type: f.type, status: initial?.status || 'available', price: Number(f.price), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Room'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Diesel / Fuel ───────────────────────────────────────────────────────────

export function DieselModule() {
  const { session } = useAuth();
  const diesel = useScopedCollection<Diesel>('hom_diesel', seedDiesel, session);
  const depts = tagFor(session, 'engineering');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<Diesel | null>(null);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Diesel Logs (${diesel.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Log Diesel</Btn>
      </SectionHeader>
      {showForm && (
        <DieselForm initial={editItem} depts={depts} onSave={(d) => {
          if (d.genHours > 0 && d.liters / d.genHours < 8) alert(`THEFT ALERT: ${(d.liters / d.genHours).toFixed(1)} L/hr — below 8L/hr threshold!`);
          if (editItem) diesel.replace(d.id, d); else diesel.add(d);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {diesel.items.map(d => {
            const rate = d.genHours > 0 ? d.liters / d.genHours : 0;
            const theft = d.genHours > 0 && rate < 8;
            return (
              <div key={d.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${theft ? 'bg-red-50' : ''}`}>
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">{d.liters}L — {d.supplier} {theft && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> THEFT RISK {rate.toFixed(1)}L/hr</span>}</div>
                  <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(d.date)} • {d.genHours}hrs • {naira(d.cost)} {d.note && `• ${d.note}`}</div>
                </div>
                <div className="flex gap-1.5">
                  <IconBtn onClick={() => { setEditItem(d); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => diesel.remove(d.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {diesel.items.length === 0 && <EmptyState text="No diesel logs yet" />}
        </div>
      </Card>
    </div>
  );
}

function DieselForm({ initial, depts, onSave, onCancel }: { initial: Diesel | null; depts: Department[]; onSave: (d: Diesel) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { liters: String(initial.liters), cost: String(initial.cost), supplier: initial.supplier, genHours: String(initial.genHours), note: initial.note }
    : { liters: '', cost: '', supplier: '', genHours: '', note: '' });
  return (
    <FormCard title={initial ? 'Edit Diesel Log' : 'Log Diesel'} onCancel={onCancel}>
      <div className="grid md:grid-cols-3 gap-3">
        <Field label="Liters"><NumberInput value={f.liters} onChange={e => setF({ ...f, liters: e.target.value })} placeholder="Liters" /></Field>
        <Field label="Cost (₦)"><NumberInput value={f.cost} onChange={e => setF({ ...f, cost: e.target.value })} placeholder="Cost (₦)" /></Field>
        <Field label="Supplier"><TextInput value={f.supplier} onChange={e => setF({ ...f, supplier: e.target.value })} placeholder="Supplier" /></Field>
        <Field label="Generator hours"><NumberInput value={f.genHours} onChange={e => setF({ ...f, genHours: e.target.value })} placeholder="Generator hours" /></Field>
        <Field label="Note"><TextInput value={f.note} onChange={e => setF({ ...f, note: e.target.value })} placeholder="Note" /></Field>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.liters || !f.cost || !f.supplier) return alert('Liters, cost, and supplier required'); onSave({ id: initial?.id || uid('d'), date: initial?.date || today(), liters: Number(f.liters), cost: Number(f.cost), supplier: f.supplier, genHours: Number(f.genHours) || 0, note: f.note, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Log'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Inventory ───────────────────────────────────────────────────────────────

export function InventoryModule() {
  const { session } = useAuth();
  const inventory = useSyncedCollection<InventoryItem>('inventory', 'hom_inventory', seedInventory, session);
  const depts = tagFor(session, 'housekeeping');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<InventoryItem | null>(null);
  const [search, setSearch] = useState('');

  return (
    <div className="space-y-4">
      <SectionHeader title={`Inventory (${inventory.items.length} items)`}>
        <TextInput value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..." className="!py-1.5 w-full sm:!w-48" />
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Item</Btn>
      </SectionHeader>
      {showForm && (
        <InventoryForm initial={editItem} depts={depts} onSave={(item) => {
          if (editItem) inventory.replace(item.id, item); else inventory.add(item);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {inventory.items.filter(i => i.name.toLowerCase().includes(search.toLowerCase())).map(it => (
            <div key={it.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">{it.name} {it.qty <= it.low && <span className="bg-red-100 text-red-700 text-[10px] px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> LOW STOCK</span>}</div>
                <div className="text-xs text-zinc-500 mt-0.5">Qty: {it.qty} • Min: {it.low} • Unit cost: {naira(it.cost)}</div>
              </div>
              <div className="flex items-center gap-2">
                <button onClick={() => inventory.update(it.id, { qty: Math.max(0, it.qty - 1) })} className="w-8 h-8 rounded-lg border flex items-center justify-center text-sm font-bold hover:bg-zinc-50">-1</button>
                <span className="w-10 text-center font-bold text-sm">{it.qty}</span>
                <button onClick={() => inventory.update(it.id, { qty: it.qty + 10 })} className="w-8 h-8 rounded-lg bg-hom-primary text-white flex items-center justify-center text-sm font-bold">+10</button>
                <IconBtn onClick={() => { setEditItem(it); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => inventory.remove(it.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {inventory.items.length === 0 && <EmptyState text="No inventory items yet" />}
        </div>
      </Card>
    </div>
  );
}

function InventoryForm({ initial, depts, onSave, onCancel }: { initial: InventoryItem | null; depts: Department[]; onSave: (i: InventoryItem) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { name: initial.name, qty: String(initial.qty), low: String(initial.low), cost: String(initial.cost) } : { name: '', qty: '', low: '', cost: '' });
  return (
    <FormCard title={initial ? 'Edit Item' : 'Add Item'} onCancel={onCancel}>
      <div className="grid md:grid-cols-4 gap-3">
        <Field label="Item name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Item name" /></Field>
        <Field label="Quantity"><NumberInput value={f.qty} onChange={e => setF({ ...f, qty: e.target.value })} placeholder="Quantity" /></Field>
        <Field label="Low stock threshold"><NumberInput value={f.low} onChange={e => setF({ ...f, low: e.target.value })} placeholder="Low stock threshold" /></Field>
        <Field label="Unit cost (₦)"><NumberInput value={f.cost} onChange={e => setF({ ...f, cost: e.target.value })} placeholder="Unit cost (₦)" /></Field>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.name || !f.qty) return alert('Name and quantity required'); onSave({ id: initial?.id || uid('i'), name: f.name, qty: Number(f.qty), low: Number(f.low) || 5, cost: Number(f.cost) || 0, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Item'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Staff / HR Payroll ──────────────────────────────────────────────────────

export function StaffModule() {
  const { session } = useAuth();
  const staff = useSyncedCollection<Staff>('staff', 'hom_staff', seedStaff, session);
  const depts = tagFor(session, 'humanResources');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<Staff | null>(null);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Staff & Payroll (${staff.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Staff</Btn>
      </SectionHeader>
      {showForm && (
        <StaffForm initial={editItem} depts={depts} onSave={(s) => {
          if (editItem) staff.replace(s.id, s); else staff.add(s);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {staff.items.map(s => {
            const p = paye(s.salary), pe = pension(s.salary), net = netPay(s.salary);
            return (
              <div key={s.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-bold">{s.name}</div>
                  <div className="text-xs text-zinc-500 mt-0.5">{s.role} • Gross {naira(s.salary)}</div>
                </div>
                <div className="flex items-center gap-4 text-xs flex-wrap">
                  <div className="text-right">
                    <div className="text-zinc-500">PAYE 7%: {naira(p)}</div>
                    <div className="text-zinc-500">Pension 8%: {naira(pe)}</div>
                    <div className="font-bold text-hom-primary">Net: {naira(net)}</div>
                  </div>
                  <Btn color="green" className="!px-3 !py-1.5 !text-[11px]" onClick={async () => {
                    const msg = payslipTemplate(s.name, net);
                    await sendWhatsApp('phone', msg);
                    appendWhatsAppLog('phone', msg);
                    alert(`Payslip sent to ${s.name}: ${msg}`);
                  }}><Send size={10} /> Payslip</Btn>
                  <div className="flex gap-1">
                    <IconBtn onClick={() => { setEditItem(s); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                    <IconBtn tone="red" onClick={() => staff.remove(s.id)}><Trash2 size={14} /></IconBtn>
                  </div>
                </div>
              </div>
            );
          })}
          {staff.items.length === 0 && <EmptyState text="No staff yet" />}
        </div>
      </Card>
    </div>
  );
}

function StaffForm({ initial, depts, onSave, onCancel }: { initial: Staff | null; depts: Department[]; onSave: (s: Staff) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { name: initial.name, role: initial.role, salary: String(initial.salary) } : { name: '', role: '', salary: '' });
  return (
    <FormCard title={initial ? 'Edit Staff' : 'Add Staff'} onCancel={onCancel}>
      <div className="grid md:grid-cols-3 gap-3">
        <Field label="Full name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Full name" /></Field>
        <Field label="Role"><TextInput value={f.role} onChange={e => setF({ ...f, role: e.target.value })} placeholder="Role (e.g. Front Desk)" /></Field>
        <Field label="Monthly salary (₦)"><NumberInput value={f.salary} onChange={e => setF({ ...f, salary: e.target.value })} placeholder="Monthly salary (₦)" /></Field>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.name || !f.role || !f.salary) return alert('All fields required'); onSave({ id: initial?.id || uid('s'), name: f.name, role: f.role, salary: Number(f.salary), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Staff'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Vendors & Purchase Orders ───────────────────────────────────────────────

export function VendorsModule() {
  const { session } = useAuth();
  const canManageVendors = hasPermission(session, PERMISSIONS.manageVendors);
  const canManagePOs = hasPermission(session, PERMISSIONS.managePurchaseOrders);
  const depts = tagFor(session, 'procurement');
  const vendors = useSyncedCollection<Vendor>('vendors', 'hom_vendors', seedVendors, session);
  const pos = useSyncedCollection<PurchaseOrder>('purchase_orders', 'hom_purchase_orders', seedPOs, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<any>(null);

  return (
    <div className="space-y-6">
      <SectionHeader title="Vendors & Purchase Orders">
        {canManageVendors && <Btn onClick={() => { setShowForm(true); setEditItem({ _type: 'vendor' }); }}><Plus size={14} /> Add Vendor</Btn>}
        {canManagePOs && <Btn color="amber" onClick={() => { setShowForm(true); setEditItem({ _type: 'po' }); }}><Plus size={14} /> New PO</Btn>}
      </SectionHeader>
      {showForm && editItem?._type === 'vendor' && (
        <VendorForm initial={editItem.id ? editItem : null} depts={depts} onSave={(v) => {
          if (editItem.id) vendors.replace(v.id, v); else vendors.add(v);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      {showForm && editItem?._type === 'po' && (
        <POForm vendors={vendors.items} initial={editItem.id ? editItem : null} depts={depts} onSave={(po) => {
          if (editItem.id) pos.replace(po.id, po); else pos.add(po);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="p-5">
          <h3 className="font-bold text-sm flex items-center gap-2"><Store size={16} className="text-hom-primary" /> Vendors ({vendors.items.length})</h3>
          <div className="mt-3 divide-y">
            {vendors.items.map(v => (
              <div key={v.id} className="py-3 flex justify-between items-center">
                <div className="min-w-0"><div className="font-medium text-sm truncate">{v.name}</div><div className="text-xs text-zinc-500">{v.contact} • {v.category}</div></div>
                <div className="flex gap-1">
                  {canManageVendors && <IconBtn onClick={() => { setEditItem({ ...v, _type: 'vendor' }); setShowForm(true); }}><Edit3 size={12} /></IconBtn>}
                  {canManageVendors && <IconBtn tone="red" onClick={() => { vendors.remove(v.id); pos.items.filter(p => p.vendorId === v.id).forEach(p => pos.remove(p.id)); }}><Trash2 size={12} /></IconBtn>}
                </div>
              </div>
            ))}
          </div>
        </Card>
        <Card className="p-5">
          <h3 className="font-bold text-sm flex items-center gap-2"><Package size={16} className="text-amber-500" /> Purchase Orders ({pos.items.length})</h3>
          <div className="mt-3 divide-y">
            {pos.items.map(p => {
              const next = p.status === 'pending' ? 'approved' : p.status === 'approved' ? 'delivered' : null;
              return (
                <div key={p.id} className="py-3 flex justify-between items-center">
                  <div className="min-w-0"><div className="font-medium text-sm truncate">{p.items}</div><div className="text-xs text-zinc-500">{vendors.items.find(v => v.id === p.vendorId)?.name || 'Unknown'} • {naira(p.amount)} • {fmtDate(p.date)}</div></div>
                  <div className="flex items-center gap-2">
                    <StatusChip status={p.status} />
                    {canManagePOs && next && (
                      <Btn color="outline" className="!px-2.5 !py-1 !text-[10px]" onClick={() => pos.update(p.id, { status: next })}>Mark {next[0].toUpperCase() + next.slice(1)}</Btn>
                    )}
                    {canManagePOs && <IconBtn onClick={() => { setEditItem({ ...p, _type: 'po' }); setShowForm(true); }}><Edit3 size={12} /></IconBtn>}
                    {canManagePOs && <IconBtn tone="red" onClick={() => pos.remove(p.id)}><Trash2 size={12} /></IconBtn>}
                  </div>
                </div>
              );
            })}
            {pos.items.length === 0 && <EmptyState text="No purchase orders" />}
          </div>
        </Card>
      </div>
    </div>
  );
}

function VendorForm({ initial, depts, onSave, onCancel }: { initial: Vendor | null; depts: Department[]; onSave: (v: Vendor) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { name: initial.name, contact: initial.contact, category: initial.category } : { name: '', contact: '', category: '' });
  return (
    <FormCard title={initial ? 'Edit Vendor' : 'Add Vendor'} onCancel={onCancel}>
      <div className="grid md:grid-cols-3 gap-3">
        <Field label="Vendor name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Vendor name" /></Field>
        <Field label="Contact"><TextInput value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="Contact" /></Field>
        <Field label="Category"><TextInput value={f.category} onChange={e => setF({ ...f, category: e.target.value })} placeholder="Category (Fuel, Cleaning...)" /></Field>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.name) return alert('Vendor name required'); onSave({ id: initial?.id || uid('v'), name: f.name, contact: f.contact, category: f.category, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Vendor'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

function POForm({ vendors, initial, depts, onSave, onCancel }: { vendors: Vendor[]; initial: PurchaseOrder | null; depts: Department[]; onSave: (po: PurchaseOrder) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial ? { vendorId: initial.vendorId, items: initial.items, amount: String(initial.amount) } : { vendorId: vendors[0]?.id || '', items: '', amount: '' });
  return (
    <FormCard title={initial ? 'Edit Purchase Order' : 'New Purchase Order'} onCancel={onCancel}>
      <div className="grid md:grid-cols-3 gap-3">
        <Field label="Vendor">
          <Select value={f.vendorId} onChange={e => setF({ ...f, vendorId: e.target.value })}>
            {vendors.map(v => <option key={v.id} value={v.id}>{v.name}</option>)}
          </Select>
        </Field>
        <Field label="Items description"><TextInput value={f.items} onChange={e => setF({ ...f, items: e.target.value })} placeholder="Items description" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount (₦)" /></Field>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn color="amber" onClick={() => { if (!f.items || !f.amount) return alert('Items and amount required'); onSave({ id: initial?.id || uid('po'), vendorId: f.vendorId, items: f.items, amount: Number(f.amount), date: today(), status: initial?.status || 'pending', departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Create PO'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
