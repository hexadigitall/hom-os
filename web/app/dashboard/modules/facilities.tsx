'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Dumbbell, Waves, ShoppingBag, CalendarClock, Search, MessageCircle, CheckCircle2, LogIn, BadgeCheck, TrendingUp, X } from 'lucide-react';
import {
  Facility, FacilityBooking, GiftItem, FacilitySale, SaleLine, FacilityRevenue,
  FacilityType, BookingKind, FacilityBookingStatus,
  FACILITY_TYPE_LABEL, FACILITY_TYPE_SHORT, FACILITY_TYPE_DEPT,
  BOOKING_KIND_LABEL, FACILITY_BOOKING_STATUS_LABEL, FACILITY_BOOKING_STATUS_DEPS,
  ActivityLog,
} from '@/lib/types';
import { seedFacilities, seedGiftItems, seedFacilityBookings, seedFacilityRevenue, seedActivity } from '@/lib/seed';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { tagFor, hasPermission, hasAnyPermission, PERMISSIONS, type Department } from '@/lib/rbac';
import { today, nowISO, uid, naira, fmtDate } from '@/lib/format';
import { postActivity } from '@/lib/activity';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, Select, DateInput, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'facilities' | 'bookings' | 'giftShop' | 'revenue';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'facilities', label: 'Facilities', icon: CalendarClock },
  { id: 'bookings', label: 'Bookings & Events', icon: BadgeCheck },
  { id: 'giftShop', label: 'Gift Shop', icon: ShoppingBag },
  { id: 'revenue', label: 'Revenue', icon: TrendingUp },
];

const TYPE_COLOR: Record<FacilityType, string> = {
  gym: 'text-red-500 bg-red-50',
  pool: 'text-blue-600 bg-blue-50',
  giftShop: 'text-orange-600 bg-orange-50',
  eventHall: 'text-amber-600 bg-amber-50',
};
const TYPE_ICON: Record<FacilityType, any> = {
  gym: Dumbbell, pool: Waves, giftShop: ShoppingBag, eventHall: CalendarClock,
};

