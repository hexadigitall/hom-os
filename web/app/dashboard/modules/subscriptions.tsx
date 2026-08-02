'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3 } from 'lucide-react';
import { Subscription, BillingCycle } from '@/lib/types';
import { seedSubscriptions } from '@/lib/seed';
import { useScopedCollection } from '@/lib/scoped';
import { useAuth } from '@/lib/auth';
import { tagFor, type Department } from '@/lib/rbac';
import { today, uid, naira, fmtDate, addMonths, daysBetween } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

const CATEGORIES = ['TV & Entertainment', 'Internet', 'Software / SaaS', 'License & Permits', 'Security Monitoring', 'Cleaning', 'Other'];

export function SubscriptionsModule() {
  const { session } = useAuth();
  const subs = useScopedCollection<Subscription>('hom_subscriptions', seedSubscriptions, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<Subscription | null>(null);
  const depts = tagFor(session, 'management');

  const monthlyTotal = subs.items.reduce((a, s) => a + (s.billingCycle === 'monthly' ? s.amount : s.billingCycle === 'quarterly' ? s.amount / 3 : s.amount / 12), 0);

  const renewalDate = (s: Subscription) => {
    let d = s.startDate;
    while (d <= today()) d = addMonths(d, s.billingCycle === 'monthly' ? 1 : s.billingCycle === 'quarterly' ? 3 : 12);
    return d;
  };

  return (
    <div className="space-y-4">
      <SectionHeader title={`Subscriptions (${subs.items.length})`} sub={`Total recurring cost: ${naira(monthlyTotal)}/mo`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Subscription</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Active" value={subs.items.filter(s => s.status === 'active').length} sub="In good standing" color="bg-green-50 text-green-700" />
        <MetricCard label="Expiring" value={subs.items.filter(s => s.status === 'expiring').length} sub="Renewal soon" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Expired" value={subs.items.filter(s => s.status === 'expired').length} sub="Needs action" color="bg-red-50 text-red-700" />
        <MetricCard label="Monthly Total" value={naira(monthlyTotal)} sub="Annualized / 12" color="bg-blue-50 text-blue-700" />
      </div>
      {showForm && (
        <SubForm initial={editItem} depts={depts} onSave={(s) => {
          if (editItem) subs.replace(s.id, s); else subs.add(s);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {subs.items.map(s => {
            const rn = renewalDate(s);
            const days = daysBetween(today(), rn);
            return (
              <div key={s.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">{s.name} <span className="text-zinc-400 font-normal text-sm">{s.provider}</span></div>
                  <div className="text-xs text-zinc-500 mt-0.5">{s.category} • Since {fmtDate(s.startDate)} • Renews {fmtDate(rn)} ({days}d)</div>
                  {s.notes && <div className="text-xs text-zinc-400 italic mt-0.5">{s.notes}</div>}
                </div>
                <div className="flex items-center gap-3 flex-wrap">
                  <div className="text-right">
                    <div className="font-bold text-hom-primary">{naira(s.amount)}<span className="text-zinc-400 text-xs font-normal">/{s.billingCycle}</span></div>
                    <div className="text-[10px] text-zinc-400">{s.autoLogExpenditure ? 'Auto-logs to expenditure' : 'No auto-log'}</div>
                  </div>
                  <StatusChip status={s.status} />
                  <IconBtn onClick={() => { setEditItem(s); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => subs.remove(s.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {subs.items.length === 0 && <EmptyState text="No subscriptions — add one to track recurring costs" />}
        </div>
      </Card>
    </div>
  );
}

function SubForm({ initial, depts, onSave, onCancel }: { initial: Subscription | null; depts: Department[]; onSave: (s: Subscription) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { name: initial.name, provider: initial.provider, category: initial.category, amount: String(initial.amount), billingCycle: initial.billingCycle, startDate: initial.startDate, contactInfo: initial.contactInfo || '', notes: initial.notes || '', autoLogExpenditure: initial.autoLogExpenditure }
    : { name: '', provider: '', category: CATEGORIES[0], amount: '', billingCycle: 'monthly' as BillingCycle, startDate: today(), contactInfo: '', notes: '', autoLogExpenditure: true });

  return (
    <FormCard title={initial ? 'Edit Subscription' : 'Add Subscription'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Subscription Name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="e.g. DSTV Premium Business" /></Field>
        <Field label="Provider"><TextInput value={f.provider} onChange={e => setF({ ...f, provider: e.target.value })} placeholder="e.g. Multichoice Nigeria" /></Field>
        <Field label="Category">
          <Select value={f.category} onChange={e => setF({ ...f, category: e.target.value })}>
            {CATEGORIES.map(c => <option key={c}>{c}</option>)}
          </Select>
        </Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount per cycle" /></Field>
        <Field label="Billing Cycle">
          <Select value={f.billingCycle} onChange={e => setF({ ...f, billingCycle: e.target.value as BillingCycle })}>
            <option value="monthly">Monthly</option><option value="quarterly">Quarterly</option><option value="annual">Annual</option>
          </Select>
        </Field>
        <Field label="Start Date"><DateInput value={f.startDate} onChange={e => setF({ ...f, startDate: e.target.value })} /></Field>
        <Field label="Contact Info"><TextInput value={f.contactInfo} onChange={e => setF({ ...f, contactInfo: e.target.value })} placeholder="Phone / email" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <label className="flex items-center gap-2 mt-3 text-sm cursor-pointer">
        <input type="checkbox" checked={f.autoLogExpenditure} onChange={e => setF({ ...f, autoLogExpenditure: e.target.checked })} className="accent-hom-primary w-4 h-4" />
        Auto-log to Expenditure
      </label>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.name || !f.amount) return alert('Name and amount required'); onSave({ id: initial?.id || uid('sub'), ...f, amount: Number(f.amount), status: initial?.status || 'active', departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Subscription'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
