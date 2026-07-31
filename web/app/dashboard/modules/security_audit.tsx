'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Check, Moon, ShieldAlert, UserCheck, Repeat } from 'lucide-react';
import {
  NightAuditLog, SecurityIncident, VisitorPass, ShiftHandover,
  IncidentType, IncidentStatus, ShiftType,
} from '@/lib/types';
import { seedNightAudits, seedIncidents, seedVisitors, seedShifts } from '@/lib/seed';
import { useCollection } from '@/lib/storage';
import { today, nowISO, uid, naira, fmtDate } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'nightaudit' | 'security' | 'visitors' | 'shifts';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'nightaudit', label: 'Night Audit', icon: Moon },
  { id: 'security', label: 'Security', icon: ShieldAlert },
  { id: 'visitors', label: 'Visitors', icon: UserCheck },
  { id: 'shifts', label: 'Shifts', icon: Repeat },
];

export function SecurityAuditModule() {
  const [tab, setTab] = useState<SubTab>('nightaudit');
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
      {tab === 'nightaudit' && <NightAuditTab />}
      {tab === 'security' && <SecurityTab />}
      {tab === 'visitors' && <VisitorsTab />}
      {tab === 'shifts' && <ShiftsTab />}
    </div>
  );
}

// ─── Night Audit ─────────────────────────────────────────────────────────────

