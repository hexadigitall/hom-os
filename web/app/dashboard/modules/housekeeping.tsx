'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Check, Search, Bed, Droplet, HelpCircle } from 'lucide-react';
import {
  HousekeepingTask, LaundryItem, LostFoundItem, LinenDamage,
  HousekeepingPriority, LaundryType, LaundryStatus, LostFoundCategory, LinenCategory, LinenCondition,
} from '@/lib/types';
import { seedHkTasks, seedLaundry, seedLostFound, seedLinen } from '@/lib/seed';
import { useScopedCollection } from '@/lib/scoped';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { tagFor, type Department } from '@/lib/rbac';
import { today, nowISO, uid, naira, fmtDate, addDays } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'tasks' | 'laundry' | 'lostfound' | 'linen';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'tasks', label: 'Tasks', icon: Check },
  { id: 'laundry', label: 'Laundry', icon: Droplet },
  { id: 'lostfound', label: 'Lost & Found', icon: Search },
  { id: 'linen', label: 'Linen', icon: Bed },
];

export function HousekeepingModule() {
  const [tab, setTab] = useState<SubTab>('tasks');
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
      {tab === 'tasks' && <TasksTab />}
      {tab === 'laundry' && <LaundryTab />}
      {tab === 'lostfound' && <LostFoundTab />}
      {tab === 'linen' && <LinenTab />}
    </div>
  );
}

// ─── Tasks ───────────────────────────────────────────────────────────────────

const HK_PRIORITY_LABEL: Record<HousekeepingPriority, string> = {
  routine: 'Routine', deepClean: 'Deep Clean', turndown: 'Turndown', vipSetup: 'VIP Setup',
};