export function FacilitiesModule() {
  const { session } = useAuth();
  const core = hasAnyPermission(session, [
    PERMISSIONS.viewFacilities, PERMISSIONS.manageFacilities,
    PERMISSIONS.manageFacilityAccess, PERMISSIONS.manageGiftShop,
  ]);
  const canGift = hasAnyPermission(session, [
    PERMISSIONS.manageGiftShop, PERMISSIONS.manageFacilities,
  ]);
  const canRev = hasAnyPermission(session, [
    PERMISSIONS.viewNightAudit, PERMISSIONS.manageFacilities,
    PERMISSIONS.manageFacilityAccess, PERMISSIONS.manageGiftShop,
  ]);
  const tabs = SUB_NAV.filter(s =>
    s.id === 'facilities' || s.id === 'bookings' ? core
    : s.id === 'giftShop' ? canGift : canRev);
  const [tab, setTab] = useState<SubTab>(tabs[0]?.id ?? 'facilities');
  const activeTab = tabs.some(s => s.id === tab) ? tab : (tabs[0]?.id ?? 'facilities');
  return (
    <div className="space-y-4">
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {tabs.map(s => {
          const Icon = s.icon;
          return (
            <button key={s.id} onClick={() => setTab(s.id)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap flex items-center gap-1.5 ${activeTab === s.id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
              <Icon size={13} />{s.label}
            </button>
          );
        })}
      </div>
      {activeTab === 'facilities' && core && <FacilitiesTab />}
      {activeTab === 'bookings' && core && <BookingsTab />}
      {activeTab === 'giftShop' && canGift && <GiftShopTab />}
      {activeTab === 'revenue' && canRev && <RevenueTab />}
    </div>
  );
}

// ─── Facilities ──────────────────────────────────────────────────────────────

function FacilitiesTab() {
  const { session } = useAuth();
  const facilities = useSyncedCollection<Facility>('facilities', 'facilities', seedFacilities, session);
  const bookings = useSyncedCollection<FacilityBooking>('facility_bookings', 'facility_bookings', seedFacilityBookings, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const depts = tagFor(session, 'banqueting');
  const canEdit = hasPermission(session, PERMISSIONS.manageFacilities);
  const [showForm, setShowForm] = useState(false);
  const [edit, setEdit] = useState<Facility | null>(null);

  const openToday = bookings.items.filter(b =>
    b.status !== 'cancelled' && b.date === today()).length;
  const checkInsToday = bookings.items
    .flatMap(b => b.checkIns || [])
    .filter(c => c.slice(0, 10) === today()).length;

  const facilityDept = (t: FacilityType): Department[] =>
    [FACILITY_TYPE_DEPT[t]];

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <MetricCard label="Amenities" value={facilities.items.length} sub={`${facilities.items.filter(f => f.isAvailable).length} available`} color="bg-green-50 text-green-700" />
        <MetricCard label="Bookings today" value={openToday} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Visits today" value={checkInsToday} sub="access log" color="bg-amber-50 text-amber-700" />
      </div>

      <SectionHeader title={`Facility & Amenity List (${facilities.items.length})`}>
        {canEdit && <Btn onClick={() => { setShowForm(true); setEdit(null); }}><Plus size={14} /> Add Facility</Btn>}
      </SectionHeader>

      {showForm && (
        <FacilityForm initial={edit} onSave={(f) => {
          if (edit) facilities.replace(f.id, f); else facilities.add(f);
          postActivity(feed, session, {
            dept: 'banqueting', action: 'facility.created',
            message: `${edit ? 'Updated' : 'Added'} facility ${f.name}`, refId: f.id,
          });
          setShowForm(false); setEdit(null);
        }} onCancel={() => { setShowForm(false); setEdit(null); }} />
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {facilities.items.map(f => {
          const Icon = TYPE_ICON[f.type];
          return (
            <Card key={f.id} className="p-4">
              <div className="flex items-start gap-3">
                <div className={`h-10 w-10 rounded-xl flex items-center justify-center shrink-0 ${TYPE_COLOR[f.type]}`}>
                  <Icon size={18} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <div className="font-bold text-sm truncate">{f.name}</div>
                    <StatusChip status={f.isAvailable ? 'available' : 'maintenance'} label={f.isAvailable ? 'Open' : 'Closed'} />
                  </div>
                  <div className="text-[11px] text-zinc-500 mt-0.5">{f.hours} · {f.capacity > 0 ? `${f.capacity} capacity` : ''}</div>
                  <div className="text-xs font-bold mt-0.5">
                    {f.type === 'eventHall'
                      ? `${naira(f.rate)}/event · deposit ${f.depositPercent || 0}%`
                      : f.rate > 0 ? `${naira(f.rate)}/pass` : 'Retail point of sale'}
                  </div>
                  {f.type === 'eventHall' && f.equipment && f.equipment.length > 0 && (
                    <div className="flex flex-wrap gap-1 mt-1.5">
                      {f.equipment.slice(0, 4).map((e, i) => (
                        <span key={i} className="text-[9px] bg-zinc-100 text-zinc-600 px-1.5 py-0.5 rounded">{e}</span>
                      ))}
                    </div>
                  )}
                </div>
                {canEdit && (
                  <div className="flex gap-1">
                    <IconBtn onClick={() => { setEdit(f); setShowForm(true); }}><Edit3 size={12} /></IconBtn>
                    <IconBtn tone="red" onClick={() => {
                      facilities.remove(f.id);
                      postActivity(feed, session, { dept: 'banqueting', action: 'facility.deleted', message: `Removed facility ${f.name}`, refId: f.id });
                    }}><Trash2 size={12} /></IconBtn>
                  </div>
                )}
              </div>
              <div className="mt-2 hidden">
                {facilityDept(f.type).join(',')}
              </div>
            </Card>
          );
        })}
        {facilities.items.length === 0 && <div className="col-span-full"><EmptyState text="No facilities configured" /></div>}
      </div>
    </div>
  );
}

function FacilityForm({ initial, onSave, onCancel }: { initial: Facility | null; onSave: (f: Facility) => void; onCancel: () => void }) {
  const [f, setF] = useState({
    name: initial?.name || '', type: initial?.type || 'gym', rate: initial ? String(initial.rate) : '',
    capacity: initial ? String(initial.capacity) : '', hours: initial?.hours || '',
    description: initial?.description || '', venue: initial?.venue || '',
    depositPercent: initial?.depositPercent ? String(initial.depositPercent) : '',
    equipment: initial?.equipment?.join(', ') || '', blockedDates: initial?.blockedDates?.join(', ') || '',
  });
  const isEvent = f.type === 'eventHall';
  return (
    <FormCard title={initial ? 'Edit Facility' : 'Add Facility'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Facility name" /></Field>
        <Field label="Type">
          <Select value={f.type} onChange={e => setF({ ...f, type: e.target.value as FacilityType })}>
            {(Object.keys(FACILITY_TYPE_LABEL) as FacilityType[]).map(t => (
              <option key={t} value={t}>{FACILITY_TYPE_LABEL[t]}</option>
            ))}
          </Select>
        </Field>
        <Field label="Rate (₦) — pass / event fee"><NumberInput value={f.rate} onChange={e => setF({ ...f, rate: e.target.value })} placeholder="0" /></Field>
        <Field label="Capacity"><NumberInput value={f.capacity} onChange={e => setF({ ...f, capacity: e.target.value })} placeholder="0" /></Field>
        <Field label="Hours"><TextInput value={f.hours} onChange={e => setF({ ...f, hours: e.target.value })} placeholder="6:00 — 22:00" /></Field>
        {isEvent && (
          <>
            <Field label="Venue / Location"><TextInput value={f.venue} onChange={e => setF({ ...f, venue: e.target.value })} placeholder="e.g. Ground floor, east wing" /></Field>
            <Field label="Deposit schedule (%)"><NumberInput value={f.depositPercent} onChange={e => setF({ ...f, depositPercent: e.target.value })} placeholder="70 for 70/30" /></Field>
            <Field label="Equipment (comma separated)"><TextInput value={f.equipment} onChange={e => setF({ ...f, equipment: e.target.value })} placeholder="Projector, 2 mics, chairs" /></Field>
            <Field label="Blocked dates (yyyy-MM-dd)"><TextInput value={f.blockedDates} onChange={e => setF({ ...f, blockedDates: e.target.value })} placeholder="2026-12-25, 2027-01-01" /></Field>
          </>
        )}
        <Field label="Description" className="md:col-span-2"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="Optional description" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => {
          if (!f.name) return alert('Name required');
          onSave({
            id: initial?.id || uid('fac'), name: f.name, type: f.type,
            rate: Number(f.rate) || 0, capacity: Number(f.capacity) || 0,
            isAvailable: initial?.isAvailable ?? true, hours: f.hours, description: f.description,
            venue: f.venue, depositPercent: Number(f.depositPercent) || 0,
            equipment: f.equipment.split(',').map(s => s.trim()).filter(Boolean),
            blockedDates: f.blockedDates.split(',').map(s => s.trim()).filter(Boolean),
            departments: [FACILITY_TYPE_DEPT[f.type]],
          });
        }}>{initial ? 'Update' : 'Add Facility'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Bookings & Events ───────────────────────────────────────────────────────

const waMessage = (b: FacilityBooking): string => [
  `HOM — ${b.facilityName}`,
  BOOKING_KIND_LABEL[b.kind].toUpperCase(),
  `Guest: ${b.guestName}`,
  `Date: ${fmtDate(b.date)}`,
  b.kind === 'event' && b.eventType ? `Event: ${b.eventType}` : '',
  b.kind === 'event' ? `Guests: ${b.guestCount || 0}` : '',
  b.qty > 1 ? `Qty: ${b.qty}` : '',
  `Amount: ${naira(b.amount)}`,
  `Paid: ${naira(b.paidAmount)}`,
  `Status: ${FACILITY_BOOKING_STATUS_LABEL[b.status]}`,
  `Reference: ${b.id}`,
].filter(Boolean).join('\n');

const normPhone = (p: string) => {
  let x = p.replace(/\D/g, '');
  if (x.startsWith('0')) x = '234' + x.slice(1);
  return x;
};

function BookingsTab() {
  const { session } = useAuth();
  const bookings = useSyncedCollection<FacilityBooking>('facility_bookings', 'facility_bookings', seedFacilityBookings, session);
  const facilities = useSyncedCollection<Facility>('facilities', 'facilities', seedFacilities, session);
  const revenue = useSyncedCollection<FacilityRevenue>('facility_revenue', 'facility_revenue', seedFacilityRevenue, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const depts = tagFor(session, 'banqueting');
  const canManage = hasAnyPermission(session, [
    PERMISSIONS.manageFacilities, PERMISSIONS.manageFacilityAccess,
    PERMISSIONS.manageCorporateEvents, PERMISSIONS.manageBanquetingHallRentals,
  ]);
  const canDelete = hasAnyPermission(session, [
    PERMISSIONS.manageFacilities, PERMISSIONS.manageCorporateEvents,
    PERMISSIONS.manageBanquetingHallRentals,
  ]);
  const [showForm, setShowForm] = useState(false);
  const [kindFilter, setKindFilter] = useState<'all' | BookingKind>('all');
  const [q, setQ] = useState('');

  const list = bookings.items
    .filter(b => (kindFilter === 'all' || b.kind === kindFilter) &&
      (!q || b.guestName.toLowerCase().includes(q.toLowerCase()) ||
       b.facilityName.toLowerCase().includes(q.toLowerCase()) || b.phone.includes(q)))
    .sort((a, b) => b.date.localeCompare(a.date));

  const syncBookingRevenue = (b: FacilityBooking) => {
    const recognized = (b.status === 'paid' || b.status === 'depositPaid') && b.amount > 0;
    const existing = revenue.items.find(r => r.refId === b.id);
    const facility = facilities.items.find(f => f.id === b.facilityId);
    const source = facility ? FACILITY_TYPE_SHORT[facility.type] : b.facilityName;
    if (!recognized) {
      if (existing) revenue.remove(existing.id);
      return;
    }
    const amount = b.status === 'depositPaid'
      ? Math.min(b.paidAmount, b.amount)
      : b.amount;
    if (amount <= 0) { if (existing) revenue.remove(existing.id); return; }
    if (existing) revenue.replace(existing.id, { ...existing, date: b.date, source, amount });
    else revenue.add({ id: uid('frev'), date: b.date, source, amount, refId: b.id, departments: depts });
  };

  const advance = (b: FacilityBooking, status: FacilityBookingStatus) => {
    const paidAmount = status === 'paid' ? b.amount
      : status === 'depositPaid' ? Math.min(b.amount * (b.depositPercent || 0) / 100, b.amount)
      : b.paidAmount;
    const updated: FacilityBooking = { ...b, status, paidAmount };
    bookings.replace(b.id, updated);
    syncBookingRevenue(updated);
    postActivity(feed, session, {
      dept: 'banqueting', action: 'facility.status',
      message: `${FACILITY_BOOKING_STATUS_LABEL[status]} — ${b.guestName} (${b.facilityName})`, refId: b.id,
    });
  };

  const checkIn = (b: FacilityBooking) => {
    const updated: FacilityBooking = { ...b, checkIns: [...(b.checkIns || []), nowISO()] };
    bookings.replace(b.id, updated);
    postActivity(feed, session, { dept: 'banqueting', action: 'facility.checkin', message: `${b.guestName} checked in at ${b.facilityName}`, refId: b.id });
  };

  const sendWa = (b: FacilityBooking) => {
    const phone = normPhone(b.phone);
    if (!phone) return;
    window.open(`https://wa.me/${phone}?text=${encodeURIComponent(waMessage(b))}`, '_blank');
  };

  const counts: Record<'all' | BookingKind, number> = {
    all: bookings.items.length,
    dayPass: bookings.items.filter(b => b.kind === 'dayPass').length,
    membership: bookings.items.filter(b => b.kind === 'membership').length,
    event: bookings.items.filter(b => b.kind === 'event').length,
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
          <TextInput className="pl-8" value={q} onChange={e => setQ(e.target.value)} placeholder="Search guest, facility or phone…" />
        </div>
        {canManage && <Btn onClick={() => setShowForm(true)}><Plus size={14} /> New Booking / Pass / Event</Btn>}
      </div>

      <div className="flex gap-1.5 flex-wrap">
        {(['all', 'dayPass', 'membership', 'event'] as const).map(k => (
          <button key={k} onClick={() => setKindFilter(k)}
            className={`px-3 py-1.5 rounded-full text-xs font-bold ${kindFilter === k ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
            {k === 'all' ? 'All' : BOOKING_KIND_LABEL[k]} ({counts[k]})
          </button>
        ))}
      </div>

      {showForm && (
        <BookingForm facilities={facilities.items} onSave={(b) => {
          bookings.add(b);
          syncBookingRevenue(b);
          postActivity(feed, session, { dept: 'banqueting', action: 'facility.booking', message: `${BOOKING_KIND_LABEL[b.kind]} for ${b.guestName} at ${b.facilityName}`, refId: b.id });
          setShowForm(false);
        }} onCancel={() => setShowForm(false)} />
      )}

      <div className="space-y-2">
        {list.length === 0 && <EmptyState text="No bookings found" />}
        {list.map(b => (
          <Card key={b.id} className="p-4">
            <div className="flex items-start justify-between gap-3 flex-wrap">
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <div className="font-bold text-sm">{b.guestName}</div>
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${FACILITY_BOOKING_STATUS_DEPS[b.status]}`}>{FACILITY_BOOKING_STATUS_LABEL[b.status]}</span>
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-600 font-bold">{BOOKING_KIND_LABEL[b.kind]}</span>
                </div>
                <div className="text-xs text-zinc-500 mt-0.5">
                  {b.facilityName} · {fmtDate(b.date)}
                  {b.kind === 'event' && ` · ${b.eventType || 'Event'}${b.guestCount ? ` · ${b.guestCount} guests` : ''}`}
                  {b.kind === 'membership' && ` · expires ${fmtDate(b.endDate)}`}
                </div>
                <div className="text-xs font-bold mt-0.5">
                  {naira(b.amount)} · Paid {naira(b.paidAmount)}
                  {b.amount - b.paidAmount > 0 && b.status !== 'cancelled' && <span className="text-orange-600"> · Balance {naira(b.amount - b.paidAmount)}</span>}
                </div>
                {b.checkIns && b.checkIns.length > 0 && (
                  <div className="text-[11px] font-bold text-green-600 mt-0.5">{b.checkIns.length} check-in{b.checkIns.length > 1 ? 's' : ''}</div>
                )}
              </div>
              <div className="flex gap-1.5 flex-wrap justify-end">
                {canManage && b.status === 'requested' && (
                  <Btn color="primary" onClick={() => advance(b, 'confirmed')}><CheckCircle2 size={13} /> Confirm</Btn>
                )}
                {canManage && b.status === 'confirmed' && (
                  <Btn color="amber" onClick={() => advance(b, 'depositPaid')}>{b.kind === 'event' ? 'Deposit' : 'Collect'} {b.kind === 'event' ? `(${naira(b.amount * (b.depositPercent || 0) / 100)})` : ''}</Btn>
                )}
                {canManage && b.status === 'depositPaid' && (
                  <Btn color="green" onClick={() => advance(b, 'paid')}><CheckCircle2 size={13} /> Full Payment</Btn>
                )}
                {canManage && b.kind !== 'event' && b.status === 'paid' && (
                  <Btn onClick={() => checkIn(b)}><LogIn size={13} /> Check-in</Btn>
                )}
                {b.phone && (
                  <Btn color="outline" onClick={() => sendWa(b)}><MessageCircle size={13} /> WhatsApp</Btn>
                )}
                {canDelete && (
                  <IconBtn tone="red" onClick={() => {
                    bookings.remove(b.id);
                    const existing = revenue.items.find(r => r.refId === b.id);
                    if (existing) revenue.remove(existing.id);
                  }}><Trash2 size={12} /></IconBtn>
                )}
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

function BookingForm({ facilities, onSave, onCancel }: { facilities: Facility[]; onSave: (b: FacilityBooking) => void; onCancel: () => void }) {
  const empty = facilities[0]?.id || '';
  const [f, setF] = useState({
    facilityId: empty, kind: 'dayPass' as BookingKind, guestName: '', phone: '',
    qty: '1', amount: '', paid: '', status: 'requested' as FacilityBookingStatus,
    paymentMethod: 'Cash', eventType: '', organizer: '', guestCount: '',
    avNeeds: '', buffet: '', notes: '',
  });
  const facility = facilities.find(x => x.id === f.facilityId);
  const isEvent = f.kind === 'event';
  const amount = Number(f.amount) || 0;
  const depositPct = isEvent ? (facility?.depositPercent || 0) : 0;
  const endDate = f.kind === 'membership'
    ? new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10)
    : today();

  const pickFacility = (id: string) => {
    const fac = facilities.find(x => x.id === id);
    const next: typeof f = { ...f, facilityId: id };
    if (!f.amount && fac && fac.rate > 0) next.amount = String(fac.rate);
    setF(next);
  };

  return (
    <FormCard title="New Booking / Pass / Event" onCancel={onCancel}>
      <FieldGrid>
        <Field label="Facility">
          <Select value={f.facilityId} onChange={e => pickFacility(e.target.value)}>
            {facilities.map(x => (
              <option key={x.id} value={x.id}>{x.name} ({FACILITY_TYPE_SHORT[x.type]})</option>
            ))}
          </Select>
        </Field>
        <Field label="Booking Type">
          <Select value={f.kind} onChange={e => setF({ ...f, kind: e.target.value as BookingKind })}>
            {(Object.keys(BOOKING_KIND_LABEL) as BookingKind[]).map(k => (
              <option key={k} value={k}>{BOOKING_KIND_LABEL[k]}</option>
            ))}
          </Select>
        </Field>
        <Field label="Guest / Client Name"><TextInput value={f.guestName} onChange={e => setF({ ...f, guestName: e.target.value })} placeholder="Guest name" /></Field>
        <Field label="WhatsApp Phone"><TextInput value={f.phone} onChange={e => setF({ ...f, phone: e.target.value })} placeholder="e.g. 08031234567" /></Field>
        <Field label="Qty"><NumberInput value={f.qty} onChange={e => setF({ ...f, qty: e.target.value })} /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder={facility ? String(facility.rate) : '0'} /></Field>
        <Field label="Date"><DateInput value={today()} disabled /></Field>
        <Field label="Paid (₦)"><NumberInput value={f.paid} onChange={e => setF({ ...f, paid: e.target.value })} placeholder="0" /></Field>
        <Field label="Payment Method">
          <Select value={f.paymentMethod} onChange={e => setF({ ...f, paymentMethod: e.target.value })}>
            <option>Cash</option><option>Transfer</option><option>POS</option><option>Card</option>
          </Select>
        </Field>
        <Field label="Status">
          <Select value={f.status} onChange={e => setF({ ...f, status: e.target.value as FacilityBookingStatus })}>
            {(Object.keys(FACILITY_BOOKING_STATUS_LABEL) as FacilityBookingStatus[]).map(s => (
              <option key={s} value={s}>{FACILITY_BOOKING_STATUS_LABEL[s]}</option>
            ))}
          </Select>
        </Field>
        {isEvent && (
          <>
            <Field label="Event Type"><TextInput value={f.eventType} onChange={e => setF({ ...f, eventType: e.target.value })} placeholder="Wedding / Owambe / AGM" /></Field>
            <Field label="Organizer"><TextInput value={f.organizer} onChange={e => setF({ ...f, organizer: e.target.value })} /></Field>
            <Field label="Expected Guests"><NumberInput value={f.guestCount} onChange={e => setF({ ...f, guestCount: e.target.value })} /></Field>
            <Field label="AV / Equipment"><TextInput value={f.avNeeds} onChange={e => setF({ ...f, avNeeds: e.target.value })} placeholder="Projector + 2 mics" /></Field>
            <Field label="Buffet / Catering"><TextInput value={f.buffet} onChange={e => setF({ ...f, buffet: e.target.value })} /></Field>
          </>
        )}
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} /></Field>
      </FieldGrid>
      {isEvent && depositPct > 0 && (
        <p className="text-xs font-bold text-amber-600 mt-2">
          Deposit schedule: {depositPct}% / {100 - depositPct}% ({naira(amount * depositPct / 100)} due up-front)
        </p>
      )}
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => {
          if (!f.guestName) return alert('Guest name required');
          onSave({
            id: uid('bk'), facilityId: f.facilityId,
            facilityName: facility?.name || '', kind: f.kind, status: f.status,
            guestName: f.guestName, phone: f.phone.trim(), date: today(), endDate,
            qty: Number(f.qty) || 1, amount, paidAmount: Number(f.paid) || 0,
            depositPercent: isEvent ? depositPct : 0,
            eventType: f.eventType, guestCount: Number(f.guestCount) || 0,
            avNeeds: f.avNeeds, buffet: f.buffet, organizer: f.organizer,
            notes: f.notes, staffName: 'Staff',
            paymentMethod: f.paymentMethod,
            departments: facility ? [FACILITY_TYPE_DEPT[facility.type]] : deptFallback,
          });
        }}>Save Booking</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ⚠ helper so BookingForm can build departments without access to session scope
const deptFallback: Department[] = ['banqueting'];

// ─── Gift Shop ───────────────────────────────────────────────────────────────

function GiftShopTab() {
  const { session } = useAuth();
  const items = useSyncedCollection<GiftItem>('gift_items', 'gift_items', seedGiftItems, session);
  const sales = useSyncedCollection<FacilitySale>('facility_sales', 'facility_sales', () => [], session);
  const revenue = useSyncedCollection<FacilityRevenue>('facility_revenue', 'facility_revenue', seedFacilityRevenue, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const depts = tagFor(session, 'concierge');
  const canPOS = hasAnyPermission(session, [PERMISSIONS.manageGiftShop, PERMISSIONS.manageFacilities]);
  const [cart, setCart] = useState<Record<string, number>>({});
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<GiftItem | null>(null);
  const [checkingOut, setCheckingOut] = useState(false);
  const [cashier, setCashier] = useState(session?.userName || 'Staff');
  const [customer, setCustomer] = useState('');
  const [method, setMethod] = useState('Cash');

  const cartLines = items.items
    .filter(g => (cart[g.id] || 0) > 0)
    .map(g => ({ item: g, qty: cart[g.id] }));
  const cartTotal = cartLines.reduce((s, l) => s + l.qty * l.item.price, 0);
  const cartCount = cartLines.reduce((s, l) => s + l.qty, 0);
  const lowStock = items.items.filter(g => g.available && g.stock <= g.low).length;

  const checkout = () => {
    const sale: FacilitySale = {
      id: uid('sale'), date: nowISO(), items: cartLines.map(l => ({
        itemId: l.item.id, name: l.item.name, qty: l.qty, unitPrice: l.item.price,
      }) as SaleLine), cashier, customerName: customer, paymentMethod: method,
      note: '', departments: depts,
    };
    sales.add(sale);
    for (const l of cartLines) {
      items.update(l.item.id, { stock: Math.max(0, l.item.stock - l.qty) });
    }
    revenue.add({ id: uid('frev'), date: today(), source: 'Gift Shop', amount: cartTotal, refId: sale.id, departments: depts });
    postActivity(feed, session, { dept: 'concierge', action: 'facility.sale', message: `Gift shop sale ${naira(cartTotal)} (${cartCount} items) by ${cashier}`, refId: sale.id });
    setCart({}); setCheckingOut(false); setCustomer('');
  };

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <MetricCard label="Items" value={items.items.length} color="bg-green-50 text-green-700" />
        <MetricCard label="Low stock" value={lowStock} color="bg-red-50 text-red-700" />
        <MetricCard label="Cart" value={naira(cartTotal)} sub={`${cartCount} items`} color="bg-orange-50 text-orange-700" />
      </div>

      <SectionHeader title={`Gift Shop POS (${items.items.length})`}>
        {canPOS && <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Item</Btn>}
      </SectionHeader>

      {showForm && (
        <GiftItemForm initial={editItem} onSave={(g) => {
          if (editItem) items.replace(g.id, g); else items.add(g);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {items.items.map(g => {
          const qty = cart[g.id] || 0;
          const disabled = !g.available || g.stock === 0;
          return (
            <Card key={g.id} className="p-4 flex items-center gap-3">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <div className="font-bold text-sm truncate">{g.name}</div>
                  {g.available && g.stock <= g.low && <span className="text-[9px] font-black text-red-600 bg-red-50 px-1.5 py-0.5 rounded">LOW</span>}
                </div>
                <div className="text-xs text-zinc-500">{naira(g.price)} · stock {g.stock} · {g.category}</div>
              </div>
              {canPOS ? (
                <div className="flex items-center gap-1 shrink-0">
                  <IconBtn onClick={() => setCart({ ...cart, [g.id]: Math.max(0, qty - 1) })}><X size={12} /></IconBtn>
                  <span className="w-6 text-center font-bold text-sm">{qty}</span>
                  <button
                    className={`h-7 w-7 rounded-lg flex items-center justify-center font-black ${disabled || qty >= g.stock ? 'bg-zinc-100 text-zinc-300' : 'bg-hom-primary text-white'}`}
                    onClick={() => setCart({ ...cart, [g.id]: qty + 1 })}
                    disabled={disabled || qty >= g.stock}>+</button>
                  <IconBtn onClick={() => { setEditItem(g); setShowForm(true); }}><Edit3 size={12} /></IconBtn>
                  <IconBtn tone="red" onClick={() => items.remove(g.id)}><Trash2 size={12} /></IconBtn>
                </div>
              ) : (
                <span className="text-xs text-zinc-500 shrink-0">stock {g.stock}</span>
              )}
            </Card>
          );
        })}
        {items.items.length === 0 && <div className="col-span-full"><EmptyState text="No gift items configured" /></div>}
      </div>

      {canPOS && cartCount > 0 && (
        <Card className="p-4 border-2 border-orange-200 bg-orange-50/40">
          <div className="flex items-center justify-between gap-3 flex-wrap">
            <div>
              <div className="text-xs font-bold text-orange-600 uppercase tracking-wide">Checkout</div>
              <div className="font-black text-lg">{naira(cartTotal)} <span className="text-xs font-bold text-zinc-500">({cartCount} items)</span></div>
            </div>
            <div className="flex items-center gap-2">
              <TextInput className="w-36" value={cashier} onChange={e => setCashier(e.target.value)} placeholder="Cashier" />
              <TextInput className="w-36" value={customer} onChange={e => setCustomer(e.target.value)} placeholder="Customer (optional)" />
              <Select className="w-28" value={method} onChange={e => setMethod(e.target.value)}>
                <option>Cash</option><option>Transfer</option><option>POS</option><option>Card</option>
              </Select>
              <Btn color="amber" onClick={() => setCheckingOut(true)}>Pay — {naira(cartTotal)}</Btn>
            </div>
          </div>
        </Card>
      )}

      {checkingOut && (
        <FormCard title="Confirm Sale" onCancel={() => setCheckingOut(false)}>
          <div className="space-y-1 text-sm">
            {cartLines.map(l => (
              <div key={l.item.id} className="flex justify-between">
                <span>{l.item.name} × {l.qty}</span>
                <span className="font-bold">{naira(l.qty * l.item.price)}</span>
              </div>
            ))}
            <div className="flex justify-between font-black pt-2 border-t">Total <span>{naira(cartTotal)}</span></div>
          </div>
          <div className="mt-4 flex gap-2">
            <Btn color="amber" onClick={checkout}>Complete Sale — {naira(cartTotal)}</Btn>
            <Btn color="outline" onClick={() => setCheckingOut(false)}>Back</Btn>
          </div>
        </FormCard>
      )}
    </div>
  );
}

function GiftItemForm({ initial, onSave, onCancel }: { initial: GiftItem | null; onSave: (g: GiftItem) => void; onCancel: () => void }) {
  const [g, setG] = useState({
    name: initial?.name || '', sku: initial?.sku || '', category: initial?.category || 'General',
    price: initial ? String(initial.price) : '', stock: initial ? String(initial.stock) : '',
    low: initial ? String(initial.low) : '', available: initial?.available ?? true,
  });
  return (
    <FormCard title={initial ? 'Edit Gift Item' : 'Add Gift Item'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Name"><TextInput value={g.name} onChange={e => setG({ ...g, name: e.target.value })} placeholder="Item name" /></Field>
        <Field label="SKU / Barcode"><TextInput value={g.sku} onChange={e => setG({ ...g, sku: e.target.value })} placeholder="MR-101" /></Field>
        <Field label="Category"><TextInput value={g.category} onChange={e => setG({ ...g, category: e.target.value })} placeholder="General" /></Field>
        <Field label="Price (₦)"><NumberInput value={g.price} onChange={e => setG({ ...g, price: e.target.value })} placeholder="0" /></Field>
        <Field label="Stock"><NumberInput value={g.stock} onChange={e => setG({ ...g, stock: e.target.value })} placeholder="0" /></Field>
        <Field label="Low-stock alert at"><NumberInput value={g.low} onChange={e => setG({ ...g, low: e.target.value })} placeholder="0" /></Field>
      </FieldGrid>
      <label className="flex items-center gap-2 mt-3 text-sm">
        <input type="checkbox" checked={g.available} onChange={e => setG({ ...g, available: e.target.checked })} />
        Available for sale
      </label>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => {
          if (!g.name) return alert('Name required');
          onSave({
            id: initial?.id || uid('gi'), name: g.name, sku: g.sku, category: g.category,
            price: Number(g.price) || 0, stock: Number(g.stock) || 0, low: Number(g.low) || 0,
            available: g.available, departments: ['concierge'],
          });
        }}>{initial ? 'Update' : 'Add Item'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Revenue ──────────────────────────────────────────────────────────────────

const SOURCE_COLOR: Record<string, string> = {
  Gym: 'bg-red-500', Pool: 'bg-blue-500', 'Gift Shop': 'bg-orange-500', Events: 'bg-amber-500',
};

function RevenueTab() {
  const { session } = useAuth();
  const revenue = useSyncedCollection<FacilityRevenue>('facility_revenue', 'facility_revenue', seedFacilityRevenue, session);

  const month = revenue.items.filter(r => r.date.slice(0, 7) === today().slice(0, 7));
  const monthTotal = month.reduce((s, r) => s + r.amount, 0);
  const todayTotal = month.filter(r => r.date === today()).reduce((s, r) => s + r.amount, 0);
  const bySource: Record<string, number> = {};
  for (const r of month) bySource[r.source] = (bySource[r.source] || 0) + r.amount;
  const sources = Object.keys(bySource).sort();
  const rows = [...revenue.items].sort((a, b) => b.date.localeCompare(a.date));

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <MetricCard label="This month" value={naira(monthTotal)} color="bg-green-50 text-green-700" />
        <MetricCard label="Today" value={naira(todayTotal)} color="bg-amber-50 text-amber-700" />
        <MetricCard label="Roll-up target" value="Night Audit" sub="auto-posted by source" color="bg-blue-50 text-blue-700" />
      </div>

      <SectionHeader title="Revenue by Source" />
      {sources.length === 0 && <EmptyState text="No facility revenue yet — postings appear when bookings are paid or gift sales are recorded." />}
      <div className="space-y-3">
        {sources.map(s => (
          <div key={s}>
            <div className="flex justify-between text-sm font-bold">
              <span>{s}</span><span>{naira(bySource[s])}</span>
            </div>
            <div className="h-2 bg-zinc-100 rounded-full mt-1 overflow-hidden">
              <div className={`h-full ${SOURCE_COLOR[s] || 'bg-amber-500'}`} style={{ width: `${monthTotal > 0 ? (bySource[s] / monthTotal) * 100 : 0}%` }} />
            </div>
          </div>
        ))}
      </div>

      <SectionHeader title="Recent Postings" />
      <div className="space-y-2">
        {rows.length === 0 && <EmptyState text="No postings yet" />}
        {rows.slice(0, 20).map(r => (
          <Card key={r.id} className="p-3 flex items-center justify-between gap-3">
            <div className="flex items-center gap-3 min-w-0">
              <div className={`h-8 w-8 rounded-lg flex items-center justify-center text-white font-black text-xs shrink-0 ${SOURCE_COLOR[r.source] || 'bg-amber-500'}`}>
                {r.source.slice(0, 1)}
              </div>
              <div className="min-w-0">
                <div className="font-bold text-sm">{r.source} — {naira(r.amount)}</div>
                <div className="text-[11px] text-zinc-500">{fmtDate(r.date)} · {r.refId}</div>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