function NightAuditTab() {
  const audits = useCollection<NightAuditLog>('sa_nightaudits', seedNightAudits);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<NightAuditLog | null>(null);

  const last = audits.items[0];
  const closed = audits.items.filter(a => a.locked).length;

  return (
    <div className="space-y-4">
      <SectionHeader title="Night Audit" sub="End-of-day financial closure">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Audit</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Last Audit Date" value={last ? fmtDate(last.businessDate) : '—'} sub="Latest run" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Last Revenue" value={last ? naira(last.totalRevenue) : '—'} sub="Business date" color="bg-green-50 text-green-700" />
        <MetricCard label="Cash Dropped" value={last ? naira(last.cashDropTotal) : '—'} sub={`${last?.cashDropCount || 0} drops`} color="bg-amber-50 text-amber-700" />
        <MetricCard label="Closed Audits" value={closed} sub="Locked days" color="bg-zinc-50 text-zinc-700" />
      </div>
      {showForm && (
        <NightAuditForm initial={editItem} onSave={(a) => {
          if (editItem) audits.replace(a.id, a); else audits.add(a);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {audits.items.map(a => (
            <div key={a.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${a.locked ? '' : 'bg-amber-50/30'}`}>
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">Business Date {fmtDate(a.businessDate)} {!a.locked && <span className="text-[10px] bg-amber-500 text-white px-2 py-0.5 rounded-full font-bold">OPEN</span>}</div>
                <div className="text-xs text-zinc-500 mt-0.5">
                  Room {naira(a.roomRevenue)} • F&B {naira(a.fnbRevenue)} • Other {naira(a.otherRevenue)} • Cash drops {naira(a.cashDropTotal)}
                </div>
                <div className="text-[10px] text-zinc-400 mt-0.5">{a.closedBy && `Closed by ${a.closedBy}`} {a.closedAt && ` at ${a.closedAt.slice(11, 16)}`}</div>
              </div>
              <div className="flex items-center gap-3 flex-wrap">
                <span className="font-bold">{naira(a.totalRevenue)}</span>
                <StatusChip status={a.locked ? 'locked' : 'pending'} label={a.locked ? 'Locked' : 'Open'} />
                {!a.locked && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => audits.update(a.id, { locked: true, closedAt: nowISO(), closedBy: 'Front Desk' })}>Close & Lock</Btn>
                )}
                <IconBtn onClick={() => { setEditItem(a); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => audits.remove(a.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {audits.items.length === 0 && <EmptyState text="No night audits run yet" />}
        </div>
      </Card>
    </div>
  );
}

function NightAuditForm({ initial, onSave, onCancel }: { initial: NightAuditLog | null; onSave: (a: NightAuditLog) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { businessDate: initial.businessDate, roomRevenue: String(initial.roomRevenue), fnbRevenue: String(initial.fnbRevenue), otherRevenue: String(initial.otherRevenue), cashDropCount: String(initial.cashDropCount), cashDropTotal: String(initial.cashDropTotal), closedBy: initial.closedBy || '' }
    : { businessDate: today(), roomRevenue: '0', fnbRevenue: '0', otherRevenue: '0', cashDropCount: '0', cashDropTotal: '0', closedBy: '' });

  const total = (Number(f.roomRevenue) || 0) + (Number(f.fnbRevenue) || 0) + (Number(f.otherRevenue) || 0);

  return (
    <FormCard title={initial ? 'Edit Audit' : 'Run Night Audit'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Business Date"><input type="date" className="border rounded-xl px-4 py-2.5 text-sm w-full" value={f.businessDate} onChange={e => setF({ ...f, businessDate: e.target.value })} /></Field>
        <Field label="Closed By"><TextInput value={f.closedBy} onChange={e => setF({ ...f, closedBy: e.target.value })} placeholder="Who ran the audit" /></Field>
        <Field label="Room Revenue (₦)"><NumberInput value={f.roomRevenue} onChange={e => setF({ ...f, roomRevenue: e.target.value })} placeholder="Room revenue" /></Field>
        <Field label="F&B Revenue (₦)"><NumberInput value={f.fnbRevenue} onChange={e => setF({ ...f, fnbRevenue: e.target.value })} placeholder="F&B revenue" /></Field>
        <Field label="Other Revenue (₦)"><NumberInput value={f.otherRevenue} onChange={e => setF({ ...f, otherRevenue: e.target.value })} placeholder="Other revenue" /></Field>
        <Field label="Cash Drop Count"><NumberInput value={f.cashDropCount} onChange={e => setF({ ...f, cashDropCount: e.target.value })} placeholder="Count" /></Field>
        <Field label="Cash Drop Total (₦)"><NumberInput value={f.cashDropTotal} onChange={e => setF({ ...f, cashDropTotal: e.target.value })} placeholder="Total dropped" /></Field>
        <Field label="Total Revenue (auto)"><div className="border rounded-xl px-4 py-2.5 text-sm font-bold bg-zinc-50">{naira(total)}</div></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { onSave({ id: initial?.id || uid('sa'), ...f, roomRevenue: Number(f.roomRevenue) || 0, fnbRevenue: Number(f.fnbRevenue) || 0, otherRevenue: Number(f.otherRevenue) || 0, cashDropCount: Number(f.cashDropCount) || 0, cashDropTotal: Number(f.cashDropTotal) || 0, totalRevenue: total, locked: initial?.locked || false }); }}>{initial ? 'Update' : 'Save Audit'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Security ────────────────────────────────────────────────────────────────

const INCIDENT_TYPE_LABEL: Record<IncidentType, string> = {
  theft: 'Theft', fire: 'Fire', medical: 'Medical', intruder: 'Intruder', propertyDamage: 'Property Damage', noiseComplaint: 'Noise Complaint', other: 'Other',
};

function SecurityTab() {
  const incidents = useCollection<SecurityIncident>('sa_incidents', seedIncidents);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<SecurityIncident | null>(null);

  const open = incidents.items.filter(x => x.status === 'open').length;
  const investigating = incidents.items.filter(x => x.status === 'investigating').length;
  const resolved = incidents.items.filter(x => x.status === 'resolved').length;

  const nextStatus: Record<IncidentStatus, IncidentStatus | null> = { open: 'investigating', investigating: 'resolved', resolved: null };

  return (
    <div className="space-y-4">
      <SectionHeader title={`Security Incidents (${incidents.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Log Incident</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Open" value={open} sub="Reported" color="bg-red-50 text-red-700" />
        <MetricCard label="Investigating" value={investigating} sub="In progress" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Resolved" value={resolved} sub="Closed out" color="bg-green-50 text-green-700" />
        <MetricCard label="Theft" value={incidents.items.filter(x => x.type === 'theft').length} sub="Type count" color="bg-zinc-50 text-zinc-700" />
      </div>
      {showForm && (
        <IncidentForm initial={editItem} onSave={(i) => {
          if (editItem) incidents.replace(i.id, i); else incidents.add(i);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {incidents.items.map(x => {
            const next = nextStatus[x.status];
            return (
              <div key={x.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap"><ShieldAlert size={15} className={x.status === 'resolved' ? 'text-green-500' : 'text-red-500'} /> {INCIDENT_TYPE_LABEL[x.type]} <span className="text-zinc-400 font-normal text-sm">{x.location}</span></div>
                  <div className="text-xs text-zinc-500 mt-0.5">{x.description} • Reported by {x.reportedBy}</div>
                  {x.resolvedBy && <div className="text-[10px] text-zinc-400 mt-0.5">Resolved by {x.resolvedBy} {x.dateResolved && fmtDate(x.dateResolved)} {x.notes && `• ${x.notes}`}</div>}
                </div>
                <div className="flex items-center gap-2">
                  <StatusChip status={x.status} />
                  {next && <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => incidents.update(x.id, { status: next, resolvedBy: next === 'resolved' ? 'Security Officer' : x.resolvedBy, dateResolved: next === 'resolved' ? today() : x.dateResolved })}>Mark {next}</Btn>}
                  <IconBtn onClick={() => { setEditItem(x); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => incidents.remove(x.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {incidents.items.length === 0 && <EmptyState text="No security incidents" />}
        </div>
      </Card>
    </div>
  );
}

function IncidentForm({ initial, onSave, onCancel }: { initial: SecurityIncident | null; onSave: (i: SecurityIncident) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { type: initial.type, location: initial.location, description: initial.description, reportedBy: initial.reportedBy, notes: initial.notes || '' }
    : { type: 'theft' as IncidentType, location: '', description: '', reportedBy: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Incident' : 'Log Security Incident'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Type">
          <Select value={f.type} onChange={e => setF({ ...f, type: e.target.value as IncidentType })}>
            {Object.entries(INCIDENT_TYPE_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </Select>
        </Field>
        <Field label="Location"><TextInput value={f.location} onChange={e => setF({ ...f, location: e.target.value })} placeholder="Location" /></Field>
        <Field label="Description" className="md:col-span-2"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="What happened" /></Field>
        <Field label="Reported By"><TextInput value={f.reportedBy} onChange={e => setF({ ...f, reportedBy: e.target.value })} placeholder="Reporter" /></Field>
        <Field label="Notes"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.location || !f.description) return alert('Location and description required'); onSave({ id: initial?.id || uid('sa'), ...f, status: initial?.status || 'open' }); }}>{initial ? 'Update' : 'Log Incident'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Visitors ────────────────────────────────────────────────────────────────

function VisitorsTab() {
  const visitors = useCollection<VisitorPass>('sa_visitors', seedVisitors);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<VisitorPass | null>(null);

  const inside = visitors.items.filter(v => !v.checkOut).length;
  const checkedOut = visitors.items.filter(v => v.checkOut).length;

  return (
    <div className="space-y-4">
      <SectionHeader title={`Visitor Passes (${visitors.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Issue Pass</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="On Premises" value={inside} sub="Not checked out" color="bg-green-50 text-green-700" />
        <MetricCard label="Checked Out" value={checkedOut} sub="Exited" color="bg-zinc-50 text-zinc-700" />
        <MetricCard label="Today" value={visitors.items.filter(v => (v.checkIn || '').slice(0, 10) === today()).length} sub="New passes" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Hosted By" value={new Set(visitors.items.map(v => v.hostName)).size} sub="Unique hosts" color="bg-amber-50 text-amber-700" />
      </div>
      {showForm && (
        <VisitorForm initial={editItem} onSave={(v) => {
          if (editItem) visitors.replace(v.id, v); else visitors.add(v);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {visitors.items.map(v => (
            <div key={v.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${v.checkOut ? 'opacity-60' : ''}`}>
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">{v.visitorName} <span className="text-[10px] px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-600 font-medium">{v.badgeNumber}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">{v.purpose} • Host: {v.hostName}</div>
                <div className="text-[10px] text-zinc-400 mt-0.5">In {v.checkIn?.replace('T', ' ').slice(0, 16)} {v.checkOut && `• Out ${v.checkOut.replace('T', ' ').slice(0, 16)}`}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={v.checkOut ? 'checked-out' : 'active'} label={v.checkOut ? 'Checked Out' : 'On Premises'} />
                {!v.checkOut && <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => visitors.update(v.id, { checkOut: nowISO() })}><Check size={12} /> Check Out</Btn>}
                <IconBtn onClick={() => { setEditItem(v); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => visitors.remove(v.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {visitors.items.length === 0 && <EmptyState text="No visitor passes issued" />}
        </div>
      </Card>
    </div>
  );
}

function VisitorForm({ initial, onSave, onCancel }: { initial: VisitorPass | null; onSave: (v: VisitorPass) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { visitorName: initial.visitorName, purpose: initial.purpose, hostName: initial.hostName, badgeNumber: initial.badgeNumber, checkIn: initial.checkIn?.slice(0, 16) || '' }
    : { visitorName: '', purpose: '', hostName: '', badgeNumber: '', checkIn: '' });
  const now = new Date();
  const defaultCheckIn = `${today()}T${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  return (
    <FormCard title={initial ? 'Edit Pass' : 'Issue Visitor Pass'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Visitor Name"><TextInput value={f.visitorName} onChange={e => setF({ ...f, visitorName: e.target.value })} placeholder="Visitor name" /></Field>
        <Field label="Badge Number"><TextInput value={f.badgeNumber} onChange={e => setF({ ...f, badgeNumber: e.target.value })} placeholder="Badge #" /></Field>
        <Field label="Purpose"><TextInput value={f.purpose} onChange={e => setF({ ...f, purpose: e.target.value })} placeholder="Purpose of visit" /></Field>
        <Field label="Host"><TextInput value={f.hostName} onChange={e => setF({ ...f, hostName: e.target.value })} placeholder="Host staff" /></Field>
        <Field label="Check-In Time"><input type="datetime-local" className="border rounded-xl px-4 py-2.5 text-sm w-full" value={f.checkIn} onChange={e => setF({ ...f, checkIn: e.target.value })} /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.visitorName || !f.hostName) return alert('Visitor and host required'); onSave({ id: initial?.id || uid('sa'), ...f, checkIn: f.checkIn ? f.checkIn + ':00' : defaultCheckIn, checkOut: initial?.checkOut }); }}>{initial ? 'Update' : 'Issue Pass'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Shifts ──────────────────────────────────────────────────────────────────

const SHIFT_LABEL: Record<ShiftType, string> = {
  morning: 'Morning', afternoon: 'Afternoon', night: 'Night',
};

function ShiftsTab() {
  const shifts = useCollection<ShiftHandover>('sa_shifts', seedShifts);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<ShiftHandover | null>(null);

  const open = shifts.items.filter(s => !s.closedAt).length;
  const closed = shifts.items.filter(s => s.closedAt).length;

  return (
    <div className="space-y-4">
      <SectionHeader title={`Shift Handovers (${shifts.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Open Shift</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Open" value={open} sub="Active shifts" color="bg-green-50 text-green-700" />
        <MetricCard label="Closed" value={closed} sub="Handed over" color="bg-zinc-50 text-zinc-700" />
        <MetricCard label="Today" value={shifts.items.filter(s => s.openedAt.slice(0, 10) === today()).length} sub="Opened today" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Night Shifts" value={shifts.items.filter(s => s.shiftType === 'night').length} sub="Total" color="bg-amber-50 text-amber-700" />
      </div>
      {showForm && (
        <ShiftForm initial={editItem} onSave={(s) => {
          if (editItem) shifts.replace(s.id, s); else shifts.add(s);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {shifts.items.map(s => (
            <div key={s.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${s.closedAt ? 'opacity-60' : 'bg-green-50/30'}`}>
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap"><Repeat size={15} className="text-hom-primary" /> {SHIFT_LABEL[s.shiftType]} Shift {!s.closedAt && <span className="text-[10px] bg-hom-primary text-white px-2 py-0.5 rounded-full font-bold">OPEN</span>}</div>
                <div className="text-xs text-zinc-500 mt-0.5">Opened by {s.openedBy} at {s.openedAt.replace('T', ' ').slice(0, 16)}</div>
                {s.notes && <div className="text-xs text-zinc-400 mt-0.5">{s.notes}</div>}
                {s.closedAt && <div className="text-[10px] text-zinc-400 mt-0.5">Closed by {s.closedBy} at {s.closedAt.replace('T', ' ').slice(0, 16)}</div>}
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={s.closedAt ? 'checked-out' : 'active'} label={s.closedAt ? 'Closed' : 'Open'} />
                {!s.closedAt && <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => shifts.update(s.id, { closedAt: nowISO(), closedBy: 'Front Desk' })}>Close Shift</Btn>}
                <IconBtn onClick={() => { setEditItem(s); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => shifts.remove(s.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {shifts.items.length === 0 && <EmptyState text="No shift handovers" />}
        </div>
      </Card>
    </div>
  );
}

function ShiftForm({ initial, onSave, onCancel }: { initial: ShiftHandover | null; onSave: (s: ShiftHandover) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { shiftType: initial.shiftType, openedBy: initial.openedBy, notes: initial.notes || '' }
    : { shiftType: 'morning' as ShiftType, openedBy: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Shift' : 'Open Shift'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Shift">
          <Select value={f.shiftType} onChange={e => setF({ ...f, shiftType: e.target.value as ShiftType })}>
            {Object.entries(SHIFT_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </Select>
        </Field>
        <Field label="Opened By"><TextInput value={f.openedBy} onChange={e => setF({ ...f, openedBy: e.target.value })} placeholder="Staff opening shift" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Handover notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.openedBy) return alert('Opened by required'); onSave({ id: initial?.id || uid('sa'), ...f, openedAt: initial?.openedAt || nowISO() }); }}>{initial ? 'Update' : 'Open Shift'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