function TasksTab() {
  const { session } = useAuth();
  const tasks = useSyncedCollection<HousekeepingTask>('hk_tasks', 'hk_tasks', seedHkTasks, session);
  const depts = tagFor(session, 'housekeeping');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<HousekeepingTask | null>(null);
  const [showDone, setShowDone] = useState(false);

  const t = today();
  const pending = tasks.items.filter(x => !x.completed);
  const overdue = pending.filter(x => x.scheduledDate < t);
  const doneToday = tasks.items.filter(x => x.completed && x.completedAt?.slice(0, 10) === t).length;
  const visible = tasks.items.filter(x => showDone || !x.completed);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Housekeeping Tasks (${pending.length} pending)`}>
        <label className="flex items-center gap-1.5 text-xs font-medium text-zinc-500 cursor-pointer">
          <input type="checkbox" checked={showDone} onChange={e => setShowDone(e.target.checked)} className="accent-hom-primary" /> Show done
        </label>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Task</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <MetricCard label="Pending" value={pending.length} sub="Scheduled" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Overdue" value={overdue.length} sub="Past date" color="bg-red-50 text-red-700" />
        <MetricCard label="Completed Today" value={doneToday} sub="Closed out" color="bg-green-50 text-green-700" />
      </div>
      {showForm && (
        <TaskForm initial={editItem} depts={depts} onSave={(task) => {
          if (editItem) tasks.replace(task.id, task); else tasks.add(task);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {visible.map(task => (
            <div key={task.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${task.completed ? 'opacity-50' : task.scheduledDate < today() ? 'bg-red-50/40' : ''}`}>
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">
                  Room {task.roomNumber} <span className="text-[10px] px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-600 font-medium">{HK_PRIORITY_LABEL[task.priority]}</span>
                  {task.scheduledDate < today() && !task.completed && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full font-bold">OVERDUE</span>}
                </div>
                <div className="text-xs text-zinc-500 mt-0.5">{task.assignedTo} • Scheduled {fmtDate(task.scheduledDate)} {task.notes && `• ${task.notes}`}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={task.completed ? 'completed' : 'pending'} label={task.completed ? 'Done' : 'Pending'} />
                {!task.completed && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => tasks.update(task.id, { completed: true, completedAt: nowISO() })}>Complete</Btn>
                )}
                {task.completed && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => tasks.update(task.id, { completed: false, completedAt: undefined })}>Reopen</Btn>
                )}
                <IconBtn onClick={() => { setEditItem(task); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => tasks.remove(task.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {visible.length === 0 && <EmptyState text="No housekeeping tasks" />}
        </div>
      </Card>
    </div>
  );
}

function TaskForm({ initial, depts, onSave, onCancel }: { initial: HousekeepingTask | null; depts: Department[]; onSave: (t: HousekeepingTask) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { roomNumber: initial.roomNumber, assignedTo: initial.assignedTo, priority: initial.priority, scheduledDate: initial.scheduledDate, notes: initial.notes || '' }
    : { roomNumber: '', assignedTo: '', priority: 'routine' as HousekeepingPriority, scheduledDate: today(), notes: '' });
  return (
    <FormCard title={initial ? 'Edit Task' : 'New Housekeeping Task'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Room Number"><TextInput value={f.roomNumber} onChange={e => setF({ ...f, roomNumber: e.target.value })} placeholder="Room number" /></Field>
        <Field label="Assigned To"><TextInput value={f.assignedTo} onChange={e => setF({ ...f, assignedTo: e.target.value })} placeholder="Assignee" /></Field>
        <Field label="Priority">
          <Select value={f.priority} onChange={e => setF({ ...f, priority: e.target.value as HousekeepingPriority })}>
            <option value="routine">Routine</option><option value="deepClean">Deep Clean</option><option value="turndown">Turndown</option><option value="vipSetup">VIP Setup</option>
          </Select>
        </Field>
        <Field label="Scheduled Date"><DateInput value={f.scheduledDate} onChange={e => setF({ ...f, scheduledDate: e.target.value })} /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.roomNumber || !f.assignedTo) return alert('Room and assignee required'); onSave({ id: initial?.id || uid('hk'), ...f, completed: initial?.completed || false, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Create Task'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Laundry ─────────────────────────────────────────────────────────────────

const LAUNDRY_TYPE_LABEL: Record<LaundryType, string> = {
  washIron: 'Wash & Iron', dryCleanOnly: 'Dry Clean', selfService: 'Self Service',
};
const LAUNDRY_NEXT: Record<LaundryStatus, LaundryStatus | null> = {
  received: 'washing', washing: 'drying', drying: 'ironing', ironing: 'ready', ready: 'delivered', delivered: null,
};

function LaundryTab() {
  const { session } = useAuth();
  const laundry = useScopedCollection<LaundryItem>('hk_laundry', seedLaundry, session);
  const depts = tagFor(session, 'laundry');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<LaundryItem | null>(null);

  const received = laundry.items.filter(x => x.status === 'received').length;
  const inProgress = laundry.items.filter(x => ['washing', 'drying', 'ironing'].includes(x.status)).length;
  const ready = laundry.items.filter(x => x.status === 'ready').length;
  const outstandingRevenue = laundry.items.filter(x => x.status !== 'delivered').reduce((a, x) => a + x.chargeAmount, 0);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Laundry (${laundry.items.length} items)`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Laundry</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Received" value={received} sub="Logged in" color="bg-blue-50 text-blue-700" />
        <MetricCard label="In Progress" value={inProgress} sub="Wash / dry / iron" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Ready" value={ready} sub="Awaiting delivery" color="bg-green-50 text-green-700" />
        <MetricCard label="Outstanding" value={naira(outstandingRevenue)} sub="Undelivered charges" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <LaundryForm initial={editItem} depts={depts} onSave={(l) => {
          if (editItem) laundry.replace(l.id, l); else laundry.add(l);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {laundry.items.map(l => {
            const next = LAUNDRY_NEXT[l.status];
            return (
              <div key={l.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">{l.itemDescription} <span className="text-zinc-400 font-normal text-sm">{l.guestName} • Room {l.roomNumber}</span></div>
                  <div className="text-xs text-zinc-500 mt-0.5">{LAUNDRY_TYPE_LABEL[l.type]} • {l.receivedDate && `Received ${fmtDate(l.receivedDate)}`} {l.deliveredDate && ` • Delivered ${fmtDate(l.deliveredDate)}`}</div>
                </div>
                <div className="flex items-center gap-3 flex-wrap">
                  <span className="font-bold">{naira(l.chargeAmount)}</span>
                  <StatusChip status={l.status} />
                  {next && <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => laundry.update(l.id, { status: next, deliveredDate: next === 'delivered' ? today() : l.deliveredDate })}>Mark {next}</Btn>}
                  <IconBtn onClick={() => { setEditItem(l); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => laundry.remove(l.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {laundry.items.length === 0 && <EmptyState text="No laundry items" />}
        </div>
      </Card>
    </div>
  );
}

function LaundryForm({ initial, depts, onSave, onCancel }: { initial: LaundryItem | null; depts: Department[]; onSave: (l: LaundryItem) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { guestName: initial.guestName, roomNumber: initial.roomNumber, itemDescription: initial.itemDescription, type: initial.type, chargeAmount: String(initial.chargeAmount), receivedDate: initial.receivedDate || '' }
    : { guestName: '', roomNumber: '', itemDescription: '', type: 'washIron' as LaundryType, chargeAmount: '0', receivedDate: today() });
  return (
    <FormCard title={initial ? 'Edit Laundry' : 'Add Laundry Item'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Guest Name"><TextInput value={f.guestName} onChange={e => setF({ ...f, guestName: e.target.value })} placeholder="Guest name" /></Field>
        <Field label="Room Number"><TextInput value={f.roomNumber} onChange={e => setF({ ...f, roomNumber: e.target.value })} placeholder="Room number" /></Field>
        <Field label="Item Description"><TextInput value={f.itemDescription} onChange={e => setF({ ...f, itemDescription: e.target.value })} placeholder="e.g. 2x Suit — Dry Clean" /></Field>
        <Field label="Service Type">
          <Select value={f.type} onChange={e => setF({ ...f, type: e.target.value as LaundryType })}>
            <option value="washIron">Wash & Iron</option><option value="dryCleanOnly">Dry Clean</option><option value="selfService">Self Service</option>
          </Select>
        </Field>
        <Field label="Charge (₦)"><NumberInput value={f.chargeAmount} onChange={e => setF({ ...f, chargeAmount: e.target.value })} placeholder="Charge" /></Field>
        <Field label="Received Date"><DateInput value={f.receivedDate} onChange={e => setF({ ...f, receivedDate: e.target.value })} /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.guestName || !f.itemDescription) return alert('Guest and item required'); onSave({ id: initial?.id || uid('hk'), ...f, chargeAmount: Number(f.chargeAmount) || 0, status: initial?.status || 'received', receivedDate: f.receivedDate || today(), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Laundry'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Lost & Found ────────────────────────────────────────────────────────────

const LF_CATEGORY_LABEL: Record<LostFoundCategory, string> = {
  electronics: 'Electronics', jewelry: 'Jewelry', documents: 'Documents', clothing: 'Clothing', luggage: 'Luggage', other: 'Other',
};

function LostFoundTab() {
  const { session } = useAuth();
  const items = useSyncedCollection<LostFoundItem>('hk_lost_found', 'hk_lostfound', seedLostFound, session);
  const depts = tagFor(session, 'housekeeping');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<LostFoundItem | null>(null);

  const open = items.items.filter(x => !x.returned);
  const held7 = open.filter(x => x.returnedAt ? daysHeld(x) >= 7 : true).length;

  return (
    <div className="space-y-4">
      <SectionHeader title={`Lost & Found (${items.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Log Item</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Open" value={open.length} sub="Not returned" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Returned" value={items.items.filter(x => x.returned).length} sub="Handed back" color="bg-green-50 text-green-700" />
        <MetricCard label="In Storage" value={held7} sub="Awaiting claim" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Categories" value={new Set(items.items.map(x => x.category)).size} sub="Types found" color="bg-zinc-50 text-zinc-700" />
      </div>
      {showForm && (
        <LostFoundForm initial={editItem} depts={depts} onSave={(l) => {
          if (editItem) items.replace(l.id, l); else items.add(l);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {items.items.map(l => (
            <div key={l.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${l.returned ? 'opacity-60' : ''}`}>
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap"><HelpCircle size={15} className="text-amber-500" /> {l.itemName} <span className="text-[10px] px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-600 font-medium">{LF_CATEGORY_LABEL[l.category]}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">Found by {l.foundBy} at {l.locationFound} {l.guestName && `• Guest: ${l.guestName}`}</div>
                {l.notes && <div className="text-xs text-zinc-400 mt-0.5">{l.notes}</div>}
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={l.returned ? 'returned' : 'pending'} label={l.returned ? 'Returned' : 'In storage'} />
                {!l.returned && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => items.update(l.id, { returned: true, returnedAt: nowISO() })}>Mark Returned</Btn>
                )}
                <IconBtn onClick={() => { setEditItem(l); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => items.remove(l.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {items.items.length === 0 && <EmptyState text="No lost & found items" />}
        </div>
      </Card>
    </div>
  );
}

const daysHeld = (l: LostFoundItem) => l.returnedAt ? Math.round((new Date().getTime() - new Date(l.returnedAt).getTime()) / 86400000) : 0;

function LostFoundForm({ initial, depts, onSave, onCancel }: { initial: LostFoundItem | null; depts: Department[]; onSave: (l: LostFoundItem) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { itemName: initial.itemName, foundBy: initial.foundBy, locationFound: initial.locationFound, category: initial.category, guestName: initial.guestName || '', notes: initial.notes || '' }
    : { itemName: '', foundBy: '', locationFound: '', category: 'other' as LostFoundCategory, guestName: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Item' : 'Log Found Item'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Item Name"><TextInput value={f.itemName} onChange={e => setF({ ...f, itemName: e.target.value })} placeholder="Item name" /></Field>
        <Field label="Category">
          <Select value={f.category} onChange={e => setF({ ...f, category: e.target.value as LostFoundCategory })}>
            {Object.entries(LF_CATEGORY_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </Select>
        </Field>
        <Field label="Found By"><TextInput value={f.foundBy} onChange={e => setF({ ...f, foundBy: e.target.value })} placeholder="Who found it" /></Field>
        <Field label="Location Found"><TextInput value={f.locationFound} onChange={e => setF({ ...f, locationFound: e.target.value })} placeholder="Location" /></Field>
        <Field label="Guest Name (if known)"><TextInput value={f.guestName} onChange={e => setF({ ...f, guestName: e.target.value })} placeholder="Guest" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.itemName || !f.foundBy) return alert('Item and finder required'); onSave({ id: initial?.id || uid('hk'), ...f, returned: initial?.returned || false, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Log Item'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Linen ───────────────────────────────────────────────────────────────────

const LINEN_CATEGORY_LABEL: Record<LinenCategory, string> = {
  bedsheet: 'Bedsheet', towel: 'Towel', pillowcase: 'Pillowcase', duvet: 'Duvet', other: 'Other',
};
const LINEN_CONDITION_LABEL: Record<LinenCondition, string> = {
  stained: 'Stained', torn: 'Torn', damaged: 'Damaged', condemned: 'Condemned',
};

function LinenTab() {
  const { session } = useAuth();
  const linen = useScopedCollection<LinenDamage>('hk_linen', seedLinen, session);
  const depts = tagFor(session, 'laundry');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<LinenDamage | null>(null);

  const totalCost = linen.items.reduce((a, l) => a + (l.replacementCost || 0) * l.quantity, 0);
  const condemned = linen.items.filter(l => l.condition === 'condemned').length;

  return (
    <div className="space-y-4">
      <SectionHeader title={`Linen Damage (${linen.items.length} entries)`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Log Damage</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Entries" value={linen.items.length} sub="Damage records" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Replacement Cost" value={naira(totalCost)} sub="All entries" color="bg-red-50 text-red-700" />
        <MetricCard label="Condemned" value={condemned} sub="Beyond recovery" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Units Damaged" value={linen.items.reduce((a, l) => a + l.quantity, 0)} sub="Total pieces" color="bg-zinc-50 text-zinc-700" />
      </div>
      {showForm && (
        <LinenForm initial={editItem} depts={depts} onSave={(l) => {
          if (editItem) linen.replace(l.id, l); else linen.add(l);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {linen.items.map(l => (
            <div key={l.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">{l.itemName} <span className="text-zinc-400 font-normal text-sm">Room {l.roomNumber}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">{LINEN_CATEGORY_LABEL[l.category]} • {l.quantity} unit(s) {l.notes && `• ${l.notes}`}</div>
              </div>
              <div className="flex items-center gap-3 flex-wrap">
                <StatusChip status={l.condition} label={LINEN_CONDITION_LABEL[l.condition]} />
                {l.replacementCost != null && <span className="font-bold">{naira(l.replacementCost * l.quantity)}</span>}
                <IconBtn onClick={() => { setEditItem(l); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => linen.remove(l.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {linen.items.length === 0 && <EmptyState text="No linen damage logged" />}
        </div>
      </Card>
    </div>
  );
}

function LinenForm({ initial, depts, onSave, onCancel }: { initial: LinenDamage | null; depts: Department[]; onSave: (l: LinenDamage) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { itemName: initial.itemName, roomNumber: initial.roomNumber, category: initial.category, condition: initial.condition, quantity: String(initial.quantity), replacementCost: initial.replacementCost != null ? String(initial.replacementCost) : '', notes: initial.notes || '' }
    : { itemName: '', roomNumber: '', category: 'bedsheet' as LinenCategory, condition: 'stained' as LinenCondition, quantity: '1', replacementCost: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Damage' : 'Log Linen Damage'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Item Name"><TextInput value={f.itemName} onChange={e => setF({ ...f, itemName: e.target.value })} placeholder="Item name" /></Field>
        <Field label="Room Number"><TextInput value={f.roomNumber} onChange={e => setF({ ...f, roomNumber: e.target.value })} placeholder="Room number" /></Field>
        <Field label="Category">
          <Select value={f.category} onChange={e => setF({ ...f, category: e.target.value as LinenCategory })}>
            {Object.entries(LINEN_CATEGORY_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </Select>
        </Field>
        <Field label="Condition">
          <Select value={f.condition} onChange={e => setF({ ...f, condition: e.target.value as LinenCondition })}>
            {Object.entries(LINEN_CONDITION_LABEL).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </Select>
        </Field>
        <Field label="Quantity"><NumberInput value={f.quantity} onChange={e => setF({ ...f, quantity: e.target.value })} placeholder="Quantity" /></Field>
        <Field label="Replacement Cost (₦)"><NumberInput value={f.replacementCost} onChange={e => setF({ ...f, replacementCost: e.target.value })} placeholder="Per unit" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.itemName) return alert('Item name required'); onSave({ id: initial?.id || uid('hk'), ...f, quantity: Number(f.quantity) || 1, replacementCost: f.replacementCost ? Number(f.replacementCost) : undefined, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Log Damage'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
