'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, TrendingUp, MoonStar, PackageX, AlertTriangle } from 'lucide-react';
import { DailyRevenue, CashDrop, HousekeepingLoss, TOTAL_ROOMS, ShiftName } from '@/lib/types';
import { seedRevenues, seedCashDrops, seedLosses, seedActivity } from '@/lib/seed';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { tagFor, type Department } from '@/lib/rbac';
import { today, uid, naira, fmtDate, addDays, monthStart } from '@/lib/format';
import { postActivity } from '@/lib/activity';
import { ActivityLog } from '@/lib/types';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'revpar' | 'nightaudit' | 'housekeeping';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'revpar', label: 'RevPAR', icon: TrendingUp },
  { id: 'nightaudit', label: 'Night Audit', icon: MoonStar },
  { id: 'housekeeping', label: 'Housekeeping', icon: PackageX },
];

export function OperationsModule() {
  const [tab, setTab] = useState<SubTab>('revpar');
  return (
    <div className="space-y-4">
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {SUB_NAV.map(s => {
          const Icon = s.icon;
          return (
            <button key={s.id} onClick={() => setTab(s.id)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap flex items-center gap-1.5 ${tab === s.id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
              <Icon size={13} />{s.label}
            </button>
          );
        })}
      </div>
      {tab === 'revpar' && <RevParTab />}
      {tab === 'nightaudit' && <NightAuditTab />}
      {tab === 'housekeeping' && <LossesTab />}
    </div>
  );
}

// ─── RevPAR ──────────────────────────────────────────────────────────────────

function RevParTab() {
  const { session } = useAuth();
  const revs = useSyncedCollection<DailyRevenue>('ops_revenues', 'ops_revenues', seedRevenues, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const depts = tagFor(session, 'accounts');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<DailyRevenue | null>(null);

  const sorted = [...revs.items].sort((a, b) => a.date.localeCompare(b.date));
  const last7 = sorted.slice(-7);
  const occ = (r: DailyRevenue) => (r.roomsSold / TOTAL_ROOMS) * 100;
  const revDays = last7.length || 1;
  const avgOcc = last7.reduce((a, r) => a + occ(r), 0) / revDays;
  const sold7 = last7.reduce((a, r) => a + r.roomsSold, 0) || 1;
  const rev7 = last7.reduce((a, r) => a + r.totalRevenue, 0);
  const adr = rev7 / sold7;
  const revpar = rev7 / (TOTAL_ROOMS * revDays);
  const maxRev = sorted.reduce((m, r) => Math.max(m, r.totalRevenue), 0);

  const openEdit = (r: DailyRevenue | null) => { setEditItem(r); setShowForm(true); };

  return (
    <div className="space-y-4">
      <SectionHeader title="Revenue Per Available Room" sub={`Last 7 days from ${sorted.length} daily records`}>
        <Btn onClick={() => openEdit(null)}><Plus size={14} /> Add Daily Entry</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Occupancy" value={`${avgOcc.toFixed(0)}%`} sub={`${revDays} days`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="ADR" value={naira(adr)} sub="Avg daily rate / room sold" color="bg-green-50 text-green-700" />
        <MetricCard label="RevPAR" value={naira(revpar)} sub={`${TOTAL_ROOMS} available rooms`} color="bg-amber-50 text-amber-700" />
        <MetricCard label="7-Day Revenue" value={naira(rev7)} sub={`${sold7} room-nights sold`} color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <RevenueForm initial={editItem} depts={depts} onSave={(r) => {
          if (editItem) revs.replace(r.id, r);
          else { revs.add(r); postActivity(feed, session, { dept: 'accounts', action: 'revpar.logged', message: `Daily revenue logged — ${fmtDate(r.date)} ${naira(r.totalRevenue)} (${r.roomsSold} rooms sold)`, refId: r.id }); }
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="p-5">
        <h3 className="font-bold text-sm mb-4">Revenue — Last 30 Days</h3>
        <div className="flex items-end gap-1 h-40">
          {sorted.map(r => {
            const h = maxRev > 0 ? Math.max(4, (r.totalRevenue / maxRev) * 140) : 4;
            const isToday = r.date === today();
            return (
              <div key={r.id} className="flex-1 flex flex-col items-center justify-end gap-1 min-w-0" title={`${fmtDate(r.date)}: ${naira(r.totalRevenue)}`}>
                <div className="w-full rounded-t bg-hom-primary" style={{ height: h, opacity: isToday ? 1 : 0.75 }} />
                <div className={`text-[10px] ${isToday ? 'text-hom-primary font-bold' : 'text-zinc-400'}`}>{r.date.slice(8)}</div>
              </div>
            );
          })}
        </div>
      </Card>
      <Card className="overflow-hidden">
        <div className="p-4 border-b font-bold text-sm">Room Performance — Last 14 Days</div>
        <div className="divide-y">
          {sorted.slice(-14).reverse().map(r => {
            const pct = occ(r);
            return (
              <div key={r.id} className="p-3 flex items-center gap-3">
                <div className="text-xs font-bold w-16 shrink-0">{fmtDate(r.date)}</div>
                <div className="flex-1 min-w-0">
                  <div className="h-2 bg-zinc-100 rounded-full overflow-hidden">
                    <div className={`h-full rounded-full ${pct > 70 ? 'bg-hom-primary' : pct > 40 ? 'bg-amber-500' : 'bg-red-500'}`} style={{ width: `${pct}%` }} />
                  </div>
                  <div className="text-[10px] text-zinc-500 mt-1">{r.roomsSold} sold • {pct.toFixed(0)}% occ • {r.walkIns} walk-ins</div>
                </div>
                <div className="font-bold text-sm shrink-0">{naira(r.totalRevenue)}</div>
                <div className="flex shrink-0">
                  <IconBtn onClick={() => openEdit(r)}><Edit3 size={13} /></IconBtn>
                  <IconBtn tone="red" onClick={() => revs.remove(r.id)}><Trash2 size={13} /></IconBtn>
                </div>
              </div>
            );
          })}
          {sorted.length === 0 && <EmptyState text="No revenue records" />}
        </div>
      </Card>
    </div>
  );
}

function RevenueForm({ initial, depts, onSave, onCancel }: { initial: DailyRevenue | null; depts: Department[]; onSave: (r: DailyRevenue) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, roomsSold: String(initial.roomsSold), walkIns: String(initial.walkIns), totalRevenue: String(initial.totalRevenue) }
    : { date: today(), roomsSold: '', walkIns: '0', totalRevenue: '' });
  return (
    <FormCard title={initial ? 'Edit Daily Revenue' : 'Add Daily Revenue'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Rooms Sold"><NumberInput value={f.roomsSold} onChange={e => setF({ ...f, roomsSold: e.target.value })} placeholder="Rooms sold" /></Field>
        <Field label="Walk-ins"><NumberInput value={f.walkIns} onChange={e => setF({ ...f, walkIns: e.target.value })} placeholder="Walk-ins" /></Field>
        <Field label="Total Revenue (₦)"><NumberInput value={f.totalRevenue} onChange={e => setF({ ...f, totalRevenue: e.target.value })} placeholder="Total revenue" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.roomsSold || !f.totalRevenue) return alert('Rooms sold and revenue required'); onSave({ id: initial?.id || uid('ops'), date: f.date, roomsSold: Number(f.roomsSold), walkIns: Number(f.walkIns) || 0, totalRevenue: Number(f.totalRevenue), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Night Audit (Cash Drops) ────────────────────────────────────────────────

function NightAuditTab() {
  const { session } = useAuth();
  const drops = useSyncedCollection<CashDrop>('ops_cash_drops', 'ops_cash_drops', seedCashDrops, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const depts = tagFor(session, 'accounts');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<CashDrop | null>(null);

  const t = today();
  const todayDrops = drops.items.filter(c => c.date === t).length;
  const week = drops.items.filter(c => c.date >= addDays(t, -6));
  const matched = week.filter(c => c.status === 'matched').length;
  const mismatched = week.filter(c => c.status === 'mismatched').length;
  const discrepancy = week.reduce((a, c) => a + Math.abs(c.expectedAmount - c.actualAmount), 0);

  return (
    <div className="space-y-4">
      <SectionHeader title="Night Audit — Cash Drops" sub="Shift-wise cash reconciliation">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Log Cash Drop</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Today" value={`${todayDrops} drop${todayDrops === 1 ? '' : 's'}`} sub="Recorded today" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Matched (7d)" value={matched} sub="Cash in balance" color="bg-green-50 text-green-700" />
        <MetricCard label="Mismatched (7d)" value={mismatched} sub="Needs investigation" color="bg-red-50 text-red-700" />
        <MetricCard label="Week Discrepancy" value={naira(discrepancy)} sub="Total variance" color="bg-amber-50 text-amber-700" />
      </div>
      {discrepancy > 0 && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700 font-bold flex items-center gap-2">
          <AlertTriangle size={16} /> Week discrepancy: {naira(discrepancy)}
        </div>
      )}
      {showForm && (
        <DropForm initial={editItem} depts={depts} onSave={(c) => {
          if (editItem) drops.replace(c.id, c);
          else { drops.add(c); postActivity(feed, session, { dept: 'accounts', action: 'cashdrop.logged', message: `${c.shift} cash drop ${fmtDate(c.date)} — ${naira(c.actualAmount)} (${c.status})`, refId: c.id }); }
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="p-4 border-b font-bold text-sm">Last 14 Drops</div>
        <div className="divide-y">
          {drops.items.slice(0, 14).map(c => {
            const diff = c.actualAmount - c.expectedAmount;
            const isMatch = c.status === 'matched';
            return (
              <div key={c.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${isMatch ? '' : 'bg-red-50/60'}`}>
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2">{c.shift} — {fmtDate(c.date)} <StatusChip status={c.status} /></div>
                  <div className="text-xs text-zinc-500 mt-0.5">Expected: {naira(c.expectedAmount)} • Actual: {naira(c.actualAmount)} {c.notes && `• ${c.notes}`}</div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`font-black ${isMatch ? 'text-hom-primary' : 'text-red-600'}`}>{diff >= 0 ? '+' : ''}{naira(diff)}</span>
                  <IconBtn onClick={() => { setEditItem(c); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => drops.remove(c.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {drops.items.length === 0 && <EmptyState text="No cash drops recorded" />}
        </div>
      </Card>
    </div>
  );
}

function DropForm({ initial, depts, onSave, onCancel }: { initial: CashDrop | null; depts: Department[]; onSave: (c: CashDrop) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, shift: initial.shift, expectedAmount: String(initial.expectedAmount), actualAmount: String(initial.actualAmount), notes: initial.notes || '' }
    : { date: today(), shift: 'Morning' as ShiftName, expectedAmount: '', actualAmount: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Cash Drop' : 'Log Cash Drop'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Shift">
          <Select value={f.shift} onChange={e => setF({ ...f, shift: e.target.value as ShiftName })}>
            <option>Morning</option><option>Evening</option><option>Night</option>
          </Select>
        </Field>
        <Field label="Expected (₦)"><NumberInput value={f.expectedAmount} onChange={e => setF({ ...f, expectedAmount: e.target.value })} placeholder="Expected amount" /></Field>
        <Field label="Actual (₦)"><NumberInput value={f.actualAmount} onChange={e => setF({ ...f, actualAmount: e.target.value })} placeholder="Actual amount" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Variance notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.expectedAmount) return alert('Expected amount required'); const exp = Number(f.expectedAmount), act = Number(f.actualAmount) || exp; onSave({ id: initial?.id || uid('ops'), date: f.date, shift: f.shift, expectedAmount: exp, actualAmount: act, status: act === exp ? 'matched' : 'mismatched', notes: f.notes, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Log Drop'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Housekeeping Losses ─────────────────────────────────────────────────────

const LOSS_COLORS: Record<string, string> = {
  Linen: 'bg-blue-500', Amenity: 'bg-amber-500', Furniture: 'bg-purple-500', Maintenance: 'bg-zinc-400',
};

function LossesTab() {
  const { session } = useAuth();
  const losses = useSyncedCollection<HousekeepingLoss>('ops_losses', 'ops_losses', seedLosses, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const depts = tagFor(session, 'housekeeping');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<HousekeepingLoss | null>(null);

  const t = today();
  const monthLoss = losses.items.filter(l => l.date >= monthStart()).reduce((a, l) => a + l.quantity * l.unitCost, 0);
  const totalLoss = losses.items.reduce((a, l) => a + l.quantity * l.unitCost, 0);
  const thisMonth = losses.items.filter(l => l.date >= monthStart());

  const byCat = losses.items.reduce<Record<string, number>>((m, l) => {
    const cost = l.quantity * l.unitCost;
    m[l.category] = (m[l.category] || 0) + cost;
    return m;
  }, {});
  const catEntries = Object.entries(byCat).sort((a, b) => b[1] - a[1]);

  const topItems = losses.items.reduce<Record<string, number>>((m, l) => {
    m[l.item] = (m[l.item] || 0) + l.quantity;
    return m;
  }, {});
  const topEntries = Object.entries(topItems).sort((a, b) => b[1] - a[1]).slice(0, 5);

  return (
    <div className="space-y-4">
      <SectionHeader title="Housekeeping — Losses & Damages" sub="Item losses across rooms">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Log Loss</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <MetricCard label="This Month" value={naira(monthLoss)} sub="Loss cost" color="bg-red-50 text-red-700" />
        <MetricCard label="All Time" value={naira(totalLoss)} sub="Total loss cost" color="bg-orange-50 text-orange-700" />
        <MetricCard label="Items Lost" value={losses.items.length} sub="Records logged" color="bg-blue-50 text-blue-700" />
      </div>
      {showForm && (
        <LossForm initial={editItem} depts={depts} onSave={(l) => {
          if (editItem) losses.replace(l.id, l);
          else { losses.add(l); postActivity(feed, session, { dept: 'housekeeping', action: 'loss.logged', message: `${l.quantity}x ${l.item} lost in Room ${l.roomNumber || '—'} (${naira(l.quantity * l.unitCost)})`, refId: l.id }); }
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="p-5">
          <h3 className="font-bold text-sm mb-3">Loss by Category</h3>
          <div className="space-y-3">
            {catEntries.map(([cat, v]) => (
              <div key={cat}>
                <div className="flex justify-between text-sm mb-1">
                  <span className="font-medium">{cat}</span>
                  <span className="font-bold">{naira(v)} <span className="text-zinc-400 font-normal">{totalLoss ? ((v / totalLoss) * 100).toFixed(0) : 0}%</span></span>
                </div>
                <div className="h-2.5 bg-zinc-100 rounded-full overflow-hidden">
                  <div className={`h-full rounded-full ${LOSS_COLORS[cat] || 'bg-zinc-400'}`} style={{ width: `${totalLoss ? (v / totalLoss) * 100 : 0}%` }} />
                </div>
              </div>
            ))}
            {catEntries.length === 0 && <EmptyState text="No losses recorded" />}
          </div>
        </Card>
        <Card className="p-5">
          <h3 className="font-bold text-sm mb-3">Top Lost Items</h3>
          <div className="space-y-2">
            {topEntries.map(([item, qty]) => (
              <div key={item} className="flex items-center gap-3">
                <span className="bg-red-50 text-red-700 text-xs font-black px-2 py-1 rounded-lg w-12 text-center">{qty}x</span>
                <span className="text-sm">{item}</span>
              </div>
            ))}
            {topEntries.length === 0 && <EmptyState text="No items lost yet" />}
          </div>
        </Card>
      </div>
      <Card className="overflow-hidden">
        <div className="p-4 border-b font-bold text-sm">Recent Records</div>
        <div className="divide-y">
          {thisMonth.slice(0, 10).map(l => (
            <div key={l.id} className="p-3 flex items-center gap-3">
              <span className="bg-red-50 text-red-700 text-xs font-black px-2 py-1 rounded-lg shrink-0">{l.quantity}x</span>
              <div className="flex-1 min-w-0">
                <div className="font-medium text-sm">{l.item}</div>
                <div className="text-[10px] text-zinc-500">{fmtDate(l.date)} — Room {l.roomNumber} — {l.category}</div>
              </div>
              <span className="font-bold text-red-600 text-sm shrink-0">{naira(l.quantity * l.unitCost)}</span>
              <div className="flex shrink-0">
                <IconBtn onClick={() => { setEditItem(l); setShowForm(true); }}><Edit3 size={13} /></IconBtn>
                <IconBtn tone="red" onClick={() => losses.remove(l.id)}><Trash2 size={13} /></IconBtn>
              </div>
            </div>
          ))}
          {thisMonth.length === 0 && <EmptyState text="No losses this month" />}
        </div>
      </Card>
    </div>
  );
}

const LOSS_CATS = ['Linen', 'Amenity', 'Furniture', 'Maintenance'];

function LossForm({ initial, depts, onSave, onCancel }: { initial: HousekeepingLoss | null; depts: Department[]; onSave: (l: HousekeepingLoss) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, item: initial.item, category: initial.category, quantity: String(initial.quantity), unitCost: String(initial.unitCost), roomNumber: initial.roomNumber }
    : { date: today(), item: '', category: 'Linen', quantity: '1', unitCost: '', roomNumber: '' });
  return (
    <FormCard title={initial ? 'Edit Loss' : 'Log Loss'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Item"><TextInput value={f.item} onChange={e => setF({ ...f, item: e.target.value })} placeholder="Item name" /></Field>
        <Field label="Category">
          <Select value={f.category} onChange={e => setF({ ...f, category: e.target.value })}>
            {LOSS_CATS.map(c => <option key={c}>{c}</option>)}
          </Select>
        </Field>
        <Field label="Quantity"><NumberInput value={f.quantity} onChange={e => setF({ ...f, quantity: e.target.value })} placeholder="Quantity" /></Field>
        <Field label="Unit Cost (₦)"><NumberInput value={f.unitCost} onChange={e => setF({ ...f, unitCost: e.target.value })} placeholder="Unit cost" /></Field>
        <Field label="Room Number"><TextInput value={f.roomNumber} onChange={e => setF({ ...f, roomNumber: e.target.value })} placeholder="Room number" /></Field>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.item || !f.unitCost) return alert('Item and unit cost required'); onSave({ id: initial?.id || uid('ops'), date: f.date, item: f.item, category: f.category, quantity: Number(f.quantity) || 1, unitCost: Number(f.unitCost), roomNumber: f.roomNumber, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Log Loss'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
